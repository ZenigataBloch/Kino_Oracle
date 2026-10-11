import 'package:flutter/material.dart';
import '../game/game_log.dart';

/// Elenco delle partite salvate nel log (le più recenti in alto).
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<GameRecord>> _games;

  @override
  void initState() {
    super.initState();
    _games = GameLog.load();
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
  static String _fmt(int secs) => '${secs ~/ 60}:${_two(secs % 60)}';
  static String _date(DateTime d) => '${_two(d.day)}/${_two(d.month)} ${_two(d.hour)}:${_two(d.minute)}';

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Svuotare la cronologia?'),
        content: const Text('Le partite salvate verranno cancellate.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Svuota')),
        ],
      ),
    );
    if (ok != true) return;
    await GameLog.clear();
    if (!mounted) return;
    setState(() => _games = GameLog.load());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partite precedenti'),
        actions: [
          IconButton(tooltip: 'Svuota cronologia', icon: const Icon(Icons.delete_outline), onPressed: _confirmClear),
        ],
      ),
      body: FutureBuilder<List<GameRecord>>(
        future: _games,
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final list = snap.data!.reversed.toList();
          if (list.isEmpty) return const Center(child: Text('Nessuna partita ancora: gioca la prima!'));
          final best = list.map((g) => g.points).reduce((a, b) => a > b ? a : b);
          return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(children: [
                Expanded(child: _Stat('${list.length}', 'partite')),
                const SizedBox(width: 12),
                Expanded(child: _Stat('$best', 'record (pt)')),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                'Il registro si svuota dopo ${GameLog.maxGames} partite.',
                style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
              ),
            ),
            for (final g in list)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: g.points == best
                      ? Icon(Icons.emoji_events, color: scheme.primary)
                      : Icon(Icons.movie_filter_outlined, color: scheme.onSurface.withValues(alpha: .4)),
                  title: Text('${g.a}  ⇄  ${g.b}', maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${g.moves} mosse · ${_fmt(g.seconds)} · ${_date(g.date)}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        g.stars > 0 ? '${'★' * g.stars}${'☆' * (3 - g.stars)}' : '—',
                        style: TextStyle(color: scheme.primary, letterSpacing: 1),
                      ),
                      Text('${g.points} pt', style: const TextStyle(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
          ]);
        },
      ),
    );
  }
}

/// Numero grande con etichetta, per il riepilogo in cima.
class _Stat extends StatelessWidget {
  final String value, label;
  const _Stat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: scheme.primary)),
          Text(label, style: TextStyle(fontSize: 13, color: scheme.onSurface.withValues(alpha: .7))),
        ]),
      ),
    );
  }
}
