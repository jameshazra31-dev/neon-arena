import '../main.dart';
import '../models/models.dart';

class TournamentService {
  static Future<List<Tournament>> list({String? status, String? game}) async {
    var query = supabase.from('tournaments').select();
    if (status != null) query = query.eq('status', status);
    if (game != null) query = query.eq('game', game);
    final rows = await query.order('start_time', ascending: true);
    final tournaments = (rows as List).map((r) => Tournament.fromJson(r)).toList();
    await _hydrateSlots(tournaments);
    return tournaments;
  }

  static Future<List<Tournament>> featured() async {
    final rows = await supabase.from('tournaments').select().eq('is_featured', true).eq('status', 'upcoming').order('start_time');
    return (rows as List).map((r) => Tournament.fromJson(r)).toList();
  }

  static Future<void> _hydrateSlots(List<Tournament> tournaments) async {
    if (tournaments.isEmpty) return;
    final ids = tournaments.map((t) => t.id).toList();
    final slots = await supabase.from('tournament_slots').select().inFilter('tournament_id', ids);
    final byId = {for (final s in slots as List) s['tournament_id']: s};
    for (final t in tournaments) {
      t.availableSlots = byId[t.id]?['available_slots'] ?? t.totalSlots;
    }
  }

  static Future<String> join({required String tournamentId, required String gameUid, required String ign, required String utr, required String screenshotUrl, String? promoCode}) async {
    final result = await supabase.rpc('join_tournament', params: {
      'p_tournament_id': tournamentId, 'p_game_uid': gameUid, 'p_ign': ign,
      'p_utr': utr, 'p_screenshot_url': screenshotUrl, 'p_promo_code': promoCode,
    });
    return result as String;
  }

  static Future<List<Participant>> myParticipations() async {
    final rows = await supabase.from('participants').select('*, tournaments(*)').eq('user_id', supabase.auth.currentUser!.id).order('created_at', ascending: false);
    return (rows as List).map((r) => Participant.fromJson(r)).toList();
  }

  static Future<RoomDetails?> roomDetails(String tournamentId) async {
    final row = await supabase.from('tournament_rooms').select().eq('tournament_id', tournamentId).maybeSingle();
    return row == null ? null : RoomDetails.fromJson(row);
  }

  static Future<List<MatchResult>> myResults() async {
    final rows = await supabase.from('results').select('*, tournaments(name)').eq('user_id', supabase.auth.currentUser!.id).order('created_at', ascending: false);
    return (rows as List).map((r) => MatchResult.fromJson(r)).toList();
  }

  static Future<List<LeaderboardEntry>> leaderboard({int limit = 50}) async {
    final rows = await supabase.from('leaderboard').select().limit(limit);
    return (rows as List).map((r) => LeaderboardEntry.fromJson(r)).toList();
  }
}
