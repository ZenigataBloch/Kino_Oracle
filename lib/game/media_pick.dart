import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

/// Scelta di inizio partita: 'movie' (film), 'tv' (serie TV) o 'both' (entrambi).
/// Se mai scelta dalla home, vale il valore delle Impostazioni.
class MediaPick {
  static String? _v;
  static const _k = 'mediaPick';

  static String get mode => _v ?? settings.mediaMode;

  static Future<void> load() async => _v = (await SharedPreferences.getInstance()).getString(_k);

  static Future<void> set(String v) async {
    _v = v;
    await (await SharedPreferences.getInstance()).setString(_k, v);
  }
}
