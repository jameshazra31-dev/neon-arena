import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../models/models.dart';

class TournamentService {
  static Future<List<Tournament>> featured() async {
    final data = await supabase
        .from('tournaments')
        .select('*, tournament_slots(*)')
        .eq('is_featured', true)
        .inFilter('status', ['upcoming', 'live'])
        .order('start_time');
    return (data as List).map((e) => Tournament.fromJson(e)).toList();
  }

  static Future<List<Tournament>> all({String? game, String? status}) async {
    var query = supabase.from('tournaments').select('*, tournament_slots(*)');
    if (game != null) query = query.eq('game', game);
    if (status != null) query = query.eq('status', status);
    final data = await query.order('start_time', ascending: false);
    return (data as List).map((e) => Tournament.fromJson(e)).toList();
  }

  static Future<List<Tournament>> myTournaments() async {
    final uid = supabase.auth.currentUser!.id;
    final data = await supabase
        .from('participants')
        .select('*, tournaments(*, tournament_slots(*))')
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    return (data as List)
        .where((e) => e['tournaments'] != null)
        .map((e) => Tournament.fromJson(e['tournaments']))
        .toList();
  }

  static Future<void> join({
    required String tournamentId,
    required String gameUid,
    required String ign,
    required String utr,
    required String screenshotUrl,
    String? promoCode,
  }) async {
    final uid = supabase.auth.currentUser!.id;
    final tournament = await supabase
        .from('tournaments')
        .select('entry_fee')
        .eq('id', tournamentId)
        .single();
    await supabase.from('participants').insert({
      'tournament_id': tournamentId,
      'user_id': uid,
      'game_uid': gameUid,
      'ign': ign,
      'utr': utr.isEmpty ? null : utr,
      'payment_screenshot_url': screenshotUrl.isEmpty ? null : screenshotUrl,
      'amount_due': tournament['entry_fee'],
      'status': tournament['entry_fee'] == 0 ? 'approved' : 'pending',
      'promo_code': promoCode,
    });
  }
}
