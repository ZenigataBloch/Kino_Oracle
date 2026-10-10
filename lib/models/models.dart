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
  const Movie(this.id, this.title, this.year, [this.posterUrl]);
}
