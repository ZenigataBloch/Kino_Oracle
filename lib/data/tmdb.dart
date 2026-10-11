import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'data_source.dart';

/// Client TMDB. Accetta sia il "Read Access Token" (v4, inizia con eyJ)
/// sia la "API Key" (v3). La chiave arriva dalle Impostazioni dell'app.
class Tmdb implements DataSource {
  static const _base = 'https://api.themoviedb.org/3';
  final String lang;
  final String _key;

  /// Lingue originali dei film da escludere (vedi regions.dart).
  final Set<String> excludedLanguages;
  Tmdb(this.lang, this._key, {this.excludedLanguages = const {}});

  final _movieCast = <int, Set<int>>{};
  final _personMovies = <int, Set<int>>{};

  bool _movieOk(dynamic m) => !excludedLanguages.contains(m['original_language']);

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
  Future<Person?> randomPerson() async {
    final rnd = Random();
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
    final j = await _get('/search/movie', {'query': q});
    return [
      for (final m in j['results'] as List)
        if (_movieOk(m))
          Movie(m['id'], m['title'],
              ((m['release_date'] ?? '') as String).length >= 4 ? (m['release_date'] as String).substring(0, 4) : null,
              m['poster_path'] == null ? null : 'https://image.tmdb.org/t/p/w342${m['poster_path']}')
    ];
  }

  @override
  Future<Set<int>> movieCastIds(int movieId) async =>
      _movieCast[movieId] ??= ((await _get('/movie/$movieId/credits'))['cast'] as List)
          .map<int>((c) => c['id'] as int)
          .toSet();

  @override
  Future<Set<int>> personMovieIds(int personId) async =>
      _personMovies[personId] ??= ((await _get('/person/$personId/movie_credits'))['cast'] as List)
          .where(_movieOk)
          .map<int>((c) => c['id'] as int)
          .toSet();
}
