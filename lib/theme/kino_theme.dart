import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/data_source.dart';

enum KinoStyle { metro, investigation, cinema }

class StyleSpec {
  final String label;
  final Color bg, ink, accent;
  final List<Color> lines; // colori delle "linee" (un film = una linea)
  const StyleSpec(this.label, this.bg, this.ink, this.accent, this.lines);

  ThemeData get materialTheme {
    final b = ThemeData.estimateBrightnessForColor(bg);
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: b),
      textTheme: ThemeData(brightness: b).textTheme.apply(bodyColor: ink, displayColor: ink),
    );
  }
}

// TODO: oltre ai colori, ogni stile avrà un proprio painter (vedi ui/board_screen.dart).
const specs = {
  KinoStyle.metro: StyleSpec('Mappa della metropolitana', Color(0xFFF5F2EA),
      Color(0xFF1B1B1B), Color(0xFFE3120B), [
    Color(0xFFE3120B), Color(0xFF0072CE), Color(0xFF00A650),
    Color(0xFFF7A800), Color(0xFF8E3B9E), Color(0xFF00A5B5),
  ]),
  KinoStyle.investigation: StyleSpec("Bacheca d'indagine", Color(0xFF3B2F26),
      Color(0xFFF1E6D0), Color(0xFFC62828), [Color(0xFFC62828)]),
  KinoStyle.cinema: StyleSpec("Cinema anni '50", Color(0xFFF3E3C3),
      Color(0xFF3A1E1E), Color(0xFF9C1C1C), [
    Color(0xFF9C1C1C), Color(0xFF1F4E5F), Color(0xFFB8860B),
  ]),
};

class AppSettings extends ChangeNotifier {
  KinoStyle style = KinoStyle.metro;
  bool noSeries = false;
  String lang = 'it-IT';
  SourceId source = hasTmdbKey ? SourceId.tmdb : SourceId.wikidata;
  StyleSpec get spec => specs[style]!;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    style = KinoStyle.values.firstWhere((s) => s.name == p.getString('style'),
        orElse: () => KinoStyle.metro);
    noSeries = p.getBool('noSeries') ?? false;
    lang = p.getString('lang') ?? 'it-IT';
    source = SourceId.values.firstWhere((s) => s.name == p.getString('source'), orElse: () => source);
  }

  Future<void> update({KinoStyle? style, bool? noSeries, String? lang, SourceId? source}) async {
    this.style = style ?? this.style;
    this.noSeries = noSeries ?? this.noSeries;
    this.lang = lang ?? this.lang;
    this.source = source ?? this.source;
    final p = await SharedPreferences.getInstance();
    await p.setString('style', this.style.name);
    await p.setBool('noSeries', this.noSeries);
    await p.setString('lang', this.lang);
    await p.setString('source', this.source.name);
    notifyListeners();
  }
}
