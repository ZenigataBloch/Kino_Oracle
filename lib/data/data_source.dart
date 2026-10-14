import 'dart:math';
import '../models/models.dart';
import 'tmdb.dart';

/// Interfaccia comune: il gioco non sa da dove arrivano i dati.
abstract class DataSource {
  Future<List<Person>> searchPeople(String q);
  Future<List<Movie>> searchMovies(String q);
  Future<Set<int>> movieCastIds(int movieId);
  Future<Set<int>> personMovieIds(int personId);

  /// Dettagli di un film/serie o di una persona a partire dall'id (percorso obbligato).
  Future<Movie?> movieById(int id);
  Future<Person?> personById(int id);

  /// Id della collezione/saga di un film (null se non ne fa parte o non disponibile).
  Future<int?> movieCollectionId(int movieId) async => null;

  /// Un attore a caso per "Scegli per me" (null se non ne trova uno).
  /// Con [rnd] con seme fisso la scelta è ripetibile (sfida giornaliera).
  Future<Person?> randomPerson({Random? rnd});
}

DataSource makeSource(String locale, String token) => Tmdb(locale, token);
