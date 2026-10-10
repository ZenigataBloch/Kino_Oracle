import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'board_state.dart';
import 'recap.dart';

/// Una partita conclusa, come viene salvata nel log.
class GameRecord {
  final DateTime date;
  final String a, b;
  final int moves, stars, points, seconds;

  const GameRecord({
    required this.date,
    required this.a,
    required this.b,
    required this.moves,
    required this.stars,
    required this.points,
    required this.seconds,
  });

  factory GameRecord.of(BoardState s) {
    final r = Recap.of(s);
    return GameRecord(
      date: DateTime.now(),
      a: s.a.name,
      b: s.b.name,
      moves: s.moves,
      stars: r.stars,
      points: r.total,
      seconds: r.seconds,
    );
  }

  Map<String, dynamic> toJson() =>
      {'d': date.toIso8601String(), 'a': a, 'b': b, 'm': moves, 's': stars, 'p': points, 't': seconds};

  factory GameRecord.fromJson(Map<String, dynamic> j) => GameRecord(
        date: DateTime.tryParse(j['d'] as String? ?? '') ?? DateTime.now(),
        a: j['a'] as String? ?? '?',
        b: j['b'] as String? ?? '?',
        moves: (j['m'] as num?)?.toInt() ?? 0,
        stars: (j['s'] as num?)?.toInt() ?? 0,
        points: (j['p'] as num?)?.toInt() ?? 0,
        seconds: (j['t'] as num?)?.toInt() ?? 0,
      );
}

/// Registro delle partite precedenti (SharedPreferences: funziona su Windows, Android e web).
/// Quando arriva la partita successiva alla [maxGames]-esima il registro si svuota
/// e riparte da quella.
class GameLog {
  static const maxGames = 25;
  static const _key = 'game_log';

  static Future<List<GameRecord>> load() async {
    final p = await SharedPreferences.getInstance();
    final out = <GameRecord>[];
    for (final s in p.getStringList(_key) ?? const <String>[]) {
      try {
        out.add(GameRecord.fromJson(jsonDecode(s) as Map<String, dynamic>));
      } catch (_) {
        // voce rovinata: la salto
      }
    }
    return out;
  }

  static Future<void> add(GameRecord r) async {
    final p = await SharedPreferences.getInstance();
    var list = p.getStringList(_key) ?? <String>[];
    if (list.length >= maxGames) list = <String>[];
    list = [...list, jsonEncode(r.toJson())];
    await p.setStringList(_key, list);
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }

  /// Coppie già giocate (per non suggerirle di nuovo).
  static Future<Set<String>> playedPairs() async => {for (final r in await load()) pairKey(r.a, r.b)};
}
