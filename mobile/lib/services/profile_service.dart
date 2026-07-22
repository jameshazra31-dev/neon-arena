import 'dart:io';
import '../main.dart';
import '../models/models.dart';

class ProfileService {
  static String get _uid => supabase.auth.currentUser!.id;

  static Future<Profile> me() async {
    final row = await supabase.from('profiles').select().eq('id', _uid).single();
    return Profile.fromJson(row);
  }

  static Future<void> updateProfile({String? username, String? language}) async {
    await supabase.from('profiles').update({
      if (username != null) 'username': username,
      if (language != null) 'language': language,
    }).eq('id', _uid);
  }

  static Future<String> uploadAvatar(File file) async {
    final path = '$_uid/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await supabase.storage.from('avatars').upload(path, file);
    final url = supabase.storage.from('avatars').getPublicUrl(path);
    await supabase.from('profiles').update({'avatar_url': url}).eq('id', _uid);
    return url;
  }

  static Future<String> uploadPaymentScreenshot(File file, String tournamentId) async {
    final path = '$_uid/$tournamentId.jpg';
    await supabase.storage.from('payments').upload(path, file, fileOptions: const FileOptions(upsert: true));
    return path;
  }

  static Future<List<GameProfile>> gameProfiles() async {
    final rows = await supabase.from('game_profiles').select().eq('user_id', _uid);
    return (rows as List).map((r) => GameProfile.fromJson(r)).toList();
  }

  static Future<void> upsertGameProfile({required String game, required String gameUid, required String ign, String? teamName}) async {
    await supabase.from('game_profiles').upsert({'user_id': _uid, 'game': game, 'game_uid': gameUid, 'ign': ign, 'team_name': teamName}, onConflict: 'user_id,game');
  }

  static Future<void> applyReferral(String code) async {
    await supabase.rpc('apply_referral', params: {'p_code': code});
  }
}
