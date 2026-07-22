import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/admin_service.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});
  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  late Future<List<Map<String, dynamic>>> _future = AdminService.pendingPayments();
  void _reload() => setState(() => _future = AdminService.pendingPayments());

  Future<void> _review(Map<String, dynamic> p, bool approve) async {
    final note = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: Text(approve ? 'Approve payment?' : 'Reject payment?'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${p['profiles']?['username']} - ${p['tournaments']?['name']}'),
        const SizedBox(height: 12),
        TextField(controller: note, decoration: const InputDecoration(labelText: 'Note (optional)')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: approve ? NeonColors.green : NeonColors.red), onPressed: () => Navigator.pop(context, true), child: Text(approve ? 'APPROVE' : 'REJECT')),
      ],
    ));
    if (ok != true) return;
    await AdminService.reviewPayment(p['id'], approve, note.text);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(approve ? 'Payment approved - player joined' : 'Payment rejected')));
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PENDING PAYMENTS', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3))),
      body: RefreshIndicator(
        color: NeonColors.pink,
        onRefresh: () async => _reload(),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final items = snap.data!;
            if (items.isEmpty) return ListView(children: const [SizedBox(height: 160), Center(child: Text('No pending requests', style: TextStyle(color: NeonColors.textMuted)))]);
            return ListView.builder(padding: const EdgeInsets.all(16), itemCount: items.length, itemBuilder: (_, i) {
              final p = items[i];
              return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p['tournaments']?['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text('${p['profiles']?['username'] ?? 'user'} - ${p['profiles']?['phone'] ?? 'no phone'}', style: const TextStyle(color: NeonColors.textMuted)),
                    const SizedBox(height: 6),
                    Text('Game ID: ${p['game_uid']} - IGN: ${p['ign']}'),
                    Text('UTR: ${p['utr'] ?? '-'}', style: const TextStyle(color: NeonColors.blue, fontWeight: FontWeight.w700)),
                    Text('Due: Rs.${p['amount_due']}', style: const TextStyle(color: NeonColors.green, fontWeight: FontWeight.w700)),
                  ])),
                  FutureBuilder<String?>(future: AdminService.screenshotUrl(p['payment_screenshot_url']), builder: (context, s) =>
                    s.data == null ? const SizedBox(width: 84, height: 84, child: Icon(Icons.image_not_supported, color: NeonColors.textMuted))
                    : GestureDetector(
                        onTap: () => showDialog(context: context, builder: (_) => Dialog(child: InteractiveViewer(child: CachedNetworkImage(imageUrl: s.data!)))),
                        child: ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: s.data!, width: 84, height: 84, fit: BoxFit.cover)),
                      ),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: NeonColors.green), onPressed: () => _review(p, true), icon: const Icon(Icons.check_rounded), label: const Text('APPROVE'))),
                  const SizedBox(width: 10),
                  Expanded(child: FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: NeonColors.red), onPressed: () => _review(p, false), icon: const Icon(Icons.close_rounded), label: const Text('REJECT'))),
                ]),
              ])));
            });
          },
        ),
      ),
    );
  }
}
