import '../models/models.dart';
import 'tmdb.dart';
import 'wikidata.dart';

enum SourceId { tmdb, wikidata }

/// Interfaccia comune: il gioco non sa da dove arrivano i dati.
abstract class DataSource {
  Future<List<Person>> searchPeople(String q);
  Future<List<Movie>> searchMovies(String q);
  Future<Set<int>> movieCastIds(int movieId);
  Future<Set<int>> personMovieIds(int personId);

  /// Un attore a caso per "Scegli per me" (null se non ne trova uno).
  Future<Person?> randomPerson();
}

/// Nomi tra cui sceglie "Scegli per me" quando la fonte non ha una classifica di popolarità.
const famousActors = [
  'Tom Hanks', 'Meryl Streep', 'Denzel Washington', 'Al Pacino', 'Scarlett Johansson',
  'Brad Pitt', 'Cate Blanchett', 'Robert De Niro', 'Julia Roberts', 'Leonardo DiCaprio',
  'Sophia Loren', 'Marcello Mastroianni', 'Toni Servillo', 'Monica Bellucci', 'Kevin Bacon',
  'Morgan Freeman', 'Jack Nicholson', 'Anthony Hopkins', 'Harrison Ford', 'Samuel L. Jackson',
  'Nicole Kidman', 'Sandra Bullock', 'Angelina Jolie', 'Johnny Depp', 'Keanu Reeves',
  'Matt Damon', 'Ben Affleck', 'George Clooney', 'Christian Bale', 'Natalie Portman',
  'Emma Stone', 'Ryan Gosling', 'Margot Robbie', 'Joaquin Phoenix', 'Jennifer Lawrence',
  'Anne Hathaway', 'Hugh Jackman', 'Tom Cruise', 'Bruce Willis', 'Sylvester Stallone',
  'Arnold Schwarzenegger', 'Clint Eastwood', 'Dustin Hoffman', 'Robin Williams', 'Michael Caine',
  'Ian McKellen', 'Judi Dench', 'Helen Mirren', 'Kate Winslet', 'Emma Thompson',
  'Colin Firth', 'Ralph Fiennes', 'Daniel Day-Lewis', 'Gary Oldman', 'Tilda Swinton',
  'Charlize Theron', 'Halle Berry', 'Will Smith', 'Eddie Murphy', 'Jim Carrey',
  'Adam Sandler', 'Ben Stiller', 'Owen Wilson', 'Bill Murray', 'Steve Carell',
  'Jake Gyllenhaal', 'Mark Wahlberg', 'Christoph Waltz', 'Javier Bardem', 'Penélope Cruz',
  'Antonio Banderas', 'Gael García Bernal', 'Marion Cotillard', 'Juliette Binoche', 'Jean Reno',
  'Catherine Deneuve', 'Gérard Depardieu', 'Audrey Tautou', 'Vincent Cassel', 'Léa Seydoux',
  'Isabella Rossellini', 'Roberto Benigni', 'Alberto Sordi', 'Totò', 'Vittorio Gassman',
  'Anna Magnani', 'Gina Lollobrigida', 'Claudia Cardinale', 'Giancarlo Giannini', 'Silvio Orlando',
  'Pierfrancesco Favino', 'Elio Germano', 'Valeria Golino', 'Kim Rossi Stuart', 'Alba Rohrwacher',
  'Toshiro Mifune', 'Ken Watanabe', 'Song Kang-ho', 'Michelle Yeoh', 'Jackie Chan',
  'Audrey Hepburn', 'Marilyn Monroe', 'Humphrey Bogart', 'Cary Grant', 'Marlon Brando',
];

/// True se l'app e' stata avviata con --dart-define=TMDB_TOKEN=...
const hasTmdbKey = String.fromEnvironment('TMDB_TOKEN') != '';

DataSource makeSource(SourceId id, String locale) =>
    id == SourceId.tmdb && hasTmdbKey ? Tmdb(locale) : Wikidata(locale);
