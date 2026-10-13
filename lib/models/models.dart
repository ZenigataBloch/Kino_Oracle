class Person {
  final int id;
  final String name;
  final String? photoUrl; // URL completo della foto
  final String? birthday; // AAAA-MM-GG, se disponibile
  const Person(this.id, this.name, this.photoUrl, this.birthday);
}

class Movie {
  final int id;
  final String title;
  final String? year;
  final String? posterUrl; // URL completo del poster
  final String mediaType; // 'movie' o 'tv'
  const Movie(this.id, this.title, this.year, [this.posterUrl, this.mediaType = 'movie']);

  /// Gli id delle serie TV sono spostati di [tvOffset] per non scontrarsi con quelli dei film.
  static const tvOffset = 1000000000;
  bool get isTv => mediaType == 'tv';
  int get tmdbId => isTv ? id - tvOffset : id;
}
