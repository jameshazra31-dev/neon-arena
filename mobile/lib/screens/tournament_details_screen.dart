import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../main.dart';
import '../widgets/widgets.dart';
import 'join_tournament_screen.dart';

class TournamentDetailsScreen extends StatefulWidget {
  final Tournament tournament;
  const TournamentDetailsScreen({super.key, required this.tournament});
  @override
  State<TournamentDetailsScreen> createState() => _TournamentDetailsScreenState();
}

class _TournamentDetailsScreenState extends State<TournamentDetailsScreen> {
  String? _myStatus;
  RoomDetails? _room;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final row = await supabase.from('participants').select('status').eq('tournament_id', widget.tournament.id).eq('user_id', supabase.auth.currentUser!.id).maybeSingle();
      _myStatus = row?['status'];
      if (_myStatus == 'approved') {
        final room = await supabase.from('tournament_rooms').select().eq('tournament_id', widget.tournament.id).maybeSingle();
        if (room != null) _room = RoomDetails.fromJson(room);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tournament;
    final df = DateFormat('EEEE, d MMMM yyyy - h:mm a');
    return Scaffold(
      appBar: AppBar(title: Text(Games.label(t.game))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (t.bannerUrl != null) ClipRRect(borderRadius: BorderRadius.circular(20), child: CachedNetworkImage(imageUrl: t.bannerUrl!, height: 170, fit: BoxFit.cover)),
        const SizedBox(height: 16),
        Row(children: [Expanded(child: Text(t.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800))), StatusChip(status: t.status)]),
        const SizedBox(height: 6),
        Text(df.format(t.startTime), style: const TextStyle(color: NeonColors.textMuted, fontSize: 15)),
        const SizedBox(height: 16),
        GlassCard(child: Column(children: [
          _row('Game', Games.label(t.game)),
          _row('Entry Fee', t.entryFee == 0 ? 'FREE' : 'Rs.${t.entryFee.toStringAsFixed(0)}'),
          _row('Prize Pool', 'Rs.${t.prizePool.toStringAsFixed(0)}'),
          if (t.perKillPrize > 0) _row('Per Kill', 'Rs.${t.perKillPrize.toStringAsFixed(0)}'),
          _row('Map', t.mapName ?? '-'),
          _row('Mode', t.mode ?? '-'),
          _row('Slots', '${t.availableSlots ?? '-'} left of ${t.totalSlots}'),
        ])),
        const SizedBox(height: 16),
        if (_myStatus == 'approved') _roomCard(),
        if (t.rules != null && t.rules!.isNotEmpty) ...[
          const Text('RULES', style: TextStyle(color: NeonColors.blue, fontWeight: FontWeight.w800, letterSpacing: 2)),
          const SizedBox(height: 8),
          GlassCard(child: Text(t.rules!, style: const TextStyle(height: 1.5))),
          const SizedBox(height: 16),
        ],
        if (_loading) const Center(child: CircularProgressIndicator()) else _cta(),
        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _roomCard() => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('ROOM DETAILS', style: TextStyle(color: NeonColors.green, fontWeight: FontWeight.w800, letterSpacing: 2)),
      const SizedBox(height: 10),
      if (_room == null)
        const Text('Room ID & password will appear here before the match.', style: TextStyle(color: NeonColors.textMuted))
      else ...[
        _row('Room ID', _room!.roomId),
        _row('Password', _room!.roomPassword),
        if (_room!.matchTime != null) _row('Match Time', DateFormat('d MMM - h:mm a').format(_room!.matchTime!)),
      ],
    ])),
  );

  Widget _cta() {
    final t = widget.tournament;
    switch (_myStatus) {
      case 'approved': return const NeonButton(label: 'JOINED', onPressed: null);
      case 'pending': return const NeonButton(label: 'PAYMENT UNDER REVIEW', onPressed: null);
      case 'rejected': return const NeonButton(label: 'PAYMENT REJECTED', onPressed: null);
      default:
        final joinable = t.status == 'upcoming' && (t.availableSlots ?? 1) > 0;
        return NeonButton(
          label: joinable ? 'JOIN TOURNAMENT' : 'REGISTRATION CLOSED',
          onPressed: joinable ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => JoinTournamentScreen(tournament: t))).then((_) => _load()) : null,
        );
    }
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: NeonColors.textMuted)),
      Flexible(child: SelectableText(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700))),
    ]),
  );
}
