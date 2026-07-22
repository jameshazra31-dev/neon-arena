import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../models/models.dart';

class ProfileService {
  static Future<Profile> me() async {
    final uid = supabase.auth.currentUser!.id;
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', uid)
        .single();
    return Profile.fromJson(data);
  }

  static Future<void> uploadAvatar(File file) async {
    final uid = supabase.auth.currentUser!.id;
    final ext = file.path.split('.').last;
    final path = '$uid/avatar.$ext';
    await supabase.storage.from('avatars').upload(
      path,
      file,
      fileOptions: const FileOptions(upsert: true),
    );
    final url = supabase.storage.from('avatars').getPublicUrl(path);
    await supabase.from('profiles').update({'avatar_url': url}).eq('id', uid);
  }

  static Future<String> uploadPaymentScreenshot(File file, String tournamentId) async {
    final uid = supabase.auth.currentUser!.id;
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = '$uid/${tournamentId}_$ts.jpg';
    await supabase.storage.from('payments').upload(
      path,
      file,
      fileOptions: const FileOptions(upsert: false),
    );
    return path;
  }

  static Future<List<GameProfile>> gameProfiles() async {
    final uid = supabase.auth.currentUser!.id;
    final data = await supabase
        .from('game_profiles')
        .select()
        .eq('user_id', uid);
    return (data as List).map((e) => GameProfile.fromJson(e)).toList();
  }

  static Future<void> upsertGameProfile({
    required String game,
    required String gameUid,
    required String ign,
    String? teamName,
  }) async {
    final uid = supabase.auth.currentUser!.id;
    await supabase.from('game_profiles').upsert({
      'user_id': uid,
      'game': game,
      'game_uid': gameUid,
      'ign': ign,
      'team_name': teamName,
    });
  }
}
