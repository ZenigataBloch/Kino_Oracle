import 'package:flutter/material.dart';
import '../game/daily.dart';
import '../game/media_pick.dart';
import '../game/saga_rule.dart';
import '../main.dart';

/// Metti true per riattivare Duello a turni e Sfida giornaliera.
const kChallengesEnabled = false;

/// Scelta della modalità dopo GIOCA. Restituisce 'classic', 'duel', 'daily' o null (annullato).
Future<String?> showModeSheet(BuildContext context) => showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _ModeSheet(),
    );

class _ModeSheet extends StatefulWidget {
  const _ModeSheet();
  @override
  State<_ModeSheet> createState() => _ModeSheetState();
}

class _ModeSheetState extends State<_ModeSheet> {
  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('SCEGLI LA MODALITÀ',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.6, color: accent)),
          const SizedBox(height: 14),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.movie_filter_rounded, color: accent),
                  const SizedBox(width: 10),
                  const Text('CLASSICA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                ]),
                const SizedBox(height: 14),
                const Text('Limite di mosse (minimo + N)'),
                const SizedBox(height: 6),
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: -1, label: Text('Libero')),
                    ButtonSegment(value: 0, label: Text('+0')),
                    ButtonSegment(value: 2, label: Text('+2')),
                    ButtonSegment(value: 4, label: Text('+4')),
                  ],
                  selected: {settings.moveLimit},
                  onSelectionChanged: (v) {
                    settings.update(moveLimit: v.first);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 14),
                const Text('Cosa usare per i collegamenti'),
                const SizedBox(height: 6),
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 'movie', label: Text('Film'), icon: Icon(Icons.movie)),
                    ButtonSegment(value: 'tv', label: Text('Serie TV'), icon: Icon(Icons.tv)),
                    ButtonSegment(value: 'both', label: Text('Entrambi')),
                  ],
                  selected: {MediaPick.mode},
                  onSelectionChanged: (v) async {
                    await MediaPick.set(v.first);
                    if (mounted) setState(() {});
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Niente film della stessa saga'),
                  value: SagaRule.enabled,
                  onChanged: (v) async {
                    await SagaRule.set(v);
                    if (mounted) setState(() {});
                  },
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () => Navigator.pop(context, 'classic'),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('INIZIA', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w800)),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 10),
          _challenge(Icons.people, 'DUELLO A TURNI', 'Due giocatori sullo stesso telefono', 'duel'),
          const SizedBox(height: 8),
          _challenge(Icons.today, Daily.label, 'Stessa coppia per tutti, una al giorno', 'daily'),
        ]),
      ),
    );
  }

  Widget _challenge(IconData icon, String title, String subtitle, String value) => Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          enabled: kChallengesEnabled,
          leading: Icon(icon),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
          subtitle: Text(kChallengesEnabled ? subtitle : 'Presto disponibile'),
          onTap: kChallengesEnabled ? () => Navigator.pop(context, value) : null,
        ),
      );
}
