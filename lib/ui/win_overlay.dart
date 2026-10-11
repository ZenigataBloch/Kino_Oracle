import 'dart:math';
import 'package:flutter/material.dart';
import '../game/board_state.dart';
import '../game/game_log.dart';
import '../game/recap.dart';
import '../theme/kino_look.dart';
import '../theme/kino_theme.dart';

/// Schermata di vittoria: coriandoli, stelle che compaiono una alla volta,
/// punteggio che sale, dettaglio dei punti e suggerimento per la prossima sfida.
class WinOverlay extends StatefulWidget {
  final BoardState state;
  final StyleSpec spec;
  final VoidCallback onNewGame;
  final VoidCallback onClose;
  final void Function(PairingHint hint) onPlayHint;

  const WinOverlay({
    super.key,
    required this.state,
    required this.spec,
    required this.onNewGame,
    required this.onClose,
    required this.onPlayHint,
  });

  @override
  State<WinOverlay> createState() => _WinOverlayState();
}

class _WinOverlayState extends State<WinOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_Piece> _pieces;
  PairingHint? _hint;
  bool _hintReady = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 5200))..forward();
    final rnd = Random();
    final colors = <Color>[...widget.spec.lines, widget.spec.accent, Colors.white];
    _pieces = List.generate(90, (_) => _Piece(rnd, colors));
    _loadHint();
  }

  Future<void> _loadHint() async {
    var played = <String>{};
    try {
      played = await GameLog.playedPairs();
    } catch (_) {
      // senza log suggerisco comunque
    }
    if (!mounted) return;
    setState(() {
      _hint = suggestPairing(widget.state, played);
      _hintReady = true;
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Avanzamento 0..1 di un tratto della timeline (frazioni della durata totale).
  double _t(double from, double to, [Curve curve = Curves.easeOut]) =>
      curve.transform(((_c.value - from) / (to - from)).clamp(0.0, 1.0).toDouble());

  static String _fmt(int secs) => '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (_, __) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final r = Recap.of(widget.state);
          return Stack(children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: widget.onClose,
                child: ColoredBox(color: Colors.black.withOpacity(0.55 * _t(0, 0.1))),
              ),
            ),
            Center(
              child: Transform.scale(
                scale: _t(0, 0.14, Curves.easeOutBack),
                child: Opacity(opacity: _t(0, 0.08), child: _card(r)),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(child: CustomPaint(painter: _ConfettiPainter(_pieces, _c.value))),
            ),
          ]);
        },
      ),
    );
  }

  Widget _card(Recap r) {
    final spec = widget.spec;
    final s = widget.state;
    final rows = <(String, String, bool)>[
      ('Collegamento completato', '+${r.basePts}', false),
      if (r.stars > 0) ('Stelle × ${r.stars}', '+${r.starPts}', false),
      ('Bonus velocità (${_fmt(r.seconds)})', '+${r.timePts}', false),
      if (r.extra > 0) ('Mosse oltre il minimo × ${r.extra}', '−${r.penaltyPts}', true),
    ];
    final note = s.minNote;
    final tail = _t(0.62, 0.76);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: spec.bg,
          borderRadius: BorderRadius.circular(spec.radius + 10),
          border: Border.all(color: spec.ink, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 30, offset: Offset(0, 12))],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (spec.label == 'Cinema') _bulbs(),
            if (spec.label == 'Bacheca') const _PinDot(),
            Text('COLLEGATI!',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2, color: spec.accent)),
            const SizedBox(height: 4),
            Text('${s.a.name}  ⇄  ${s.b.name}',
                textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (r.stars > 0)
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = 0; i < 3; i++)
                  Transform.scale(
                    scale: _t(0.14 + 0.07 * i, 0.26 + 0.07 * i, Curves.elasticOut),
                    child: Icon(
                      i < r.stars ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 48,
                      color: i < r.stars ? const Color(0xFFFFB400) : spec.ink.withOpacity(.3),
                    ),
                  ),
              ])
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  s.optimalReady ? 'Percorso minimo non disponibile' : 'Calcolo il percorso minimo…',
                  style: TextStyle(color: spec.ink.withOpacity(.6)),
                ),
              ),
            const SizedBox(height: 4),
            Text('${(r.total * _t(0.30, 0.60, Curves.easeOutCubic)).round()}',
                style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w900, height: 1.1)),
            Text('PUNTI', style: TextStyle(letterSpacing: 4, fontWeight: FontWeight.w700, color: spec.ink.withOpacity(.6))),
            const SizedBox(height: 12),
            for (var i = 0; i < rows.length; i++) _row(i, rows[i]),
            const Divider(height: 24),
            Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
              _pill(Icons.alt_route, '${r.moves} mosse'),
              _pill(Icons.person, '${r.actors} attori'),
              _pill(Icons.movie, '${r.movies} film'),
              _pill(Icons.timer_outlined, _fmt(r.seconds)),
            ]),
            if (note != null) ...[
              const SizedBox(height: 10),
              Text(note, textAlign: TextAlign.center, style: TextStyle(color: spec.ink.withOpacity(.7))),
            ],
            const SizedBox(height: 14),
            Opacity(opacity: tail, child: _suggestion()),
            const SizedBox(height: 14),
            Opacity(
              opacity: tail,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: widget.onNewGame,
                  icon: const Icon(Icons.replay),
                  label: const Text('NUOVA PARTITA'),
                ),
              ),
            ),
            Opacity(
              opacity: tail,
              child: TextButton(onPressed: widget.onClose, child: const Text('Guarda la mappa')),
            ),
          ]),
        ),
      ),
    );
  }

  /// Fila di lampadine che si accendono a turno (solo stile Cinema).
  Widget _bulbs() {
    final gold = widget.spec.lines.last;
    final phase = (_c.value * 8).floor().isEven;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < 9; i++)
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: gold.withValues(alpha: i.isEven == phase ? 1 : .4),
              boxShadow: [BoxShadow(color: gold.withValues(alpha: i.isEven == phase ? .7 : 0), blurRadius: 6)],
            ),
          ),
      ]),
    );
  }

  Widget _row(int i, (String, String, bool) row) {
    final t = _t(0.42 + 0.06 * i, 0.54 + 0.06 * i);
    final color = row.$3 ? widget.spec.accent : widget.spec.ink;
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, 12 * (1 - t)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Expanded(child: Text(row.$1)),
            Text(row.$2, style: TextStyle(fontWeight: FontWeight.w800, color: color)),
          ]),
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: widget.spec.ink.withOpacity(.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _suggestion() {
    final spec = widget.spec;
    final h = _hint;
    if (!_hintReady) return const SizedBox.shrink();
    if (h == null) {
      return Text(
        'Suggerimento: prova due attori di epoche o paesi diversi per un percorso più lungo.',
        textAlign: TextAlign.center,
        style: TextStyle(color: spec.ink.withOpacity(.7)),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(spec.radius + 2),
        border: Border.all(color: spec.accent.withOpacity(.6), width: 2),
      ),
      child: Column(children: [
        Text('PROSSIMA SFIDA',
            style: TextStyle(fontSize: 12, letterSpacing: 3, fontWeight: FontWeight.w800, color: spec.accent)),
        const SizedBox(height: 6),
        Text('${h.x.name}  ⇄  ${h.y.name}',
            textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(
          'Sul tavolo li separano ${h.films} film: riesci a collegarli con meno?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: spec.ink.withOpacity(.7)),
        ),
        const SizedBox(height: 8),
        FilledButton.tonal(onPressed: () => widget.onPlayHint(h), child: const Text('Gioca questa sfida')),
      ]),
    );
  }
}

/// Puntina in cima alla scheda (solo stile Bacheca).
class _PinDot extends StatelessWidget {
  const _PinDot();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-.4, -.4),
            colors: [Color.alphaBlend(Colors.white.withValues(alpha: .55), color), color],
          ),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 3, offset: Offset(1, 2))],
        ),
      ),
    );
  }
}

class _Piece {
  final double x, delay, size, sway, phase, spin, aspect;
  final Color color;
  _Piece(Random r, List<Color> colors)
      : x = r.nextDouble(),
        delay = r.nextDouble() * 0.45,
        size = 6 + r.nextDouble() * 8,
        sway = 10 + r.nextDouble() * 30,
        phase = r.nextDouble() * 6.28,
        spin = (r.nextDouble() - 0.5) * 20,
        aspect = 0.4 + r.nextDouble() * 0.6,
        color = colors[r.nextInt(colors.length)];
}

class _ConfettiPainter extends CustomPainter {
  final List<_Piece> pieces;
  final double t;
  _ConfettiPainter(this.pieces, this.t);

  @override
  void paint(Canvas c, Size size) {
    for (final p in pieces) {
      final prog = (t - p.delay) / (1 - p.delay);
      if (prog <= 0 || prog >= 1) continue;
      final y = -20 + (size.height + 40) * prog;
      final x = p.x * size.width + sin(prog * 8 + p.phase) * p.sway;
      c.save();
      c.translate(x, y);
      c.rotate(prog * p.spin);
      c.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * p.aspect),
        Paint()..color = p.color,
      );
      c.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}
