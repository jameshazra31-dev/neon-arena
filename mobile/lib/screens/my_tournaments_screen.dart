import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/tournament_service.dart';
import '../widgets/widgets.dart';
import 'tournament_details_screen.dart';

class MyTournamentsScreen extends StatefulWidget {
  const MyTournamentsScreen({super.key});
  @override
  State<MyTournamentsScreen> createState() => _MyTournamentsScreenState();
}

class _MyTournamentsScreenState extends State<MyTournamentsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MY MATCHES', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3)),
        bottom: TabBar(controller: _tabs, indicatorColor: NeonColors.blue, labelColor: NeonColors.blue, unselectedLabelColor: NeonColors.textMuted, tabs: const [Tab(text: 'JOINED'), Tab(text: 'WINNINGS')])),
      body: TabBarView(controller: _tabs, children: [_joined(), _winnings()]),
    );
  }

  Widget _joined() => FutureBuilder<List<Participant>>(
    future: TournamentService.myParticipations(),
    builder: (context, snap) {
      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
      final items = snap.data!;
      if (items.isEmpty) return const Center(child: Text('No tournaments joined yet', style: TextStyle(color: NeonColors.textMuted)));
      return ListView.builder(itemCount: items.length, itemBuilder: (_, i) {
        final p = items[i]; final t = p.tournament;
        return Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), child: ListTile(
          onTap: t == null ? null : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TournamentDetailsScreen(tournament: t))),
          leading: Text(Games.emoji(t?.game ?? ''), style: const TextStyle(fontSize: 28)),
          title: Text(t?.name ?? 'Tournament', style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(t == null ? '' : DateFormat('d MMM - h:mm a').format(t.startTime)),
          trailing: StatusChip(status: p.status),
        ));
      });
    },
  );

  Widget _winnings() => FutureBuilder<List<MatchResult>>(
    future: TournamentService.myResults(),
    builder: (context, snap) {
      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
      final items = snap.data!;
      if (items.isEmpty) return const Center(child: Text('No results yet - go win something!', style: TextStyle(color: NeonColors.textMuted)));
      return ListView.builder(itemCount: items.length, itemBuilder: (_, i) {
        final r = items[i];
        return Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), child: ListTile(
          leading: CircleAvatar(backgroundColor: NeonColors.purple.withOpacity(.25), child: Text('#${r.rank}', style: const TextStyle(color: NeonColors.blue, fontWeight: FontWeight.w800))),
          title: Text(r.tournamentName ?? 'Tournament', style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('${r.kills} kills'),
          trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Rs.${r.prizeAmount.toStringAsFixed(0)}', style: const TextStyle(color: NeonColors.green, fontSize: 16, fontWeight: FontWeight.w800)),
            Text(r.prizeStatus.toUpperCase(), style: TextStyle(fontSize: 10, color: r.prizeStatus == 'paid' ? NeonColors.green : NeonColors.amber)),
          ]),
        ));
      });
    },
  );
}
