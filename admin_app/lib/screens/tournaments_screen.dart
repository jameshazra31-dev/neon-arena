import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../services/admin_service.dart';

const kGames = ['free_fire', 'bgmi', 'mlbb', 'efootball'];
const kStatuses = ['upcoming', 'live', 'completed', 'cancelled'];

class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({super.key});
  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  late Future<List<Map<String, dynamic>>> _future = AdminService.tournaments();
  void _reload() => setState(() => _future = AdminService.tournaments());

  Future<void> _openForm([Map<String, dynamic>? existing]) async {
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => TournamentForm(existing: existing)));
    if (saved == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TOURNAMENTS', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3))),
      floatingActionButton: FloatingActionButton.extended(backgroundColor: NeonColors.pink, onPressed: () => _openForm(), icon: const Icon(Icons.add), label: const Text('CREATE')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final items = snap.data!;
          return RefreshIndicator(color: NeonColors.pink, onRefresh: () async => _reload(), child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 90), itemCount: items.length,
            itemBuilder: (_, i) {
              final t = items[i];
              return Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), child: ListTile(
                onTap: () => _openForm(t),
                title: Text('${t['name']}${t['is_featured'] == true ? ' (Featured)' : ''}', style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${t['game']} - Rs.${t['entry_fee']} entry - Rs.${t['prize_pool']} prize\n${DateFormat('d MMM, h:mm a').format(DateTime.parse(t['start_time']).toLocal())} - ${t['total_slots']} slots'),
                isThreeLine: true,
                trailing: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  Text((t['status'] as String).toUpperCase(), style: const TextStyle(color: NeonColors.blue, fontSize: 11, fontWeight: FontWeight.w800)),
                  GestureDetector(onTap: () async {
                    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                      title: const Text('Delete tournament?'), content: Text(t['name']),
                      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: NeonColors.red)))],
                    ));
                    if (ok == true) { await AdminService.deleteTournament(t['id']); _reload(); }
                  }, child: const Icon(Icons.delete_outline, color: NeonColors.red, size: 20)),
                ]),
              ));
            },
          ));
        },
      ),
    );
  }
}

class TournamentForm extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const TournamentForm({super.key, this.existing});
  @override
  State<TournamentForm> createState() => _TournamentFormState();
}

class _TournamentFormState extends State<TournamentForm> {
  late final e = widget.existing;
  late final _name = TextEditingController(text: e?['name']);
  late final _fee = TextEditingController(text: e?['entry_fee']?.toString());
  late final _prize = TextEditingController(text: e?['prize_pool']?.toString());
  late final _perKill = TextEditingController(text: e?['per_kill_prize']?.toString());
  late final _slots = TextEditingController(text: e?['total_slots']?.toString());
  late final _map = TextEditingController(text: e?['map_name']);
  late final _mode = TextEditingController(text: e?['mode']);
  late final _rules = TextEditingController(text: e?['rules']);
  late final _banner = TextEditingController(text: e?['banner_url']);
  late final _upiId = TextEditingController(text: e?['upi_id']);
  late final _upiQr = TextEditingController(text: e?['upi_qr_url']);
  late String _game = e?['game'] ?? kGames.first;
  late String _status = e?['status'] ?? 'upcoming';
  late bool _featured = e?['is_featured'] ?? false;
  late DateTime _start = e == null ? DateTime.now().add(const Duration(days: 1)) : DateTime.parse(e!['start_time']).toLocal();
  bool _busy = false;

  Future<void> _pickStart() async {
    final date = await showDatePicker(context: context, initialDate: _start, firstDate: DateTime.now().subtract(const Duration(days: 1)), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_start));
    if (time == null) return;
    setState(() => _start = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await AdminService.upsertTournament({
        'name': _name.text.trim(), 'game': _game,
        'entry_fee': double.tryParse(_fee.text) ?? 0, 'prize_pool': double.tryParse(_prize.text) ?? 0,
        'per_kill_prize': double.tryParse(_perKill.text) ?? 0, 'start_time': _start.toUtc().toIso8601String(),
        'total_slots': int.tryParse(_slots.text) ?? 0, 'map_name': _map.text.trim(), 'mode': _mode.text.trim(),
        'rules': _rules.text.trim(), 'status': _status, 'is_featured': _featured,
        'banner_url': _banner.text.trim().isEmpty ? null : _banner.text.trim(),
        'upi_id': _upiId.text.trim().isEmpty ? null : _upiId.text.trim(),
        'upi_qr_url': _upiQr.text.trim().isEmpty ? null : _upiQr.text.trim(),
      }, id: e?['id']);
      if (mounted) Navigator.pop(context, true);
    } catch (err) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err.toString()))); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(e == null ? 'Create Tournament' : 'Edit Tournament')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Tournament Name')),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: _game, decoration: const InputDecoration(labelText: 'Game'), items: kGames.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(), onChanged: (v) => setState(() => _game = v!)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(controller: _fee, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Entry Fee Rs.'))),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: _prize, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Prize Pool Rs.'))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(controller: _perKill, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Per Kill Rs.'))),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: _slots, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Slots'))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(controller: _map, decoration: const InputDecoration(labelText: 'Map Name'))),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: _mode, decoration: const InputDecoration(labelText: 'Mode'))),
        ]),
        const SizedBox(height: 12),
        TextField(controller: _rules, maxLines: 4, decoration: const InputDecoration(labelText: 'Rules')),
        const SizedBox(height: 12),
        TextField(controller: _banner, decoration: const InputDecoration(labelText: 'Banner URL')),
        const SizedBox(height: 12),
        TextField(controller: _upiId, decoration: const InputDecoration(labelText: 'UPI ID')),
        const SizedBox(height: 12),
        TextField(controller: _upiQr, decoration: const InputDecoration(labelText: 'UPI QR Image URL')),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: _status, decoration: const InputDecoration(labelText: 'Status'), items: kStatuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _status = v!)),
        const SizedBox(height: 12),
        SwitchListTile(value: _featured, onChanged: (v) => setState(() => _featured = v), title: const Text('Featured tournament'), activeColor: NeonColors.pink),
        const SizedBox(height: 12),
        ListTile(title: const Text('Start Date & Time'), subtitle: Text(DateFormat('d MMM yyyy, h:mm a').format(_start)), trailing: const Icon(Icons.calendar_today, color: NeonColors.pink), onTap: _pickStart),
        const SizedBox(height: 20),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: NeonColors.pink, minimumSize: const Size.fromHeight(52)), onPressed: _busy ? null : _save, child: Text(_busy ? 'SAVING...' : (e == null ? 'CREATE TOURNAMENT' : 'SAVE CHANGES'), style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2))),
        const SizedBox(height: 40),
      ]),
    );
  }
}
