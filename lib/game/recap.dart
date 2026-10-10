import 'dart:math';
import '../models/models.dart';
import 'board_state.dart';

/// Riepilogo a partita finita: statistiche e punteggio con il dettaglio dei punti.
///
/// Punti = base + stelle + bonus velocità - penalità per le mosse oltre il minimo.
class Recap {
  static const base = 500; // collegamento completato
  static const perStar = 200; // per ogni stella (max 3)
  static const timeBudget = 300; // 1 punto per ogni secondo risparmiato sui 5 minuti
  static const perExtraMove = 25; // penalità per ogni mossa oltre il minimo

  final int stars, moves, actors, movies, seconds, extra;
  final int basePts, starPts, timePts, penaltyPts;

  const Recap({
    required this.stars,
    required this.moves,
    required this.actors,
    required this.movies,
    required this.seconds,
    required this.extra,
    required this.basePts,
    required this.starPts,
    required this.timePts,
    required this.penaltyPts,
  });

  int get total => max(0, basePts + starPts + timePts - penaltyPts);

  factory Recap.of(BoardState s) {
    final secs = s.elapsed.inSeconds;
    final st = s.stars;
    final ex = s.extraMoves;
    return Recap(
      stars: st,
      moves: s.moves,
      actors: s.people.length,
      movies: s.movies.length,
      seconds: secs,
      extra: ex,
      basePts: base,
      starPts: st * perStar,
      timePts: max(0, timeBudget - secs),
      penaltyPts: ex * perExtraMove,
    );
  }
}

/// Chiave di una coppia di attori, indipendente dall'ordine e dalla fonte dati.
String pairKey(String a, String b) {
  final l = [a.toLowerCase(), b.toLowerCase()]..sort();
  return l.join('|');
}

/// Suggerimento per la prossima partita: due attori incontrati sul tavolo.
class PairingHint {
  final Person x, y;
  final int films; // film che li separano sul tavolo
  const PairingHint(this.x, this.y, this.films);
}

/// Sceglie, tra gli attori presenti sul tavolo, la coppia più lontana (almeno 2 film)
/// che non sia la coppia appena giocata né una già giocata (`played`).
/// Sul tavolo gli attori sono collegati solo tramite film: le distanze tra attori
/// sono sempre pari (attore-film-attore = 2 archi), quindi i film sono dist / 2.
PairingHint? suggestPairing(BoardState s, Set<String> played) {
  PairingHint? best;
  final list = s.people.values.toList();
  for (var i = 0; i < list.length; i++) {
    final d = s.distancesFrom('p${list[i].id}');
    for (var j = i + 1; j < list.length; j++) {
      final x = list[i], y = list[j];
      final isCurrent = (x.id == s.a.id && y.id == s.b.id) || (x.id == s.b.id && y.id == s.a.id);
      if (isCurrent || played.contains(pairKey(x.name, y.name))) continue;
      final dist = d['p${y.id}'];
      if (dist == null || dist < 4) continue;
      final films = dist ~/ 2;
      if (best == null || films > best.films) best = PairingHint(x, y, films);
    }
  }
  return best;
}
