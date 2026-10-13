import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/regions.dart';

enum KinoStyle { metro, investigation, cinema }

/// Aspetto: indipendente dallo stile grafico. AMOLED = scuro con nero puro.
enum Appearance { system, light, dark, amoled }

class StyleSpec {
  final String label;
  final Color bg, ink, accent;
  final List<Color> lines; // colori delle "linee" (un film = una linea)
  final bool amoled;
  const StyleSpec(this.label, this.bg, this.ink, this.accent, this.lines, {this.amoled = false});

  StyleSpec toAmoled() => StyleSpec(label, Colors.black, ink, accent, lines, amoled: true);

  ThemeData get materialTheme {
    final b = ThemeData.estimateBrightnessForColor(bg);
    var scheme = ColorScheme.fromSeed(seedColor: accent, brightness: b);
    if (amoled) scheme = scheme.copyWith(surface: Colors.black);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      iconTheme: IconThemeData(color: ink),
      appBarTheme: AppBarTheme(backgroundColor: bg, foregroundColor: ink, surfaceTintColor: Colors.transparent),
      textTheme: ThemeData(brightness: b).textTheme.apply(bodyColor: ink, displayColor: ink),
    );
  }
}

/// Uno stile ha una palette chiara e una scura.
class StyleDef {
  final String label;
  final StyleSpec light, dark;
  const StyleDef(this.label, this.light, this.dark);
}

// TODO: oltre ai colori, bacheca e cinema avranno un painter proprio (ui/metro_painter.dart).
const specs = {
  KinoStyle.metro: StyleDef(
    'Mappa della metropolitana',
    StyleSpec('Metro', Color(0xFFF5F2EA), Color(0xFF1B1B1B), Color(0xFFE3120B), [
      Color(0xFFE3120B), Color(0xFF0072CE), Color(0xFF00A650),
      Color(0xFFF7A800), Color(0xFF8E3B9E), Color(0xFF00A5B5),
    ]),
    StyleSpec('Metro', Color(0xFF14161A), Color(0xFFECECEC), Color(0xFFFF5A4F), [
      Color(0xFFFF5A4F), Color(0xFF3D9BFF), Color(0xFF2FCB7B),
      Color(0xFFFFB830), Color(0xFFC07AD6), Color(0xFF2CC7D6),
    ]),
  ),
  KinoStyle.investigation: StyleDef(
    "Bacheca d'indagine",
    StyleSpec('Bacheca', Color(0xFFE8D8BB), Color(0xFF2B2118), Color(0xFFB71C1C), [Color(0xFFB71C1C)]),
    StyleSpec('Bacheca', Color(0xFF2A211B), Color(0xFFE8DCC4), Color(0xFFE5484D), [Color(0xFFE5484D)]),
  ),
  KinoStyle.cinema: StyleDef(
    "Cinema anni '50",
    StyleSpec('Cinema', Color(0xFFF3E3C3), Color(0xFF3A1E1E), Color(0xFF9C1C1C), [
      Color(0xFF9C1C1C), Color(0xFF1F4E5F), Color(0xFFB8860B),
    ]),
    StyleSpec('Cinema', Color(0xFF1C1410), Color(0xFFF0E0C0), Color(0xFFE0584F), [
      Color(0xFFE0584F), Color(0xFF4FA3B8), Color(0xFFE0B040),
    ]),
  ),
};

class AppSettings extends ChangeNotifier {
  KinoStyle style = KinoStyle.metro;
  Appearance appearance = Appearance.system;
  bool noSeries = false;

  /// Cosa si può collegare: 'movie' (film), 'tv' (serie) o 'both'.
  String mediaMode = 'movie';

  /// Modalità a tempo: minuti a disposizione, 0 = disattivata.
  int timeLimit = 0;

  /// Limite di mosse: extra sul percorso minimo (N), -1 = nessun limite.
  int moveLimit = -1;

  /// Percorso obbligato: la partita assegna un film/attore da cui passare.
  bool mustPass = false;

  /// Filtri: id dei generi TMDB e decenni (es. 1990) ammessi; vuoti = nessun filtro.
  Set<int> genreFilter = {}, decadeFilter = {};
  String lang = 'it-IT';

  /// Nomi delle [Region] escluse (es. 'southAsia', 'eastAsia').
  Set<String> excludedRegions = {};

  /// Codici lingua originali da escludere, derivati dalle regioni scelte.
  Set<String> get excludedLanguages => {
        for (final r in Region.values)
          if (excludedRegions.contains(r.name)) ...r.languages
      };

  /// Chiave TMDB inserita nelle Impostazioni (salvata sul telefono).
  String tmdbToken = '';
  static const _buildKey = String.fromEnvironment('TMDB_TOKEN');

  /// Chiave in uso: quella delle Impostazioni, altrimenti quella di --dart-define.
  String get tmdbKey => tmdbToken.isNotEmpty ? tmdbToken : _buildKey;
  bool get hasKey => tmdbKey.isNotEmpty;

  /// Palette effettiva: stile + aspetto (+ tema del sistema se "Sistema").
  StyleSpec get spec {
    final def = specs[style]!;
    final dark = switch (appearance) {
      Appearance.light => false,
      Appearance.system => PlatformDispatcher.instance.platformBrightness == Brightness.dark,
      _ => true,
    };
    if (!dark) return def.light;
    return appearance == Appearance.amoled ? def.dark.toAmoled() : def.dark;
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    style = KinoStyle.values.firstWhere((s) => s.name == p.getString('style'), orElse: () => KinoStyle.metro);
    appearance = Appearance.values.firstWhere((a) => a.name == p.getString('appearance'), orElse: () => Appearance.system);
    noSeries = p.getBool('noSeries') ?? false;
    mediaMode = p.getString('mediaMode') ?? 'movie';
    timeLimit = p.getInt('timeLimit') ?? 0;
    moveLimit = p.getInt('moveLimit') ?? -1;
    mustPass = p.getBool('mustPass') ?? false;
    genreFilter = {for (final x in p.getStringList('genreFilter') ?? const <String>[]) int.parse(x)};
    decadeFilter = {for (final x in p.getStringList('decadeFilter') ?? const <String>[]) int.parse(x)};
    lang = p.getString('lang') ?? 'it-IT';
    tmdbToken = p.getString('tmdbToken') ?? '';
    excludedRegions = (p.getStringList('excludedRegions') ?? const <String>[]).toSet();
  }

  Future<void> update({
    KinoStyle? style,
    Appearance? appearance,
    bool? noSeries,
    String? mediaMode,
    int? timeLimit,
    int? moveLimit,
    bool? mustPass,
    Set<int>? genreFilter,
    Set<int>? decadeFilter,
    String? lang,
    String? tmdbToken,
    Set<String>? excludedRegions,
  }) async {
    this.style = style ?? this.style;
    this.appearance = appearance ?? this.appearance;
    this.noSeries = noSeries ?? this.noSeries;
    this.mediaMode = mediaMode ?? this.mediaMode;
    this.timeLimit = timeLimit ?? this.timeLimit;
    this.moveLimit = moveLimit ?? this.moveLimit;
    this.mustPass = mustPass ?? this.mustPass;
    this.genreFilter = genreFilter ?? this.genreFilter;
    this.decadeFilter = decadeFilter ?? this.decadeFilter;
    this.lang = lang ?? this.lang;
    this.tmdbToken = tmdbToken ?? this.tmdbToken;
    this.excludedRegions = excludedRegions ?? this.excludedRegions;
    final p = await SharedPreferences.getInstance();
    await p.setString('style', this.style.name);
    await p.setString('appearance', this.appearance.name);
    await p.setBool('noSeries', this.noSeries);
    await p.setString('mediaMode', this.mediaMode);
    await p.setInt('timeLimit', this.timeLimit);
    await p.setInt('moveLimit', this.moveLimit);
    await p.setBool('mustPass', this.mustPass);
    await p.setStringList('genreFilter', [for (final x in this.genreFilter) '$x']);
    await p.setStringList('decadeFilter', [for (final x in this.decadeFilter) '$x']);
    await p.setString('lang', this.lang);
    await p.setString('tmdbToken', this.tmdbToken);
    await p.setStringList('excludedRegions', this.excludedRegions.toList());
    notifyListeners();
  }
}
