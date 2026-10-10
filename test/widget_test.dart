import 'package:flutter_test/flutter_test.dart';
import 'package:kino_oracle/game/game_log.dart';
import 'package:kino_oracle/game/recap.dart';
import 'package:kino_oracle/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

GameRecord _rec(int i) => GameRecord(
      date: DateTime(2026, 1, 1),
      a: 'A$i',
      b: 'B$i',
      moves: 3,
      stars: 3,
      points: 1000 + i,
      seconds: 30,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('il log si svuota quando arriva la partita successiva alla 25-esima', () async {
    for (var i = 0; i < GameLog.maxGames; i++) {
      await GameLog.add(_rec(i));
    }
    expect((await GameLog.load()).length, GameLog.maxGames);

    await GameLog.add(_rec(99));
    final after = await GameLog.load();
    expect(after.length, 1);
    expect(after.single.a, 'A99');
  });

  test('clear() azzera il log', () async {
    await GameLog.add(_rec(1));
    await GameLog.clear();
    expect(await GameLog.load(), isEmpty);
  });

  test('la chiave della coppia non dipende da ordine e maiuscole', () {
    expect(pairKey('Tom Hanks', 'Meryl Streep'), pairKey('meryl streep', 'TOM HANKS'));
  });

  test('i punti della partita si sommano come da recap', () {
    const r = Recap(
      stars: 3,
      moves: 3,
      actors: 3,
      movies: 2,
      seconds: 60,
      extra: 0,
      basePts: Recap.base,
      starPts: 3 * Recap.perStar,
      timePts: Recap.timeBudget - 60,
      penaltyPts: 0,
    );
    expect(r.total, 500 + 600 + 240);
  });

  testWidgets('la home si avvia', (tester) async {
    await settings.load();
    await tester.pumpWidget(const KinoApp());
    expect(find.text('KINO ORACLE'), findsOneWidget);
    expect(find.text('GIOCA'), findsOneWidget);
  });
}
