import '../data/data_source.dart';

/// Calcola il numero minimo di mosse (film + attori aggiunti) tra due attori,
/// fino a 3 mosse: A -film- B  (1)  oppure  A -film- X -film- B  (3).
/// Ritorna: 1 o 3; null se il minimo e' 5 o piu; 0 se il calcolo non e' riuscito.
class Solver {
  static const _maxMovies = 150; // limite per attore, per contenere le richieste

  static Future<int?> shortest(DataSource d, int a, int b, bool Function() cancelled) async {
    try {
      final fa = (await d.personMovieIds(a)).take(_maxMovies).toSet();
      final fb = (await d.personMovieIds(b)).take(_maxMovies).toSet();
      if (fa.intersection(fb).isNotEmpty) return 1;
      final castA = await _cast(d, fa, cancelled);
      final castB = await _cast(d, fb, cancelled);
      if (cancelled()) return 0;
      castA..remove(a)..remove(b);
      return castA.intersection(castB).isNotEmpty ? 3 : null;
    } catch (_) {
      return 0;
    }
  }

  static Future<Set<int>> _cast(DataSource d, Set<int> movies, bool Function() cancelled) async {
    final out = <int>{};
    final ids = movies.toList();
    for (var i = 0; i < ids.length; i += 8) {
      if (cancelled()) return out;
      final r = await Future.wait(
          ids.skip(i).take(8).map((m) => d.movieCastIds(m).catchError((_) => <int>{})));
      for (final s in r) {
        out.addAll(s);
      }
    }
    return out;
  }
}
