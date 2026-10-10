import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/kino_theme.dart';

/// Immagine di rete con segnaposto mentre carica o se manca. Va messa in uno spazio di dimensione fissa.
class NodeImage extends StatelessWidget {
  final String? url;
  final IconData fallback;
  final Color color;
  const NodeImage({super.key, required this.url, required this.fallback, required this.color});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, box) {
        final ph = ColoredBox(
          color: color.withOpacity(.08),
          child: Center(child: Icon(fallback, size: box.biggest.shortestSide * .5, color: color.withOpacity(.35))),
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

/// Attore sulla mappa: foto tonda con nome. A e B sono piu grandi e hanno il badge;
/// gli scambi (2+ film) hanno il doppio anello.
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

  @override
  Widget build(BuildContext context) {
    final strong = isA || isB || hub;
    Widget photo = Container(
      width: _d,
      height: _d,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: spec.bg,
        border: Border.all(color: spec.ink, width: strong ? 5 : 3.5),
      ),
      child: ClipOval(child: NodeImage(url: person.photoUrl, fallback: Icons.person, color: spec.ink)),
    );
    if (hub) {
      photo = Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: spec.ink, width: 2)),
        child: photo,
      );
    }
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
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: spec.bg.withOpacity(.94),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: spec.ink.withOpacity(.3)),
            ),
            child: Text(
              person.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: spec.ink,
                fontSize: 15,
                height: 1.15,
                fontWeight: (isA || isB) ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Film sulla mappa: poster con bordo del colore della sua linea e titolo (anno).
class MovieNode extends StatelessWidget {
  static const width = 150.0, posterW = 84.0, posterH = 126.0;
  final Movie movie;
  final StyleSpec spec;
  final Color color;
  final VoidCallback onTap;
  const MovieNode({super.key, required this.movie, required this.spec, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final onColor = ThemeData.estimateBrightnessForColor(color) == Brightness.dark ? Colors.white : Colors.black;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: posterW,
            height: posterH,
            decoration: BoxDecoration(
              color: spec.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color, width: 4),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: NodeImage(url: movie.posterUrl, fallback: Icons.movie, color: spec.ink),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
            child: Text(
              '${movie.title}${movie.year == null ? '' : ' (${movie.year})'}',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: onColor, fontSize: 14, height: 1.15, fontWeight: FontWeight.w700),
            ),
          ),
        ]),
      ),
    );
  }
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
    backgroundColor: spec.bg,
    showDragHandle: true,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: round ? 200 : 160,
            height: round ? 200 : 240,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(round ? 100 : 16),
              child: NodeImage(url: imageUrl, fallback: round ? Icons.person : Icons.movie, color: spec.ink),
            ),
          ),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: spec.ink)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 16, color: spec.ink.withOpacity(.7))),
          ],
        ]),
      ),
    ),
  );
}
