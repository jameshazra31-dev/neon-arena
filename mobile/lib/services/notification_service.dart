import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../models/models.dart';

class NotificationService {
  static String get _uid => supabase.auth.currentUser!.id;

  static Future<List<AppNotification>> list() async {
    final rows = await supabase.from('notifications').select().eq('user_id', _uid).order('created_at', ascending: false).limit(100);
    return (rows as List).map((r) => AppNotification.fromJson(r)).toList();
  }

  static Future<int> unreadCount() async {
    final rows = await supabase.from('notifications').select('id').eq('user_id', _uid).eq('is_read', false);
    return (rows as List).length;
  }

  static Future<void> markAllRead() async {
    await supabase.from('notifications').update({'is_read': true}).eq('user_id', _uid).eq('is_read', false);
  }

  static RealtimeChannel subscribe(void Function(AppNotification) onNew) {
    return supabase.channel('notifications:$_uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert, schema: 'public', table: 'notifications',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: _uid),
          callback: (payload) => onNew(AppNotification.fromJson(payload.newRecord)),
        ).subscribe();
  }
}
