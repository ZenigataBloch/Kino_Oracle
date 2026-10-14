import 'dart:math';
import '../data/data_source.dart';
import '../models/models.dart';

/// Passaggio obbligato: un film (o una serie) oppure un attore da cui il collegamento deve passare.
class Waypoint {
  final Movie? movie;
  final Person? person;
  const Waypoint.movie(Movie this.movie) : person = null;
  const Waypoint.person(Person this.person) : movie = null;

  /// Chiave del nodo nel grafo di [BoardState] ('m123' / 'p123').
  String get key => movie != null ? 'm${movie!.id}' : 'p${person!.id}';
  String get kind => movie == null ? 'attore' : (movie!.isTv ? 'serie' : 'film');
  String get label => movie != null
      ? '${movie!.title}${movie!.year == null ? '' : ' (${movie!.year})'}'
      : person!.name;
}

/// Sceglie un passaggio garantendo che esista un percorso A - film - attore - film - B
/// che lo attraversa. Null se non ne trova uno entro un numero limitato di richieste.
Future<Waypoint?> pickWaypoint(DataSource data, Person a, Person b, {Random? rnd}) async {
  rnd ??= Random();
  final bMovies = await data.personMovieIds(b.id);
  final films = (await data.personMovieIds(a.id)).toList()..shuffle(rnd);
  var checked = 0;
  for (final w in films.take(12)) {
    final cast = await data.movieCastIds(w);
    if (cast.contains(b.id)) continue;
    // Il cast arriva in ordine di rilievo: si provano prima gli attori principali.
    for (final x in cast.where((x) => x != a.id && x != b.id).take(8)) {
      if (++checked > 40) return null;
      final fm = await data.personMovieIds(x);
      if (!fm.any(bMovies.contains)) continue;
      if (rnd.nextBool()) {
        final m = await data.movieById(w);
        if (m != null) return Waypoint.movie(m);
      } else {
        final p = await data.personById(x);
        if (p != null) return Waypoint.person(p);
      }
    }
  }
  return null;
}
