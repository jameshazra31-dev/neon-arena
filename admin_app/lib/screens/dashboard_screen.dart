import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../main.dart';
import '../services/admin_service.dart';
import 'login_screen.dart';
import 'results_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Map<String, num>> _stats = AdminService.stats();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ADMIN DASHBOARD', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3)),
        actions: [IconButton(icon: const Icon(Icons.logout_rounded), onPressed: () async {
          await supabase.auth.signOut();
          if (context.mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const AdminLoginScreen()), (_) => false);
        })],
      ),
      body: RefreshIndicator(
        color: NeonColors.pink,
        onRefresh: () async => setState(() => _stats = AdminService.stats()),
        child: FutureBuilder<Map<String, num>>(
          future: _stats,
          builder: (context, snap) {
            final s = snap.data;
            return ListView(padding: const EdgeInsets.all(16), children: [
              GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.5, children: [
                _stat('TOTAL USERS', s?['users'], NeonColors.blue),
                _stat('TOURNAMENTS', s?['tournaments'], NeonColors.purple),
                _stat('PENDING PAYMENTS', s?['pending'], NeonColors.amber),
                _stat('ACTIVE MATCHES', s?['live'], NeonColors.pink),
              ]),
              const SizedBox(height: 12),
              Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('TOTAL REVENUE (APPROVED)', style: TextStyle(color: NeonColors.textMuted, fontSize: 11, letterSpacing: 2)),
                Text(s == null ? '...' : 'Rs.${(s['revenue'] ?? 0).toStringAsFixed(0)}', style: const TextStyle(color: NeonColors.green, fontSize: 34, fontWeight: FontWeight.w800)),
              ]))),
              const SizedBox(height: 16),
              Card(child: ListTile(
                leading: const Icon(Icons.military_tech_rounded, color: NeonColors.amber, size: 32),
                title: const Text('Result Management', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Add winners, update leaderboard, mark prizes paid'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ResultsScreen())),
              )),
            ]);
          },
        ),
      ),
    );
  }

  Widget _stat(String label, num? value, Color color) => Card(
    child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(label, style: const TextStyle(color: NeonColors.textMuted, fontSize: 11, letterSpacing: 1.5)),
      const SizedBox(height: 6),
      Text(value?.toString() ?? '...', style: TextStyle(color: color, fontSize: 30, fontWeight: FontWeight.w800)),
    ])),
  );
}
