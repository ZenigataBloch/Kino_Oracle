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
}

/// True se l'app e' stata avviata con --dart-define=TMDB_TOKEN=...
const hasTmdbKey = String.fromEnvironment('TMDB_TOKEN') != '';

DataSource makeSource(SourceId id, String locale) =>
    id == SourceId.tmdb && hasTmdbKey ? Tmdb(locale) : Wikidata(locale);
