import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'data_source.dart';

/// Client TMDB. Accetta sia il "Read Access Token" (v4, inizia con eyJ)
/// sia la "API Key" (v3), passati con --dart-define=TMDB_TOKEN=...
class Tmdb implements DataSource {
  static const _key = String.fromEnvironment('TMDB_TOKEN');
  static const _base = 'https://api.themoviedb.org/3';
  final String lang;
  Tmdb(this.lang);

  final _movieCast = <int, Set<int>>{};
  final _personMovies = <int, Set<int>>{};

  Future<Map<String, dynamic>> _get(String path, [Map<String, String> q = const {}]) async {
    final bearer = _key.startsWith('eyJ');
    final uri = Uri.parse('$_base$path').replace(queryParameters: {
      'language': lang,
      if (!bearer) 'api_key': _key,
      ...q,
    });
    final r = await http.get(uri, headers: bearer ? {'Authorization': 'Bearer $_key'} : {});
    if (r.statusCode != 200) throw Exception('TMDB ${r.statusCode}');
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  @override
  Future<List<Person>> searchPeople(String q) async {
    final j = await _get('/search/person', {'query': q});
    return [
      for (final p in j['results'] as List)
        if (p['known_for_department'] == 'Acting')
          Person(p['id'], p['name'],
              p['profile_path'] == null ? null : 'https://image.tmdb.org/t/p/w342${p['profile_path']}', null)
    ];
  }

  @override
  Future<List<Movie>> searchMovies(String q) async {
    final j = await _get('/search/movie', {'query': q});
    return [
      for (final m in j['results'] as List)
        Movie(m['id'], m['title'],
            ((m['release_date'] ?? '') as String).length >= 4 ? (m['release_date'] as String).substring(0, 4) : null)
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
          .map<int>((c) => c['id'] as int)
          .toSet();
}
