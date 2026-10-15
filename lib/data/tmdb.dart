import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'data_source.dart';
import 'filters.dart';

/// Client TMDB. Accetta sia il "Read Access Token" (v4, inizia con eyJ)
/// sia la "API Key" (v3). La chiave arriva dalle Impostazioni dell'app.
class Tmdb implements DataSource {
  static const _base = 'https://api.themoviedb.org/3';
  final String lang;
  final String _key;

  /// Lingue originali dei film da escludere (vedi regions.dart).
  final Set<String> excludedLanguages;

  /// 'movie', 'tv' o 'both'.
  final String mediaMode;

  /// Filtri per genere (id TMDB) e decennio (es. 1990); vuoti = nessun filtro.
  final Set<int> genres, decades;
  Tmdb(this.lang, this._key,
      {this.excludedLanguages = const {},
      this.mediaMode = 'movie',
      this.genres = const {},
      this.decades = const {}});

  bool get _useMovies => mediaMode != 'tv';
  bool get _useTv => mediaMode != 'movie';

  final _movieCast = <int, Set<int>>{};
  final _personMovies = <int, Set<int>>{};

  bool _movieOk(dynamic m, {bool tv = false}) =>
      !excludedLanguages.contains(m['original_language']) &&
      passesFilters(m, tv: tv, genres: genres, decades: decades);

  /// Serie valide: niente talk show e notiziari (l'attore vi compare solo come ospite).
  bool _tvOk(dynamic m) {
    final g = (m['genre_ids'] as List?) ?? const [];
    return _movieOk(m, tv: true) && !g.contains(10767) && !g.contains(10763);
  }

  /// Esclude una persona se più della metà dei titoli per cui è nota è in lingue escluse.
  bool _personOk(dynamic p) {
    if (excludedLanguages.isEmpty) return true;
    final known = (p['known_for'] as List?) ?? const [];
    if (known.isEmpty) return true;
    final bad = known.where((k) => excludedLanguages.contains(k['original_language'])).length;
    return bad * 2 <= known.length;
  }

  Future<Map<String, dynamic>> _get(String path, [Map<String, String> q = const {}]) async {
    final bearer = _key.startsWith('eyJ');
    final uri = Uri.parse('$_base$path').replace(queryParameters: {
      'language': lang,
      if (!bearer) 'api_key': _key,
      ...q,
    });
    final r = await http.get(uri, headers: bearer ? {'Authorization': 'Bearer $_key'} : {});
    if (r.statusCode == 401) throw Exception('Chiave TMDB non valida (401)');
    if (r.statusCode != 200) throw Exception('TMDB ${r.statusCode}');
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Person _toPerson(dynamic p) => Person(p['id'], p['name'],
      p['profile_path'] == null ? null : 'https://image.tmdb.org/t/p/w342${p['profile_path']}', null);

  @override
  Future<List<Person>> searchPeople(String q) async {
    final j = await _get('/search/person', {'query': q});
    return [
      for (final p in j['results'] as List)
        if (p['known_for_department'] == 'Acting' && _personOk(p)) _toPerson(p)
    ];
  }

  /// Un attore a caso tra i più popolari (25 pagine da 20 = circa 500 persone).
  /// Se il filtro svuota la pagina, riprova su un'altra.
  @override
  Future<Person?> randomPerson({Random? rnd}) async {
    rnd ??= Random();
    for (var attempt = 0; attempt < 4; attempt++) {
      final j = await _get('/person/popular', {'page': '${1 + rnd.nextInt(25)}'});
      final actors = [
        for (final p in j['results'] as List)
          if (p['known_for_department'] == 'Acting' && _personOk(p)) p
      ];
      if (actors.isNotEmpty) return _toPerson(actors[rnd.nextInt(actors.length)]);
    }
    return null;
  }

  @override
  Future<List<Movie>> searchMovies(String q) async {
    String? yr(dynamic d) => ((d ?? '') as String).length >= 4 ? (d as String).substring(0, 4) : null;
    String? poster(dynamic m) =>
        m['poster_path'] == null ? null : 'https://image.tmdb.org/t/p/w342${m['poster_path']}';
    final films = <Movie>[], series = <Movie>[];
    if (_useMovies) {
      final j = await _get('/search/movie', {'query': q});
      for (final m in j['results'] as List) {
        if (_movieOk(m)) films.add(Movie(m['id'], m['title'], yr(m['release_date']), poster(m)));
      }
    }
    if (_useTv) {
      final j = await _get('/search/tv', {'query': q});
      for (final m in j['results'] as List) {
        if (_tvOk(m)) {
          series.add(Movie(Movie.tvOffset + (m['id'] as int), m['name'], yr(m['first_air_date']), poster(m), 'tv'));
        }
      }
    }
    // Con "Entrambi" si alternano film e serie: i chiamanti prendono solo i primi 4-5 risultati
    // e le serie, messe in coda, non venivano mai trovate.
    final out = <Movie>[];
    for (var i = 0; i < films.length || i < series.length; i++) {
      if (i < films.length) out.add(films[i]);
      if (i < series.length) out.add(series[i]);
    }
    return out;
  }

  @override
  Future<Set<int>> movieCastIds(int movieId) async {
    if (movieId >= Movie.tvOffset) {
      return _movieCast[movieId] ??=
          ((await _get('/tv/${movieId - Movie.tvOffset}/aggregate_credits'))['cast'] as List)
              .map<int>((c) => c['id'] as int)
              .toSet();
    }
    return _movieCast[movieId] ??= ((await _get('/movie/$movieId/credits'))['cast'] as List)
        .map<int>((c) => c['id'] as int)
        .toSet();
  }

  @override
  Future<Set<int>> personMovieIds(int personId) async {
    if (_personMovies[personId] != null) return _personMovies[personId]!;
    final ids = <int>{};
    if (_useMovies) {
      for (final c in (await _get('/person/$personId/movie_credits'))['cast'] as List) {
        if (_movieOk(c)) ids.add(c['id'] as int);
      }
    }
    if (_useTv) {
      for (final c in (await _get('/person/$personId/tv_credits'))['cast'] as List) {
        if (_tvOk(c)) ids.add(Movie.tvOffset + (c['id'] as int));
      }
    }
    return _personMovies[personId] = ids;
  }

  @override
  Future<Movie?> movieById(int id) async {
    final tv = id >= Movie.tvOffset;
    final m = await _get(tv ? '/tv/${id - Movie.tvOffset}' : '/movie/$id');
    final d = ((tv ? m['first_air_date'] : m['release_date']) ?? '') as String;
    return Movie(id, (tv ? m['name'] : m['title']) as String, d.length >= 4 ? d.substring(0, 4) : null,
        m['poster_path'] == null ? null : 'https://image.tmdb.org/t/p/w342${m['poster_path']}', tv ? 'tv' : 'movie');
  }

  final _collections = <int, int?>{};

  @override
  Future<int?> movieCollectionId(int movieId) async {
    if (_collections.containsKey(movieId)) return _collections[movieId];
    final m = await _get('/movie/$movieId');
    return _collections[movieId] = (m['belongs_to_collection'] as Map?)?['id'] as int?;
  }

  @override
  Future<Person?> personById(int id) async => _toPerson(await _get('/person/$id'));
}
