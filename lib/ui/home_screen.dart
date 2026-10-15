import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/data_source.dart';
import '../data/tmdb.dart';
import '../game/board_state.dart';
import '../game/daily.dart';
import '../game/media_pick.dart';
import '../game/waypoint.dart';
import '../main.dart';
import '../models/models.dart';
import '../theme/kino_look.dart';
import '../theme/kino_theme.dart';
import '../update/updater.dart';
import 'board_screen.dart';
import 'history_screen.dart';
import 'mode_sheet.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DataSource data = _makeData();
  String _dataSig = _signature();
  final picks = <Person?>[null, null];
  final _keys = [UniqueKey(), UniqueKey()];

  /// Firma delle impostazioni che influenzano i dati: se cambia, si ricrea la sorgente.
  static String _signature() {
    final langs = settings.excludedLanguages.toList()..sort();
    return '${settings.lang}|${settings.tmdbKey}|${langs.join(',')}|${MediaPick.mode}|${(settings.genreFilter.toList()..sort()).join(',')}|${(settings.decadeFilter.toList()..sort()).join(',')}';
  }

  DataSource _makeData() =>
      Tmdb(settings.lang, settings.tmdbKey,
          excludedLanguages: settings.excludedLanguages,
          mediaMode: MediaPick.mode,
          genres: settings.genreFilter,
          decades: settings.decadeFilter);

  /// Ricrea la sorgente solo se lingua, chiave o filtri sono cambiati (cosi la cache resta).
  void _syncData() {
    final sig = _signature();
    if (sig == _dataSig) return;
    _dataSig = sig;
    data = _makeData();
  }

  @override
  void initState() {
    super.initState();
    Daily.load().then((_) {
      if (mounted) setState(() {});
    });
    // Su Android propone di scaricare l'APK se su GitHub c'e una versione piu nuova.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Updater.check(context);
    });
  }

  /// Azzera i due attori scelti (e i relativi campi di testo).
  void _reset() => setState(() {
        picks[0] = null;
        picks[1] = null;
        _keys[0] = UniqueKey();
        _keys[1] = UniqueKey();
      });

  void _swap() => setState(() {
        final t = picks[0];
        picks[0] = picks[1];
        picks[1] = t;
        _keys[0] = UniqueKey();
        _keys[1] = UniqueKey();
      });

  Future<void> _random(int i) async {
    final other = picks[1 - i];
    try {
      for (var k = 0; k < 4; k++) {
        final p = await data.randomPerson();
        if (p == null || p.id == other?.id) continue;
        if (!mounted) return;
        setState(() {
          picks[i] = p;
          _keys[i] = UniqueKey();
        });
        return;
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('401')
          ? 'Chiave TMDB non valida: controllala nelle Impostazioni'
          : 'Errore di rete, riprova';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  /// Quando si torna da una partita ("Nuova partita") i valori precedenti si azzerano.
  Future<void> _play({bool daily = false, bool duel = false, DataSource? src}) async {
    final data = src ?? this.data;
    Waypoint? must;
    if (settings.mustPass) {
      final wasBusy = _dailyBusy;
      setState(() => _dailyBusy = true);
      try {
        final n = DateTime.now().toUtc();
        must = await pickWaypoint(data, picks[0]!, picks[1]!,
            rnd: daily ? Random(n.year * 10000 + n.month * 100 + n.day + 1) : null);
      } catch (_) {}
      if (mounted) setState(() => _dailyBusy = wasBusy);
      if (!mounted) return;
      if (must == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nessun passaggio obbligato trovato: riprova o cambia coppia')),
        );
        return;
      }
      final w = must;
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Percorso obbligato'),
          content: Text('Devi passare da ${w.kind}: ${w.label}'),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
        ),
      );
      if (!mounted) return;
    }
    final game = BoardState(picks[0]!, picks[1]!, data)
      ..daily = daily
      ..duel = duel
      ..must = must;
    // Nel duello niente limiti di mosse o di tempo: contano i turni.
    if (!duel && settings.moveLimit >= 0) game.extraAllowed = settings.moveLimit;
    if (!duel && settings.timeLimit > 0) game.startTimer(Duration(minutes: settings.timeLimit));
    final done = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(builder: (_) => BoardScreen(game)),
    );
    if (daily && game.solved) {
      await Daily.markSolved();
      if (mounted) setState(() {});
    }
    // Partita finita (anche se si esce con "indietro") o "Nuova partita": scelta azzerata.
    if ((done == true || game.solved) && mounted) _reset();
  }

  // ---- Sfida giornaliera: stessa coppia per tutti, seme = data (UTC) ----------
  bool _dailyBusy = false;

  /// GIOCA: sceglie la modalità e avvia la partita.
  Future<void> _openModes() async {
    final m = await showModeSheet(context);
    if (!mounted || m == null) return;
    _syncData(); // le opzioni scelte nel pannello (es. Film/Serie TV) cambiano la sorgente dati
    if (m == 'classic') {
      await _play();
    } else if (m == 'duel') {
      await _play(duel: true);
    } else if (m == 'daily') {
      await _daily();
    }
  }

  static String get _today => Daily.today;

  Future<void> _daily() async {
    setState(() => _dailyBusy = true);
    // Coppia uguale per tutti: sorgente standard (solo film, nessun filtro).
    final std = Tmdb(settings.lang, settings.tmdbKey);
    try {
      final now = DateTime.now().toUtc();
      final prefs = await SharedPreferences.getInstance();
      List<Person>? pair;
      final raw = prefs.getString('dailyPair');
      if (prefs.getString('dailyDate') == _today && raw != null) {
        pair = [for (final j in jsonDecode(raw) as List) Person(j['id'], j['name'], j['photo'], null)];
      }
      if (pair == null) {
        final rnd = Random(now.year * 10000 + now.month * 100 + now.day);
        final a = await std.randomPerson(rnd: rnd);
        Person? b;
        for (var k = 0; k < 8 && b == null; k++) {
          final c = await std.randomPerson(rnd: rnd);
          if (c != null && c.id != a?.id) b = c;
        }
        if (a == null || b == null) throw Exception('nessun attore');
        pair = [a, b];
        await prefs.setString('dailyDate', _today);
        await prefs.setString('dailyPair', jsonEncode([for (final p in pair) {'id': p.id, 'name': p.name, 'photo': p.photoUrl}]));
      }
      if (!mounted) return;
      final fixed = pair;
      setState(() {
        picks[0] = fixed[0];
        picks[1] = fixed[1];
        _keys[0] = UniqueKey();
        _keys[1] = UniqueKey();
      });
      await _play(daily: true, src: std);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sfida non disponibile, riprova')));
      }
    } finally {
      if (mounted) setState(() => _dailyBusy = false);
    }
  }

  // Si ricostruisce quando cambiano le impostazioni (anche la chiave TMDB).
  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: settings, builder: (_, __) => _page(context));

  Widget _page(BuildContext context) {
    final spec = settings.spec;
    _syncData();
    final ready = settings.hasKey && picks[0] != null && picks[1] != null && picks[0]!.id != picks[1]!.id;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: spec.bg,
        actions: [
          IconButton(
            tooltip: 'Partite precedenti',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
          ),
          IconButton(
            tooltip: 'Impostazioni',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.movie_filter_rounded, size: 40, color: spec.accent),
              const SizedBox(width: 12),
              Text('KINO ORACLE',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: spec.accent)),
            ]),
            const SizedBox(height: 8),
            Text(
              'Scegli due attori e collegali attraverso i film',
              textAlign: TextAlign.center,
              style: TextStyle(color: spec.ink.withValues(alpha: .75)),
            ),
            if (!settings.hasKey) _keyBanner(spec),
            const SizedBox(height: 32),
            Wrap(spacing: 24, runSpacing: 24, alignment: WrapAlignment.center, children: [
              for (var i = 0; i < 2; i++) _slot(i),
            ]),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: picks[0] != null || picks[1] != null ? _swap : null,
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Scambia gli attori'),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 320,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 26)),
                onPressed: ready && !_dailyBusy ? _openModes : null,
                icon: const Icon(Icons.play_arrow_rounded, size: 38),
                label: const Text('GIOCA', style: TextStyle(fontSize: 26, letterSpacing: 4, fontWeight: FontWeight.w900)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  /// Senza chiave TMDB non si puo giocare: rimanda alle Impostazioni.
  Widget _keyBanner(StyleSpec spec) => Container(
        constraints: const BoxConstraints(maxWidth: 420),
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: spec.accent.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(spec.radius),
          border: Border.all(color: spec.accent.withValues(alpha: .4)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Per giocare serve una chiave TMDB (gratuita).', textAlign: TextAlign.center),
          const SizedBox(height: 10),
          FilledButton.tonal(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            child: const Text('Apri le impostazioni'),
          ),
        ]),
      );

  Widget _slot(int i) {
    final p = picks[i];
    final spec = settings.spec;
    return SizedBox(
      width: 260,
      child: Column(children: [
        // Riquadro dell'attore: bordo e ombra con l'accento quando e stato scelto.
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 240,
          decoration: BoxDecoration(
            color: spec.surface,
            border: Border.all(color: p != null ? spec.accent : spec.ink.withValues(alpha: .5), width: 3),
            borderRadius: BorderRadius.circular(spec.radius),
            boxShadow: p != null
                ? [BoxShadow(color: spec.accent.withValues(alpha: .25), blurRadius: 16, offset: const Offset(0, 6))]
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(fit: StackFit.expand, children: [
            if (p?.photoUrl != null)
              Image.network(
                p!.photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Center(child: Icon(Icons.person, size: 80, color: spec.ink.withValues(alpha: .3))),
              )
            else
              Center(child: Icon(Icons.person, size: 80, color: spec.ink.withValues(alpha: .3))),
            if (p != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  color: Colors.black.withValues(alpha: .6),
                  child: Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 8),
        Autocomplete<Person>(
          key: _keys[i],
          initialValue: TextEditingValue(text: p?.name ?? ''),
          displayStringForOption: (o) => o.name,
          optionsBuilder: (v) async => !settings.hasKey || v.text.length < 2 ? const <Person>[] : (await data.searchPeople(v.text)).take(6),
          onSelected: (o) => setState(() => picks[i] = o),
          fieldViewBuilder: (_, ctl, focus, submit) => TextField(
            controller: ctl,
            focusNode: focus,
            decoration: InputDecoration(labelText: 'Attore ${i + 1}'),
          ),
        ),
        TextButton(onPressed: settings.hasKey ? () => _random(i) : null, child: const Text('Scegli per me')),
      ]),
    );
  }
}
