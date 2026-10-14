import 'package:shared_preferences/shared_preferences.dart';
import '../data/data_source.dart';
import '../models/models.dart';

/// Filtro "niente film della stessa saga": sul tavolo non possono stare due film
/// della stessa collezione TMDB (es. due capitoli di Il Signore degli Anelli).
class SagaRule {
  static bool enabled = false;
  static const _k = 'noSameSaga';

  static Future<void> load() async =>
      enabled = (await SharedPreferences.getInstance()).getBool(_k) ?? false;

  static Future<void> set(bool v) async {
    enabled = v;
    await (await SharedPreferences.getInstance()).setBool(_k, v);
  }

  /// Messaggio di rifiuto se [m] è della stessa saga di un film già sul tavolo, altrimenti null.
  static Future<String?> conflict(DataSource data, Movie m, Iterable<Movie> onTable) async {
    if (!enabled || m.isTv) return null;
    final c = await data.movieCollectionId(m.id);
    if (c == null) return null;
    for (final o in onTable) {
      if (!o.isTv && await data.movieCollectionId(o.id) == c) {
        return '"${m.title}" è della stessa saga di "${o.title}"';
      }
    }
    return null;
  }
}
