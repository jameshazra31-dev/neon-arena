import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/tournament_service.dart';
import '../widgets/widgets.dart';
import 'tournament_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  String? _gameFilter;
  List<Tournament> _featured = [], _items = [];
  bool _loading = true;
  static const _statuses = ['upcoming', 'live', 'completed'];

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() { if (!_tabs.indexIsChanging) _load(); });
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([TournamentService.featured(), TournamentService.list(status: _statuses[_tabs.index], game: _gameFilter)]);
      if (!mounted) return;
      setState(() { _featured = results[0]; _items = results[1]; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: ShaderMask(shaderCallback: (r) => NeonColors.neonGradient.createShader(r), child: const Text('NEONARENA', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 4, color: Colors.white)))),
      body: RefreshIndicator(
        onRefresh: _load, color: NeonColors.blue,
        child: ListView(children: [
          if (_featured.isNotEmpty) SizedBox(height: 150, child: PageView.builder(
            controller: PageController(viewportFraction: .9),
            itemCount: _featured.length,
            itemBuilder: (_, i) {
              final t = _featured[i];
              return GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TournamentDetailsScreen(tournament: t))),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(gradient: NeonColors.neonGradient, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: NeonColors.purple.withOpacity(.4), blurRadius: 20)]),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('FEATURED - ${Games.label(t.game)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2)),
                    const SizedBox(height: 6),
                    Text(t.name, maxLines: 2, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text('Prize Rs.${t.prizePool.toStringAsFixed(0)} - Entry ${t.entryFee == 0 ? 'FREE' : 'Rs.${t.entryFee.toStringAsFixed(0)}'}'),
                  ]),
                ),
              );
            },
          )),
          SizedBox(height: 56, child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            children: [ChoiceChip(label: const Text('All'), selected: _gameFilter == null, onSelected: (_) { setState(() => _gameFilter = null); _load(); }),
              for (final g in Games.all) Padding(padding: const EdgeInsets.only(left: 8), child: ChoiceChip(label: Text(Games.label(g)), selected: _gameFilter == g, selectedColor: NeonColors.purple.withOpacity(.35), onSelected: (_) { setState(() => _gameFilter = g); _load(); }))],
          )),
          TabBar(controller: _tabs, indicatorColor: NeonColors.blue, labelColor: NeonColors.blue, unselectedLabelColor: NeonColors.textMuted, tabs: const [Tab(text: 'UPCOMING'), Tab(text: 'LIVE'), Tab(text: 'COMPLETED')]),
          if (_loading)
            ...List.generate(3, (_) => Shimmer.fromColors(baseColor: NeonColors.surface, highlightColor: NeonColors.surface.withOpacity(.4), child: Container(height: 180, margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: NeonColors.surface, borderRadius: BorderRadius.circular(20)))))
          else if (_items.isEmpty)
            const Padding(padding: EdgeInsets.all(48), child: Center(child: Text('No tournaments here yet', style: TextStyle(color: NeonColors.textMuted))))
          else
            ..._items.map((t) => TournamentCard(tournament: t, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TournamentDetailsScreen(tournament: t))).then((_) => _load()))),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}
