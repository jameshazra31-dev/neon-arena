import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../services/admin_service.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});
  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  late Future<List<dynamic>> _future = _load();
  Future<List<dynamic>> _load() => Future.wait([AdminService.tournaments(statuses: ['upcoming', 'live']), AdminService.rooms()]);
  void _reload() => setState(() => _future = _load());

  Future<void> _publish(Map<String, dynamic> t, Map<String, dynamic>? existing) async {
    final roomId = TextEditingController(text: existing?['room_id']);
    final password = TextEditingController(text: existing?['room_password']);
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: Text(t['name']),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: roomId, decoration: const InputDecoration(labelText: 'Room ID')),
        const SizedBox(height: 12),
        TextField(controller: password, decoration: const InputDecoration(labelText: 'Password')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: NeonColors.pink), onPressed: () => Navigator.pop(context, true), child: Text(existing == null ? 'PUBLISH' : 'UPDATE')),
      ],
    ));
    if (ok != true) return;
    await AdminService.publishRoom(tournamentId: t['id'], roomId: roomId.text.trim(), password: password.text.trim());
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Room published - approved players notified')));
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ROOM MANAGEMENT', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3))),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final tournaments = snap.data![0] as List<Map<String, dynamic>>;
          final rooms = snap.data![1] as Map<String, Map<String, dynamic>>;
          return RefreshIndicator(color: NeonColors.pink, onRefresh: () async => _reload(), child: ListView.builder(
            padding: const EdgeInsets.all(16), itemCount: tournaments.length,
            itemBuilder: (_, i) {
              final t = tournaments[i]; final room = rooms[t['id']];
              return Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(
                title: Text(t['name'], style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(room == null
                  ? '${t['game']} - ${DateFormat('d MMM, h:mm a').format(DateTime.parse(t['start_time']).toLocal())}\nRoom not published yet'
                  : '${t['game']} - Room: ${room['room_id']} - Pass: ${room['room_password']}\nPublished'),
                isThreeLine: true,
                trailing: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: room == null ? NeonColors.pink : NeonColors.surface, side: room == null ? null : const BorderSide(color: NeonColors.pink)),
                  onPressed: () => _publish(t, room),
                  child: Text(room == null ? 'PUBLISH' : 'EDIT', style: const TextStyle(fontSize: 12)),
                ),
              ));
            },
          ));
        },
      ),
    );
  }
}
