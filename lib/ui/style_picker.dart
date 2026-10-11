import 'package:flutter/material.dart';
import '../main.dart';
import '../theme/kino_look.dart';
import '../theme/kino_theme.dart';

/// Scelta dello stile grafico con anteprima delle palette (chiara e scura).
class StylePicker extends StatelessWidget {
  const StylePicker({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: settings,
        builder: (_, __) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Column(children: [for (final k in KinoStyle.values) _StyleCard(k)]),
        ),
      );
}

class _StyleCard extends StatelessWidget {
  final KinoStyle style;
  const _StyleCard(this.style);

  @override
  Widget build(BuildContext context) {
    final def = specs[style]!;
    final cur = settings.spec;
    final selected = settings.style == style;
    final br = BorderRadius.circular(cur.radius);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: br,
        onTap: () => settings.update(style: style),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: br,
            border: Border.all(
              color: selected ? cur.accent : cur.ink.withValues(alpha: .2),
              width: selected ? 2.5 : 1,
            ),
          ),
          child: Row(children: [
            _Swatch(def.light),
            const SizedBox(width: 8),
            _Swatch(def.dark),
            const SizedBox(width: 14),
            Expanded(child: Text(def.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
            if (selected) Icon(Icons.check_circle, color: cur.accent),
          ]),
        ),
      ),
    );
  }
}

/// Miniatura di una palette: sfondo + le "linee" dello stile.
class _Swatch extends StatelessWidget {
  final StyleSpec spec;
  const _Swatch(this.spec);

  @override
  Widget build(BuildContext context) => Container(
        width: 62,
        height: 46,
        decoration: BoxDecoration(
          color: spec.bg,
          borderRadius: BorderRadius.circular(spec.radius.clamp(4, 10)),
          border: Border.all(color: spec.ink.withValues(alpha: .3)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (final c in spec.lines.take(3))
            Container(
              height: 5,
              margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
            ),
        ]),
      );
}

/// Scelta dell'aspetto: Auto / Chiaro / Scuro / AMOLED.
class AppearancePicker extends StatelessWidget {
  const AppearancePicker({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: settings,
        builder: (_, __) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<Appearance>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: Appearance.system, label: Text('Auto')),
                ButtonSegment(value: Appearance.light, label: Text('Chiaro')),
                ButtonSegment(value: Appearance.dark, label: Text('Scuro')),
                ButtonSegment(value: Appearance.amoled, label: Text('AMOLED')),
              ],
              selected: {settings.appearance},
              onSelectionChanged: (s) => settings.update(appearance: s.first),
            ),
          ),
        ),
      );
}
