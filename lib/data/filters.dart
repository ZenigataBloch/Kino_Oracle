/// Filtri per genere e decennio (si applicano a ricerca e crediti, come le cinematografie).

const kGenres = <int, String>{
  28: 'Azione',
  12: 'Avventura',
  16: 'Animazione',
  35: 'Commedia',
  80: 'Crime',
  99: 'Documentario',
  18: 'Drammatico',
  10751: 'Famiglia',
  14: 'Fantasy',
  27: 'Horror',
  9648: 'Mistero',
  10749: 'Romantico',
  878: 'Fantascienza',
  53: 'Thriller',
  10752: 'Guerra',
  37: 'Western',
};

const kDecades = [1930, 1940, 1950, 1960, 1970, 1980, 1990, 2000, 2010, 2020];

/// Vero se il titolo [item] (risposta TMDB di film o serie) rispetta i filtri.
/// Filtri vuoti = nessuna restrizione; più generi o decenni si combinano in OR, i due gruppi in AND.
bool passesFilters(dynamic item, {required bool tv, required Set<int> genres, required Set<int> decades}) {
  if (genres.isNotEmpty) {
    // Le serie usano alcuni generi accorpati (Action & Adventure, Sci-Fi & Fantasy, War & Politics).
    final wanted = {...genres};
    if (tv) {
      if (genres.contains(28) || genres.contains(12)) wanted.add(10759);
      if (genres.contains(878) || genres.contains(14)) wanted.add(10765);
      if (genres.contains(10752)) wanted.add(10768);
    }
    final ids = ((item['genre_ids'] as List?) ?? const []).map((e) => e as int);
    if (!ids.any(wanted.contains)) return false;
  }
  if (decades.isNotEmpty) {
    final d = ((tv ? item['first_air_date'] : item['release_date']) ?? '') as String;
    final y = d.length >= 4 ? int.tryParse(d.substring(0, 4)) : null;
    if (y == null || !decades.contains(y ~/ 10 * 10)) return false;
  }
  return true;
}
