import 'dart:math';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/kino_look.dart';
import '../theme/kino_theme.dart';

// Materiali dei tre stili (uguali in chiaro e scuro, come oggetti reali sulla mappa).
const _paper = Color(0xFFF4EBD8); // carta delle polaroid
const _paperInk = Color(0xFF2B2118); // inchiostro sulla carta
const _tape = Color(0xFFE9D78A); // nastro adesivo
const _film = Color(0xFF17110D); // pellicola
const _sprocket = Color(0xFFEAD9B0); // fori della pellicola
const _bulb = Color(0xFFFFEFB8); // lampadine
const _shadow = [BoxShadow(color: Color(0x44000000), blurRadius: 6, offset: Offset(2, 4))];

/// Immagine di rete con segnaposto mentre carica o se manca. Va messa in uno spazio di dimensione fissa.
class NodeImage extends StatelessWidget {
  final String? url;
  final IconData fallback;
  final Color color;
  const NodeImage({super.key, required this.url, required this.fallback, required this.color});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, box) {
        final ph = ColoredBox(
          color: color.withValues(alpha: .08),
          child: Center(child: Icon(fallback, size: box.biggest.shortestSide * .5, color: color.withValues(alpha: .35))),
        );
        if (url == null) return ph;
        return Image.network(
          url!,
          fit: BoxFit.cover,
          width: box.maxWidth,
          height: box.maxHeight,
          loadingBuilder: (_, child, progress) => progress == null ? child : ph,
          errorBuilder: (_, __, ___) => ph,
        );
      });
}

/// Puntina rossa della Bacheca.
class _Pin extends StatelessWidget {
  final Color color;
  const _Pin(this.color);

  @override
  Widget build(BuildContext context) => Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-.4, -.4),
            colors: [Color.alphaBlend(Colors.white.withValues(alpha: .55), color), color],
          ),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 3, offset: Offset(1, 2))],
        ),
      );
}

/// Anello di lampadine attorno alla foto (stile Cinema).
class _BulbRing extends CustomPainter {
  final Color glow;
  final int count;
  _BulbRing(this.glow, this.count);

  @override
  void paint(Canvas c, Size size) {
    final center = size.center(Offset.zero);
    final r = size.width / 2 - 3;
    final glowPaint = Paint()..color = glow.withValues(alpha: .45);
    final core = Paint()..color = _bulb;
    for (var i = 0; i < count; i++) {
      final a = 2 * pi * i / count - pi / 2;
      final p = center + Offset(cos(a), sin(a)) * r;
      c.drawCircle(p, 4.5, glowPaint);
      c.drawCircle(p, 2.4, core);
    }
  }

  @override
  bool shouldRepaint(covariant _BulbRing old) => old.glow != glow || old.count != count;
}

/// Fori laterali della pellicola.
class _Sprockets extends StatelessWidget {
  const _Sprockets();

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: 10, child: CustomPaint(painter: _SprocketPainter(), size: const Size(10, double.infinity)));
}

class _SprocketPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size size) {
    final p = Paint()..color = _sprocket.withValues(alpha: .85);
    for (double y = 6; y + 7 <= size.height - 4; y += 14) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(2.5, y, 5, 7), const Radius.circular(1.5)), p);
    }
  }

  @override
  bool shouldRepaint(covariant _SprocketPainter old) => false;
}

/// Attore sulla mappa: A e B sono piu grandi e hanno il badge; gli scambi (2+ film) risaltano.
///  - Metro: foto tonda con bordo, come una stazione
///  - Bacheca: polaroid con puntina, leggermente storta
///  - Cinema: foto tonda con corona di lampadine e targhetta
class PersonNode extends StatelessWidget {
  static const width = 150.0;
  final Person person;
  final StyleSpec spec;
  final bool isA, isB, hub;
  final VoidCallback onTap;
  const PersonNode({
    super.key,
    required this.person,
    required this.spec,
    required this.isA,
    required this.isB,
    required this.hub,
    required this.onTap,
  });

  double get _d => (isA || isB) ? 100 : (hub ? 80 : 72);

  /// Diametro complessivo (compreso l'anello doppio): serve a centrare il nodo.
  double get size => hub ? _d + 10 : _d;

  /// Inclinazione fissa per persona (non cambia a ogni ricostruzione).
  double get _tilt => ((person.id % 7) - 3) * .014;

  Widget _photo() {
    final strong = isA || isB || hub;
    final img = NodeImage(url: person.photoUrl, fallback: Icons.person, color: spec.ink);
    switch (spec.label) {
      case 'Bacheca':
        return Transform.rotate(
          angle: _tilt,
          child: Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
            Container(
              width: size,
              height: size,
              padding: EdgeInsets.all(strong ? 6 : 5),
              decoration: BoxDecoration(
                color: _paper,
                borderRadius: BorderRadius.circular(3),
                border: strong ? Border.all(color: spec.accent, width: 3) : null,
                boxShadow: _shadow,
              ),
              child: img,
            ),
            Positioned(top: -7, child: _Pin(spec.accent)),
          ]),
        );
      case 'Cinema':
        return SizedBox(
          width: size,
          height: size,
          child: Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
            Positioned(
              left: -8,
              top: -8,
              right: -8,
              bottom: -8,
              child: CustomPaint(painter: _BulbRing(spec.lines.last, hub ? 20 : 14)),
            ),
            Container(
              width: _d,
              height: _d,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: spec.bg,
                border: Border.all(color: spec.ink, width: strong ? 4 : 3),
              ),
              child: ClipOval(child: img),
            ),
          ]),
        );
      default:
        Widget photo = Container(
          width: _d,
          height: _d,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: spec.bg,
            border: Border.all(color: spec.ink, width: strong ? 5 : 3.5),
          ),
          child: ClipOval(child: img),
        );
        if (hub) {
          photo = Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: spec.ink, width: 2)),
            child: photo,
          );
        }
        return photo;
    }
  }

  Widget _label() {
    final bold = (isA || isB) ? FontWeight.w900 : FontWeight.w700;
    Text name(Color color) => Text(
          person.name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: color, fontSize: 15, height: 1.15, fontWeight: bold),
        );
    return switch (spec.label) {
      'Bacheca' => Transform.rotate(
          angle: -_tilt * .6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: _paper, borderRadius: BorderRadius.circular(2), boxShadow: _shadow),
            child: name(_paperInk),
          ),
        ),
      'Cinema' => Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(color: spec.ink, borderRadius: BorderRadius.circular(4)),
          child: name(spec.bg),
        ),
      _ => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: spec.bg.withValues(alpha: .94),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: spec.ink.withValues(alpha: .3)),
          ),
          child: name(spec.ink),
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    Widget photo = _photo();
    if (isA || isB) {
      photo = Stack(clipBehavior: Clip.none, children: [
        photo,
        Positioned(
          top: -6,
          left: -6,
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: spec.accent,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Text(isA ? 'A' : 'B',
                style: TextStyle(color: spec.onAccent, fontWeight: FontWeight.w900, fontSize: 17)),
          ),
        ),
      ]);
    }
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          photo,
          const SizedBox(height: 6),
          _label(),
        ]),
      ),
    );
  }
}

/// Film sulla mappa: poster e titolo (anno).
///  - Metro: poster con bordo del colore della linea
///  - Bacheca: polaroid con puntina e titolo su nastro adesivo
///  - Cinema: fotogramma di pellicola con fori e titolo su biglietto
class MovieNode extends StatelessWidget {
  static const width = 150.0, posterW = 84.0, posterH = 126.0;
  final Movie movie;
  final StyleSpec spec;
  final Color color;
  final VoidCallback onTap;
  const MovieNode({super.key, required this.movie, required this.spec, required this.color, required this.onTap});

  double get _tilt => ((movie.id % 5) - 2) * .018;

  Widget _poster() {
    final img = NodeImage(url: movie.posterUrl, fallback: Icons.movie, color: spec.ink);
    switch (spec.label) {
      case 'Bacheca':
        return Transform.rotate(
          angle: _tilt,
          child: Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
            Container(
              width: posterW,
              height: posterH,
              padding: const EdgeInsets.fromLTRB(5, 5, 5, 16),
              decoration: BoxDecoration(color: _paper, borderRadius: BorderRadius.circular(2), boxShadow: _shadow),
              child: NodeImage(url: movie.posterUrl, fallback: Icons.movie, color: _paperInk),
            ),
            Positioned(top: -7, child: _Pin(spec.accent)),
          ]),
        );
      case 'Cinema':
        return Container(
          width: posterW,
          height: posterH,
          decoration: BoxDecoration(
            color: _film,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color, width: 2.5),
            boxShadow: _shadow,
          ),
          child: Row(children: [
            const _Sprockets(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ClipRRect(borderRadius: BorderRadius.circular(1), child: img),
              ),
            ),
            const _Sprockets(),
          ]),
        );
      default:
        return Container(
          width: posterW,
          height: posterH,
          decoration: BoxDecoration(
            color: spec.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 4),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
          ),
          child: ClipRRect(borderRadius: BorderRadius.circular(8), child: img),
        );
    }
  }

  Widget _label() {
    final onColor = ThemeData.estimateBrightnessForColor(color) == Brightness.dark ? Colors.white : Colors.black;
    final title = '${movie.title}${movie.year == null ? '' : ' (${movie.year})'}';
    Text text(Color c, {double spacing = 0}) => Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: c, fontSize: 14, height: 1.15, fontWeight: FontWeight.w700, letterSpacing: spacing),
        );
    return switch (spec.label) {
      'Bacheca' => Transform.rotate(
          angle: -_tilt,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _tape.withValues(alpha: .95),
              boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(1, 2))],
            ),
            child: text(_paperInk),
          ),
        ),
      'Cinema' => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.white.withValues(alpha: .35)),
          ),
          child: text(onColor, spacing: .3),
        ),
      _ => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
          child: text(onColor),
        ),
    };
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _poster(),
            const SizedBox(height: 6),
            _label(),
          ]),
        ),
      );
}

/// Scheda con immagine grande e nome completo, aperta toccando un nodo.
void showNodeDetail(
  BuildContext context, {
  required String title,
  String? subtitle,
  String? imageUrl,
  required bool round,
  required StyleSpec spec,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: spec.surface,
    showDragHandle: true,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: round ? 200 : 160,
            height: round ? 200 : 240,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(round ? 100 : spec.radius + 2),
              border: Border.all(color: spec.accent, width: 3),
            ),
            clipBehavior: Clip.antiAlias,
            child: NodeImage(url: imageUrl, fallback: round ? Icons.person : Icons.movie, color: spec.ink),
          ),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: spec.ink)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 16, color: spec.ink.withValues(alpha: .7))),
          ],
        ]),
      ),
    ),
  );
}
