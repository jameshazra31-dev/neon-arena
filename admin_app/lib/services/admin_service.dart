import '../main.dart';

class AdminService {
  static Future<bool> isAdmin() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return false;
    final row = await supabase.from('profiles').select('is_admin').eq('id', uid).maybeSingle();
    return row?['is_admin'] == true;
  }

  static Future<Map<String, num>> stats() async {
    final results = await Future.wait([
      supabase.from('profiles').count(),
      supabase.from('tournaments').count(),
      supabase.from('participants').count().eq('status', 'pending'),
      supabase.from('tournaments').count().eq('status', 'live'),
      supabase.from('participants').select('amount_due').eq('status', 'approved'),
    ]);
    final revenue = (results[4] as List).fold<num>(0, (sum, r) => sum + (r['amount_due'] as num? ?? 0));
    return {'users': results[0] as int, 'tournaments': results[1] as int, 'pending': results[2] as int, 'live': results[3] as int, 'revenue': revenue};
  }

  static Future<List<Map<String, dynamic>>> tournaments({List<String>? statuses}) async {
    var query = supabase.from('tournaments').select();
    if (statuses != null) query = query.inFilter('status', statuses);
    final rows = await query.order('start_time', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<void> upsertTournament(Map<String, dynamic> values, {String? id}) async {
    if (id == null) { await supabase.from('tournaments').insert(values); }
    else { await supabase.from('tournaments').update(values).eq('id', id); }
  }

  static Future<void> deleteTournament(String id) async => supabase.from('tournaments').delete().eq('id', id);

  static Future<List<Map<String, dynamic>>> pendingPayments() async {
    final rows = await supabase.from('participants').select('*, profiles(username, phone), tournaments(name, game, entry_fee)').eq('status', 'pending').order('created_at');
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<String?> screenshotUrl(String? path) async {
    if (path == null || path.isEmpty) return null;
    return supabase.storage.from('payments').createSignedUrl(path, 600);
  }

  static Future<void> reviewPayment(String participantId, bool approve, String? note) async {
    await supabase.rpc('review_payment', params: {'p_participant_id': participantId, 'p_approve': approve, 'p_note': (note == null || note.trim().isEmpty) ? null : note.trim()});
  }

  static Future<List<Map<String, dynamic>>> players({String? search}) async {
    var query = supabase.from('profiles').select();
    if (search != null && search.trim().isNotEmpty) query = query.ilike('username', '%${search.trim()}%');
    final rows = await query.order('created_at', ascending: false).limit(100);
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<void> setBanned(String userId, bool banned) async => supabase.from('profiles').update({'is_banned': banned}).eq('id', userId);

  static Future<Map<String, Map<String, dynamic>>> rooms() async {
    final rows = await supabase.from('tournament_rooms').select();
    return {for (final r in List<Map<String, dynamic>>.from(rows)) r['tournament_id'] as String: r};
  }

  static Future<void> publishRoom({required String tournamentId, required String roomId, required String password}) async {
    await supabase.from('tournament_rooms').upsert({'tournament_id': tournamentId, 'room_id': roomId, 'room_password': password});
  }

  static Future<List<Map<String, dynamic>>> approvedPlayers(String tournamentId) async {
    final rows = await supabase.from('participants').select('user_id, ign, profiles(username)').eq('tournament_id', tournamentId).eq('status', 'approved');
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<void> addResult({required String tournamentId, required String userId, required int rank, required int kills, required double prize}) async {
    await supabase.from('results').insert({'tournament_id': tournamentId, 'user_id': userId, 'rank': rank, 'kills': kills, 'prize_amount': prize});
  }

  static Future<List<Map<String, dynamic>>> recentResults() async {
    final rows = await supabase.from('results').select('*, profiles(username), tournaments(name)').order('created_at', ascending: false).limit(50);
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<void> markPrizePaid(String resultId) async => supabase.from('results').update({'prize_status': 'paid'}).eq('id', resultId);
}
