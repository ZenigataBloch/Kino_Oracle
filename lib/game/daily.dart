import 'package:shared_preferences/shared_preferences.dart';

/// Stato della sfida del giorno: completata oggi? serie di giorni consecutivi.
class Daily {
  static bool done = false;
  static int streak = 0;

  static String _day(DateTime d) {
    final u = d.toUtc();
    return '${u.year}-${u.month.toString().padLeft(2, '0')}-${u.day.toString().padLeft(2, '0')}';
  }

  static String get today => _day(DateTime.now());

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final last = p.getString('dailyDone');
    done = last == today;
    final alive = done || last == _day(DateTime.now().subtract(const Duration(days: 1)));
    streak = alive ? (p.getInt('dailyStreak') ?? 0) : 0;
  }

  /// Da chiamare quando la sfida di oggi è risolta (conta una sola volta al giorno).
  static Future<void> markSolved() async {
    final p = await SharedPreferences.getInstance();
    if (p.getString('dailyDone') == today) return;
    await load();
    final s = streak + 1;
    await p.setString('dailyDone', today);
    await p.setInt('dailyStreak', s);
    done = true;
    streak = s;
  }

  static String get label => done ? 'SFIDA DEL GIORNO ✓  serie $streak' : (streak > 0 ? 'SFIDA DEL GIORNO  serie $streak' : 'SFIDA DEL GIORNO');
}
