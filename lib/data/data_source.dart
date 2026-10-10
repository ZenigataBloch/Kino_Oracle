import '../models/models.dart';
import 'tmdb.dart';

/// Interfaccia comune: il gioco non sa da dove arrivano i dati.
abstract class DataSource {
  Future<List<Person>> searchPeople(String q);
  Future<List<Movie>> searchMovies(String q);
  Future<Set<int>> movieCastIds(int movieId);
  Future<Set<int>> personMovieIds(int personId);

  /// Un attore a caso per "Scegli per me" (null se non ne trova uno).
  Future<Person?> randomPerson();
}

DataSource makeSource(String locale, String token) => Tmdb(locale, token);
