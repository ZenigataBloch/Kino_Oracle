import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../data/data_source.dart';
import '../models/models.dart';
import 'saga_rule.dart';
import 'waypoint.dart';
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
  bool daily = false; // partita della sfida giornaliera

  // Duello a turni (2 giocatori sullo stesso telefono): dopo ogni mossa valida il turno passa;
  // vince chi chiude il collegamento.
  bool duel = false;
  int turn = 0; // 0 = Giocatore 1, 1 = Giocatore 2
  int? winner;

  String? get duelNote => duel && winner == null ? 'Turno del Giocatore ${turn + 1}' : null;

  // Percorso obbligato: la vittoria vale solo se il collegamento A-B passa da [must].
  Waypoint? must;

  String? get mustNote => must == null ? null : 'Devi passare da ${must!.kind}: ${must!.label}';

  bool get _mustOk {
    final k = must?.key;
    return k == null || (_bfs('p${a.id}').containsKey(k) && _bfs('p${b.id}').containsKey(k));
  }

  // Limite di mosse: si può collegare con al massimo "percorso minimo + extraAllowed" mosse.
  // Senza minimo noto (in calcolo, non disponibile o "almeno 5") non c'è limite.
  int? extraAllowed;
  bool outOfMoves = false;

  int? get maxMoves {
    final e = extraAllowed, o = optimal;
    if (e == null || !optimalReady || o == null || o == 0) return null;
    return o + e;
  }

  /// Mosse rimaste; null se non c'è limite.
  int? get movesLeft {
    final m = maxMoves;
    return m == null ? null : max(0, m - moves);
  }

  /// Partita persa per tempo o per mosse esaurite.
  bool get lost => timedOut || outOfMoves;

  void _checkLimit() {
    final m = maxMoves;
    if (solved || outOfMoves || m == null || moves < m) return;
    outOfMoves = true;
    finishedAt ??= DateTime.now();
    message = 'Mosse finite!';
  }

  // Modalità a tempo: se timeLimit è impostato, allo scadere la partita finisce (persa).
  Duration? timeLimit;
  bool timedOut = false;
  Timer? _timer;

  /// Tempo rimasto; null se la partita non è a tempo.
  Duration? get timeLeft {
    final l = timeLimit;
    if (l == null) return null;
    final r = l - elapsed;
    return r.isNegative ? Duration.zero : r;
  }

  /// Avvia il conto alla rovescia (da chiamare subito dopo la creazione).
  void startTimer(Duration limit) {
    timeLimit = limit;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (solved || timedOut || _closed) {
        _timer?.cancel();
        return;
      }
      if (elapsed >= limit) {
        timedOut = true;
        finishedAt ??= DateTime.now();
        message = 'Tempo scaduto!';
        _timer?.cancel();
      }
      notifyListeners();
    });
  }
  String? message;

  // Percorso minimo: 1 o 3; null = almeno 5; 0 = non disponibile
  int? optimal;
  bool optimalReady = false;
  bool _closed = false;

  // Tempo di gioco: parte alla creazione, si ferma al collegamento.
  final DateTime startedAt = DateTime.now();
  DateTime? finishedAt;
  Duration get elapsed => (finishedAt ?? DateTime.now()).difference(startedAt);

  int get moves => people.length + movies.length - 2;

  /// Distanze (in archi del grafo) da un nodo, es. 'p123'. Usato per i suggerimenti.
  Map<String, int> distancesFrom(String start) => _bfs(start);

  Future<void> _solve() async {
    final r = await Solver.shortest(data, a.id, b.id, () => _closed);
    if (_closed) return;
    optimal = r;
    optimalReady = true;
    _checkLimit();
    notifyListeners();
  }

  /// Stelle da 1 a 3; 0 se il percorso minimo non e noto (ancora in calcolo o non disponibile).
  int get stars {
    if (!optimalReady) return 0;
    final o = optimal;
    if (o == 0) return 0;
    if (o == null) return moves <= 5 ? 3 : (moves <= 7 ? 2 : 1);
    final diff = moves - o;
    return diff <= 0 ? 3 : (diff <= 2 ? 2 : 1);
  }

  /// Mosse oltre il minimo; 0 se il minimo non e noto.
  int get extraMoves {
    final o = optimal;
    if (!optimalReady || o == 0) return 0;
    return max(0, moves - (o ?? 5));
  }

  /// Nota sul percorso minimo; null se non e (ancora) noto.
  String? get minNote {
    if (!optimalReady) return null;
    final o = optimal;
    if (o == 0) return null;
    if (o == null) return 'Il percorso minimo è di almeno 5 mosse.';
    return 'Il percorso minimo era di $o ${o == 1 ? 'mossa' : 'mosse'}.';
  }

  /// Giudizio finale con stelle, da mostrare a partita risolta.
  String get verdict {
    if (duel && winner != null) return 'Vince il Giocatore ${winner! + 1}! Collegati in $moves mosse.';
    if (!optimalReady) return 'Collegati in $moves mosse! (calcolo il percorso minimo…)';
    final st = stars;
    if (st == 0) return 'Collegati in $moves mosse!';
    final title = ['', 'Ci sei arrivato!', 'Ottimo!', 'Percorso perfetto!'][st];
    return '${'★' * st}${'☆' * (3 - st)}  $title $moves mosse. $minNote';
  }

  @override
  void dispose() {
    _closed = true;
    _timer?.cancel();
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
        final clash = await SagaRule.conflict(data, m, movies.values);
        if (clash != null) {
          message = clash;
          return;
        }
        if (!await _linkMovie(m)) message = 'Nessuno degli attori sul tavolo ha recitato in "${m.title}"';
      });

  /// Testo libero: prova prima come film, poi come attore.
  Future<void> addByText(String query) => _run(() async {
        for (final m in (await data.searchMovies(query)).take(5)) {
          if (!movies.containsKey(m.id) &&
              await SagaRule.conflict(data, m, movies.values) == null &&
              await _linkMovie(m)) return;
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
    if (timedOut || outOfMoves) return;
    final before = moves;
    busy = true;
    message = null;
    notifyListeners();
    try {
      await f();
    } catch (e) {
      message = 'Errore di rete: $e';
    }
    final connected = _bfs('p${a.id}').containsKey('p${b.id}');
    solved = !timedOut && connected && _mustOk;
    if (duel) {
      if (solved) {
        winner = turn;
      } else if (moves > before) {
        turn = 1 - turn;
      }
    }
    if (connected && !solved && !timedOut) message ??= 'Collegati, ma manca il passaggio obbligato: ${must!.label}';
    if (solved) finishedAt ??= DateTime.now();
    _checkLimit();
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
  ///
  /// vertical = true (telefoni): i livelli scendono dall'alto (A) al basso (B) e i nodi dello
  /// stesso livello sono affiancati, con piu spazio perche le etichette non si sovrappongano.
  MapLayout layout({bool vertical = false}) {
    final colGap = vertical ? 280.0 : 300.0; // distanza tra livelli
    const rowGap = 200.0; // distanza tra nodi dello stesso livello
    final padLvl = vertical ? 140.0 : 150.0; // margine lungo i livelli
    final padSide = vertical ? 110.0 : 130.0; // margine sull'altro asse
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
    final mid = padSide + (maxRows - 1) / 2 * rowGap;
    Offset at(String n) {
      final lvl = padLvl + col[n]! * colGap, side = mid + row[n]! * rowGap;
      return vertical ? Offset(side, lvl) : Offset(lvl, side);
    }
    final pos = {for (final n in all) n: at(n)};
    final lastCol = cols.isEmpty ? 0 : cols.last;
    final lvlSize = 2 * padLvl + lastCol * colGap, sideSize = 2 * padSide + (maxRows - 1) * rowGap;
    return MapLayout(pos, vertical ? Size(sideSize, lvlSize) : Size(lvlSize, sideSize));
  }
}
