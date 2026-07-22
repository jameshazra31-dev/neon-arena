import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/admin_service.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});
  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late Future<List<Map<String, dynamic>>> _tournaments = AdminService.tournaments(statuses: ['live', 'completed']);
  late Future<List<Map<String, dynamic>>> _results = AdminService.recentResults();
  String? _tournamentId, _userId;
  List<Map<String, dynamic>> _players = [];
  final _rank = TextEditingController(), _kills = TextEditingController(text: '0'), _prize = TextEditingController();
  bool _busy = false;

  Future<void> _loadPlayers(String tournamentId) async {
    final players = await AdminService.approvedPlayers(tournamentId);
    setState(() { _tournamentId = tournamentId; _players = players; _userId = null; });
  }

  Future<void> _submit() async {
    if (_tournamentId == null || _userId == null || _rank.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select tournament, player and rank')));
      return;
    }
    setState(() => _busy = true);
    try {
      await AdminService.addResult(tournamentId: _tournamentId!, userId: _userId!, rank: int.parse(_rank.text), kills: int.tryParse(_kills.text) ?? 0, prize: double.tryParse(_prize.text) ?? 0);
      _rank.clear(); _kills.text = '0'; _prize.clear();
      setState(() => _results = AdminService.recentResults());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Result added - player notified')));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RESULTS', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('ADD WINNER', style: TextStyle(color: NeonColors.textMuted, letterSpacing: 2, fontSize: 12)),
          const SizedBox(height: 10),
          FutureBuilder<List<Map<String, dynamic>>>(future: _tournaments, builder: (context, snap) => DropdownButtonFormField<String>(
            value: _tournamentId,
            decoration: const InputDecoration(labelText: 'Tournament'),
            items: (snap.data ?? []).map((t) => DropdownMenuItem(value: t['id'] as String, child: Text(t['name'], overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (v) => v != null ? _loadPlayers(v) : null,
          )),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _userId,
            decoration: const InputDecoration(labelText: 'Player (approved only)'),
            items: _players.map((p) => DropdownMenuItem(value: p['user_id'] as String, child: Text('${p['profiles']?['username']} (${p['ign']})', overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (v) => setState(() => _userId = v),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: _rank, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Rank'))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _kills, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Kills'))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _prize, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Prize Rs.'))),
          ]),
          const SizedBox(height: 14),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: NeonColors.pink, minimumSize: const Size.fromHeight(48)), onPressed: _busy ? null : _submit, child: Text(_busy ? 'SAVING...' : 'ADD RESULT', style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2))),
        ]))),
        const SizedBox(height: 18),
        const Text('RECENT RESULTS', style: TextStyle(color: NeonColors.textMuted, letterSpacing: 2, fontSize: 12)),
        const SizedBox(height: 8),
        FutureBuilder<List<Map<String, dynamic>>>(future: _results, builder: (context, snap) => Column(
          children: (snap.data ?? []).map((r) => Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
            leading: Text('#${r['rank']}', style: const TextStyle(color: NeonColors.amber, fontSize: 20, fontWeight: FontWeight.w800)),
            title: Text('${r['profiles']?['username']} - Rs.${r['prize_amount']}', style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${r['tournaments']?['name']} - ${r['kills']} kills'),
            trailing: r['prize_status'] == 'paid'
              ? const Text('PAID', style: TextStyle(color: NeonColors.green, fontWeight: FontWeight.w800))
              : TextButton(onPressed: () async { await AdminService.markPrizePaid(r['id']); setState(() => _results = AdminService.recentResults()); }, child: const Text('Mark Paid')),
          ))).toList(),
        )),
      ]),
    );
  }
}
