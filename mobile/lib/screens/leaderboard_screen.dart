import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/tournament_service.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LEADERBOARD', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3))),
      body: FutureBuilder<List<LeaderboardEntry>>(
        future: TournamentService.leaderboard(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final items = snap.data!;
          if (items.isEmpty) return const Center(child: Text('No winners yet - be the first!', style: TextStyle(color: NeonColors.textMuted)));
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final e = items[i];
              final medal = switch (i) { 0 => '1st', 1 => '2nd', 2 => '3rd', _ => '${i + 1}' };
              return Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5), child: ListTile(
                leading: SizedBox(width: 66, child: Row(children: [
                  SizedBox(width: 30, child: Text(medal, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: NeonColors.amber))),
                  CircleAvatar(radius: 16, backgroundColor: NeonColors.purple.withOpacity(.3), backgroundImage: e.avatarUrl == null ? null : CachedNetworkImageProvider(e.avatarUrl!), child: e.avatarUrl == null ? Text(e.username.isEmpty ? '?' : e.username[0].toUpperCase()) : null),
                ])),
                title: Text(e.username, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${e.tournamentsWon} wins - ${e.totalKills} kills'),
                trailing: Text('Rs.${e.totalWinnings.toStringAsFixed(0)}', style: const TextStyle(color: NeonColors.green, fontSize: 16, fontWeight: FontWeight.w800)),
              ));
            },
          );
        },
      ),
    );
  }
}
