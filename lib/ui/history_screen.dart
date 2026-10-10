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
          return ListView(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                '${list.length} partite · record: $best punti\n'
                'Il registro si svuota dopo ${GameLog.maxGames} partite.',
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
            ),
            for (final g in list)
              ListTile(
                title: Text('${g.a}  ⇄  ${g.b}', maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${g.moves} mosse · ${_fmt(g.seconds)} · ${_date(g.date)}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(g.stars > 0 ? '${'★' * g.stars}${'☆' * (3 - g.stars)}' : '—'),
                    Text('${g.points} pt', style: const TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
          ]);
        },
      ),
    );
  }
}
