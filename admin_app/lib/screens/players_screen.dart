import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/admin_service.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});
  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final _search = TextEditingController();
  late Future<List<Map<String, dynamic>>> _future = AdminService.players();
  void _reload() => setState(() => _future = AdminService.players(search: _search.text));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PLAYERS', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3))),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 4), child: TextField(
          controller: _search, onSubmitted: (_) => _reload(),
          decoration: InputDecoration(hintText: 'Search username...', prefixIcon: const Icon(Icons.search_rounded), suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward_rounded, color: NeonColors.pink), onPressed: _reload)),
        )),
        Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final items = snap.data!;
            return RefreshIndicator(color: NeonColors.pink, onRefresh: () async => _reload(), child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) {
                final p = items[i]; final banned = p['is_banned'] == true;
                return Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5), child: ListTile(
                  leading: CircleAvatar(backgroundColor: NeonColors.purple.withOpacity(.25), child: Text((p['username'] ?? '?').toString().substring(0, 1).toUpperCase(), style: const TextStyle(color: NeonColors.purple, fontWeight: FontWeight.w800))),
                  title: Text(p['username'] ?? 'player', style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${p['phone'] ?? 'no phone'} - wallet Rs.${p['wallet_balance']}'),
                  trailing: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: banned ? NeonColors.green : NeonColors.red, padding: const EdgeInsets.symmetric(horizontal: 14)),
                    onPressed: () async { await AdminService.setBanned(p['id'], !banned); _reload(); },
                    child: Text(banned ? 'UNBAN' : 'BAN', style: const TextStyle(fontSize: 12)),
                  ),
                ));
              },
            ));
          },
        )),
      ]),
    );
  }
}
