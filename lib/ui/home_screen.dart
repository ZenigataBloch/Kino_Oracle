import 'dart:math';
import 'package:flutter/material.dart';
import '../data/data_source.dart';
import '../game/board_state.dart';
import '../main.dart';
import '../models/models.dart';
import 'board_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

const _famous = ['Tom Hanks', 'Meryl Streep', 'Denzel Washington', 'Al Pacino', 'Scarlett Johansson',
  'Brad Pitt', 'Cate Blanchett', 'Robert De Niro', 'Julia Roberts', 'Leonardo DiCaprio',
  'Sophia Loren', 'Marcello Mastroianni', 'Toni Servillo', 'Monica Bellucci', 'Kevin Bacon'];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DataSource data = makeSource(settings.source, settings.lang);
  final picks = <Person?>[null, null];
  final _keys = [UniqueKey(), UniqueKey()];

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
        final r = await data.searchPeople(_famous[Random().nextInt(_famous.length)]);
        if (r.isEmpty || r.first.id == other?.id) continue;
        if (!mounted) return;
        setState(() {
          picks[i] = r.first;
          _keys[i] = UniqueKey();
        });
        return;
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Errore di rete, riprova')));
    }
  }

  /// Quando si torna da una partita ("Nuova partita") i valori precedenti si azzerano.
  Future<void> _play() async {
    final game = BoardState(picks[0]!, picks[1]!, data);
    final done = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(builder: (_) => BoardScreen(game)),
    );
    // Partita finita (anche se si esce con "indietro") o "Nuova partita": scelta azzerata.
    if ((done == true || game.solved) && mounted) _reset();
  }

  @override
  Widget build(BuildContext context) {
    final spec = settings.spec;
    data = makeSource(settings.source, settings.lang);
    final ready = picks[0] != null && picks[1] != null && picks[0]!.id != picks[1]!.id;
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
            const Text('Scegli due attori e collegali attraverso i film'),
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
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16)),
              onPressed: ready ? _play : null,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('GIOCA', style: TextStyle(fontSize: 16, letterSpacing: 2, fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _slot(int i) {
    final p = picks[i];
    final spec = settings.spec;
    return SizedBox(
      width: 260,
      child: Column(children: [
        Container(
          height: 240,
          decoration: BoxDecoration(
            border: Border.all(color: spec.ink, width: 3),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(fit: StackFit.expand, children: [
            if (p?.photoUrl != null)
              Image.network(
                p!.photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(child: Icon(Icons.person, size: 80, color: spec.ink.withOpacity(.3))),
              )
            else
              Center(child: Icon(Icons.person, size: 80, color: spec.ink.withOpacity(.3))),
            if (p != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  color: Colors.black.withOpacity(.6),
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
          optionsBuilder: (v) async => v.text.length < 2 ? const <Person>[] : (await data.searchPeople(v.text)).take(6),
          onSelected: (o) => setState(() => picks[i] = o),
          fieldViewBuilder: (_, ctl, focus, submit) => TextField(
            controller: ctl,
            focusNode: focus,
            decoration: InputDecoration(labelText: 'Attore ${i + 1}', border: const OutlineInputBorder()),
          ),
        ),
        TextButton(onPressed: () => _random(i), child: const Text('Scegli per me')),
      ]),
    );
  }
}
