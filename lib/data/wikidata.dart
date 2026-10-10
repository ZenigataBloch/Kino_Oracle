import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'data_source.dart';

/// Client Wikidata: nessuna chiave o account. Dati CC0, foto da Wikimedia Commons.
class Wikidata implements DataSource {
  static const _api = 'https://www.wikidata.org/w/api.php';
  // attore, attore cinematografico, attore televisivo, doppiatore
  static const _actorJobs = {'Q33999', 'Q10800557', 'Q10798782', 'Q2405480'};
  // film, lungometraggio, film d'animazione
  static const _filmClasses = {'Q11424', 'Q24869', 'Q202866'};

  final String lang;
  Wikidata(String locale) : lang = locale.split('-').first;

  final _movieCast = <int, Set<int>>{};
  final _personMovies = <int, Set<int>>{};

  Future<Map<String, dynamic>> _get(Map<String, String> q) async {
    final uri = Uri.parse(_api).replace(queryParameters: {'format': 'json', 'origin': '*', ...q});
    final r = await http.get(uri,
        headers: kIsWeb ? {} : {'User-Agent': 'KinoOracle/0.1 (https://github.com/ZenigataBloch/Kino_Oracle)'});
    if (r.statusCode != 200) throw Exception('Wikidata ${r.statusCode}');
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<List<String>> _search(String q) async {
    final j = await _get({
      'action': 'wbsearchentities', 'search': q, 'language': lang,
      'uselang': lang, 'type': 'item', 'limit': '12',
    });
    return [for (final r in j['search'] as List) r['id'] as String];
  }

  Future<Map<String, dynamic>> _entities(List<String> ids) async {
    if (ids.isEmpty) return {};
    final j = await _get({
      'action': 'wbgetentities', 'ids': ids.join('|'), 'props': 'labels|claims',
      'languages': '$lang|en', 'languagefallback': '1',
    });
    return (j['entities'] as Map).cast<String, dynamic>();
  }

  List<dynamic> _vals(Map e, String prop) {
    final c = (e['claims'] as Map?)?[prop] as List?;
    if (c == null) return const [];
    return [
      for (final x in c)
        if (x['mainsnak']?['datavalue'] != null) x['mainsnak']['datavalue']['value']
    ];
  }

  Set<String> _ids(Map e, String prop) =>
      {for (final v in _vals(e, prop)) if (v is Map) v['id'] as String};

  String _label(Map e) {
    final l = (e['labels'] as Map?) ?? {};
    final v = l[lang] ?? l['en'] ?? (l.isNotEmpty ? l.values.first : null);
    return (v?['value'] as String?) ?? '?';
  }

  int _num(String id) => int.parse(id.substring(1));

  @override
  Future<List<Person>> searchPeople(String q) async {
    final ids = await _search(q);
    final ents = await _entities(ids);
    final out = <Person>[];
    for (final id in ids) {
      final e = ents[id] as Map?;
      if (e == null || !_ids(e, 'P31').contains('Q5')) continue;
      if (_ids(e, 'P106').intersection(_actorJobs).isEmpty) continue;
      final photos = _vals(e, 'P18');
      final births = _vals(e, 'P569');
      String? birth;
      if (births.isNotEmpty && births.first is Map) {
        final t = births.first['time'] as String; // +1956-07-09T00:00:00Z
        if (t.startsWith('+') && t.length >= 11) birth = t.substring(1, 11);
      }
      out.add(Person(_num(id), _label(e), photos.isEmpty ? null : 'https://commons.wikimedia.org/wiki/Special:FilePath/${Uri.encodeComponent(photos.first as String)}?width=342', birth));
    }
    return out;
  }

  @override
  Future<Person?> randomPerson() async {
    final names = [...famousActors]..shuffle();
    for (final n in names.take(4)) {
      final r = await searchPeople(n);
      if (r.isNotEmpty) return r.first;
    }
    return null;
  }

  @override
  Future<List<Movie>> searchMovies(String q) async {
    final ids = await _search(q);
    final ents = await _entities(ids);
    final out = <Movie>[];
    for (final id in ids) {
      final e = ents[id] as Map?;
      if (e == null || _ids(e, 'P31').intersection(_filmClasses).isEmpty) continue;
      final dates = _vals(e, 'P577');
      String? year;
      if (dates.isNotEmpty && dates.first is Map) {
        final t = dates.first['time'] as String;
        if (t.startsWith('+') && t.length >= 5) year = t.substring(1, 5);
      }
      out.add(Movie(_num(id), _label(e), year));
    }
    return out;
  }

  /// Attori (P161 "cast member") di un film.
  @override
  Future<Set<int>> movieCastIds(int movieId) async {
    final cached = _movieCast[movieId];
    if (cached != null) return cached;
    final ents = await _entities(['Q$movieId']);
    final e = ents['Q$movieId'] as Map?;
    return _movieCast[movieId] = e == null ? <int>{} : _ids(e, 'P161').map(_num).toSet();
  }

  /// Film in cui compare un attore: ricerca inversa "haswbstatement:P161=Q...".
  @override
  Future<Set<int>> personMovieIds(int personId) async {
    final cached = _personMovies[personId];
    if (cached != null) return cached;
    final out = <int>{};
    var offset = 0;
    for (var i = 0; i < 4; i++) {
      final j = await _get({
        'action': 'query', 'list': 'search', 'srsearch': 'haswbstatement:P161=Q$personId',
        'srnamespace': '0', 'srlimit': '500', 'sroffset': '$offset', 'srprop': '',
      });
      for (final r in j['query']['search'] as List) {
        out.add(int.parse((r['title'] as String).substring(1)));
      }
      final next = (j['continue'] as Map?)?['sroffset'];
      if (next == null) break;
      offset = next as int;
    }
    return _personMovies[personId] = out;
  }
}
