import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  final VoidCallback? onRead;
  const NotificationsScreen({super.key, this.onRead});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<AppNotification>> _future = NotificationService.list();

  Future<void> _refresh() async {
    setState(() => _future = NotificationService.list());
    await NotificationService.markAllRead();
    widget.onRead?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ALERTS', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3)), actions: [IconButton(icon: const Icon(Icons.done_all), onPressed: _refresh)]),
      body: RefreshIndicator(
        onRefresh: _refresh, color: NeonColors.blue,
        child: FutureBuilder<List<AppNotification>>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final items = snap.data!;
            if (items.isEmpty) return ListView(children: const [SizedBox(height: 200), Center(child: Text('No notifications yet', style: TextStyle(color: NeonColors.textMuted)))]);
            return ListView.builder(itemCount: items.length, itemBuilder: (_, i) {
              final n = items[i];
              final icon = switch (n.kind) { 'payment' => Icons.payments_rounded, 'room' => Icons.meeting_room_rounded, 'result' => Icons.emoji_events_rounded, 'reminder' => Icons.alarm_rounded, _ => Icons.notifications_rounded };
              return Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5), child: ListTile(
                leading: Icon(icon, color: n.isRead ? NeonColors.textMuted : NeonColors.blue),
                title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w800)),
                subtitle: Text('${n.body}\n${DateFormat('d MMM, h:mm a').format(n.createdAt)}'),
                isThreeLine: true,
              ));
            });
          },
        ),
      ),
    );
  }
}
