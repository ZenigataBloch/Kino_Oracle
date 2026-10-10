import 'dart:math';
import 'package:flutter/material.dart';
import '../data/data_source.dart';
import '../game/board_state.dart';
import '../main.dart';
import '../models/models.dart';
import 'board_screen.dart';
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

  Future<void> _random(int i) async {
    final r = await data.searchPeople(_famous[Random().nextInt(_famous.length)]);
    if (r.isNotEmpty) setState(() { picks[i] = r.first; _keys[i] = UniqueKey(); });
  }

  @override
  Widget build(BuildContext context) {
    final spec = settings.spec;
    data = makeSource(settings.source, settings.lang);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: spec.bg,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('KINO ORACLE', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: spec.accent)),
            const SizedBox(height: 8),
            const Text('Scegli due attori e collegali attraverso i film'),
            const SizedBox(height: 32),
            Wrap(spacing: 24, runSpacing: 24, alignment: WrapAlignment.center, children: [
              for (var i = 0; i < 2; i++) _slot(i),
            ]),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: picks[0] != null && picks[1] != null && picks[0]!.id != picks[1]!.id
                  ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => BoardScreen(BoardState(picks[0]!, picks[1]!, data))))
                  : null,
              child: const Text('Gioca'),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _slot(int i) {
    final p = picks[i];
    return SizedBox(
      width: 260,
      child: Column(children: [
        Container(
          height: 240,
          decoration: BoxDecoration(border: Border.all(color: settings.spec.ink, width: 3), borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: p?.photoUrl != null
              ? Image.network(p!.photoUrl!, fit: BoxFit.cover, width: double.infinity)
              : Center(child: Icon(Icons.person, size: 80, color: settings.spec.ink.withOpacity(.3))),
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
