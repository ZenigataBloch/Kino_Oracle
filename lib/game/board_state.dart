import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../data/data_source.dart';
import '../models/models.dart';
import 'solver.dart';

class MapLayout {
  final Map<String, Offset> pos;
  final Size size;
  const MapLayout(this.pos, this.size);
}

class BoardState extends ChangeNotifier {
  BoardState(this.a, this.b, this.data) {
    people[a.id] = a;
    people[b.id] = b;
    _solve();
  }
  final Person a, b;
  final DataSource data;
  final people = <int, Person>{};
  final movies = <int, Movie>{};
  final links = <(int, int)>{}; // (personId, movieId)
  bool busy = false, solved = false;
  String? message;

  // Percorso minimo: 1 o 3; null = almeno 5; 0 = non disponibile
  int? optimal;
  bool optimalReady = false;
  bool _closed = false;

  int get moves => people.length + movies.length - 2;

  Future<void> _solve() async {
    final r = await Solver.shortest(data, a.id, b.id, () => _closed);
    if (_closed) return;
    optimal = r;
    optimalReady = true;
    notifyListeners();
  }

  /// Giudizio finale con stelle, da mostrare a partita risolta.
  String get verdict {
    if (!optimalReady) return 'Collegati in $moves mosse! (calcolo il percorso minimo…)';
    final o = optimal;
    if (o == 0) return 'Collegati in $moves mosse!';
    final int stars;
    final String note;
    if (o == null) {
      stars = moves <= 5 ? 3 : (moves <= 7 ? 2 : 1);
      note = 'Il percorso minimo e di almeno 5 mosse.';
    } else {
      final diff = moves - o;
      stars = diff <= 0 ? 3 : (diff <= 2 ? 2 : 1);
      note = 'Il percorso minimo era di $o ${o == 1 ? 'mossa' : 'mosse'}.';
    }
    final title = ['', 'Ci sei arrivato!', 'Ottimo!', 'Percorso perfetto!'][stars];
    return '${'★' * stars}${'☆' * (3 - stars)}  $title $moves mosse. $note';
  }

  @override
  void dispose() {
    _closed = true;
    super.dispose();
  }

  // ---- Aggiunta di film e attori -------------------------------------------

  Future<void> addPersonEntity(Person p) => _run(() async {
        if (people.containsKey(p.id)) {
          message = '${p.name} e gia sul tavolo';
          return;
        }
        if (!await _linkPerson(p)) message = '${p.name} non ha recitato in nessun film sul tavolo';
      });

  Future<void> addMovieEntity(Movie m) => _run(() async {
        if (movies.containsKey(m.id)) {
          message = '${m.title} e gia sul tavolo';
          return;
        }
        if (!await _linkMovie(m)) message = 'Nessuno degli attori sul tavolo ha recitato in "${m.title}"';
      });

  /// Testo libero: prova prima come film, poi come attore.
  Future<void> addByText(String query) => _run(() async {
        for (final m in (await data.searchMovies(query)).take(5)) {
          if (!movies.containsKey(m.id) && await _linkMovie(m)) return;
        }
        for (final p in (await data.searchPeople(query)).take(5)) {
          if (!people.containsKey(p.id) && await _linkPerson(p)) return;
        }
        message = '"$query" non corrisponde a nessun film o attore collegato al tavolo';
      });

  Future<bool> _linkMovie(Movie m) async {
    final cast = await data.movieCastIds(m.id);
    final hits = people.keys.where(cast.contains).toList();
    if (hits.isEmpty) return false;
    movies[m.id] = m;
    for (final p in hits) {
      links.add((p, m.id));
    }
    return true;
  }

  Future<bool> _linkPerson(Person p) async {
    final filmo = await data.personMovieIds(p.id);
    final hits = movies.keys.where(filmo.contains).toList();
    if (hits.isEmpty) return false;
    people[p.id] = p;
    for (final m in hits) {
      links.add((p.id, m));
    }
    return true;
  }

  Future<void> _run(Future<void> Function() f) async {
    busy = true;
    message = null;
    notifyListeners();
    try {
      await f();
    } catch (e) {
      message = 'Errore di rete: $e';
    }
    solved = _bfs('p${a.id}').containsKey('p${b.id}');
    busy = false;
    notifyListeners();
  }

  // ---- Grafo e layout ---------------------------------------------------------

  Map<String, Set<String>> get _adj {
    final g = <String, Set<String>>{};
    for (final (p, m) in links) {
      (g['p$p'] ??= {}).add('m$m');
      (g['m$m'] ??= {}).add('p$p');
    }
    return g;
  }

  Map<String, int> _bfs(String start) {
    final g = _adj;
    final d = <String, int>{start: 0};
    final q = <String>[start];
    while (q.isNotEmpty) {
      final n = q.removeAt(0);
      for (final x in g[n] ?? const <String>{}) {
        if (!d.containsKey(x)) {
          d[x] = d[n]! + 1;
          q.add(x);
        }
      }
    }
    return d;
  }

  /// Colonne per distanza: il gruppo di A cresce da sinistra, quello di B da destra,
  /// finche non si incontrano. Le righe sono ordinate col baricentro dei vicini.
  MapLayout layout() {
    const colGap = 290.0, rowGap = 110.0, padX = 150.0, padY = 90.0;
    final g = _adj;
    final dA = _bfs('p${a.id}'), dB = _bfs('p${b.id}');
    final joined = dA.containsKey('p${b.id}');
    final maxA = dA.values.fold<int>(0, (p, e) => max(p, e));
    final maxB = joined ? 0 : dB.values.fold<int>(0, (p, e) => max(p, e));
    final k = maxA + maxB + 2;
    final all = [for (final p in people.keys) 'p$p', for (final m in movies.keys) 'm$m'];
    final col = {
      for (final n in all) n: dA[n] ?? (joined || !dB.containsKey(n) ? 0 : k - dB[n]!)
    };
    final byCol = <int, List<String>>{};
    for (final n in all) {
      (byCol[col[n]!] ??= []).add(n);
    }
    final cols = byCol.keys.toList()..sort();
    final row = <String, double>{};
    var maxRows = 1;
    for (final c in cols) {
      final nodes = byCol[c]!;
      double key(String n) {
        final ys = [for (final nb in g[n] ?? const <String>{}) if (row.containsKey(nb)) row[nb]!];
        return ys.isEmpty ? 1e9 + all.indexOf(n) : ys.reduce((x, y) => x + y) / ys.length;
      }
      nodes.sort((x, y) => key(x).compareTo(key(y)));
      for (var i = 0; i < nodes.length; i++) {
        row[nodes[i]] = i - (nodes.length - 1) / 2;
      }
      maxRows = max(maxRows, nodes.length);
    }
    final midY = padY + (maxRows - 1) / 2 * rowGap;
    final pos = {for (final n in all) n: Offset(padX + col[n]! * colGap, midY + row[n]! * rowGap)};
    final lastCol = cols.isEmpty ? 0 : cols.last;
    return MapLayout(pos, Size(2 * padX + lastCol * colGap, 2 * padY + (maxRows - 1) * rowGap));
  }
}
