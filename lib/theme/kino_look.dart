import 'package:flutter/material.dart';
import 'kino_theme.dart';

/// Look completo di uno stile: angoli, superfici e tema Material con tutti i componenti
/// (bottoni, campi di testo, card, dialog, switch...) coerenti con la palette.
extension KinoLook on StyleSpec {
  /// Raggio degli angoli: ogni stile ha il suo carattere.
  double get radius => switch (label) {
        'Bacheca' => 4, // carta e cartoncino: angoli quasi vivi
        'Cinema' => 8,
        _ => 14, // Metro: morbido e moderno
      };

  /// Superficie leggermente staccata dallo sfondo (card, campi, dialog).
  Color get surface => Color.alphaBlend(ink.withValues(alpha: .06), bg);

  /// Colore del testo/icone sopra l'accento, scelto per il contrasto.
  Color get onAccent =>
      ThemeData.estimateBrightnessForColor(accent) == Brightness.dark ? Colors.white : Colors.black;

  ThemeData get theme {
    final b = ThemeData.estimateBrightnessForColor(bg);
    final br = BorderRadius.circular(radius);
    final shape = RoundedRectangleBorder(borderRadius: br);
    final outline = ink.withValues(alpha: .35);

    final scheme = ColorScheme.fromSeed(seedColor: accent, brightness: b).copyWith(
      primary: accent,
      onPrimary: onAccent,
      surface: bg,
      onSurface: ink,
      outline: outline,
      surfaceContainerHighest: surface,
    );

    final base = ThemeData(brightness: b).textTheme.apply(bodyColor: ink, displayColor: ink);
    final text = base.copyWith(
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: .5),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );

    WidgetStateProperty<Color?> pick(Color on, Color off) =>
        WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? on : off);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      iconTheme: IconThemeData(color: ink),
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(color: ink, fontSize: 22),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: shape,
          minimumSize: const Size(0, 48),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(shape: shape, side: BorderSide(color: outline), minimumSize: const Size(0, 48)),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(shape: shape)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(borderRadius: br, borderSide: BorderSide(color: outline)),
        enabledBorder: OutlineInputBorder(borderRadius: br, borderSide: BorderSide(color: outline)),
        focusedBorder: OutlineInputBorder(borderRadius: br, borderSide: BorderSide(color: accent, width: 2)),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: br, side: BorderSide(color: ink.withValues(alpha: .15))),
      ),
      dialogTheme: DialogThemeData(backgroundColor: surface, surfaceTintColor: Colors.transparent, shape: shape),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: TextStyle(color: bg),
        shape: shape,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(radius + 6))),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: pick(onAccent, ink.withValues(alpha: .6)),
        trackColor: pick(accent, ink.withValues(alpha: .15)),
        trackOutlineColor: pick(Colors.transparent, outline),
      ),
      radioTheme: RadioThemeData(fillColor: pick(accent, ink.withValues(alpha: .6))),
      dividerTheme: DividerThemeData(color: ink.withValues(alpha: .12), space: 1),
      listTileTheme: ListTileThemeData(iconColor: ink, textColor: ink),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: accent,
          selectedForegroundColor: onAccent,
          foregroundColor: ink,
          shape: shape,
          side: BorderSide(color: outline),
        ),
      ),
    );
  }
}
