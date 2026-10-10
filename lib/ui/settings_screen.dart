import 'package:flutter/material.dart';
import '../main.dart';
import '../data/data_source.dart';
import '../theme/kino_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: settings,
        builder: (_, __) => Scaffold(
          appBar: AppBar(title: const Text('Impostazioni')),
          body: ListView(children: [
            const ListTile(title: Text('Stile grafico')),
            for (final k in KinoStyle.values)
              RadioListTile<KinoStyle>(
                value: k,
                groupValue: settings.style,
                title: Text(specs[k]!.label),
                onChanged: (v) => settings.update(style: v),
              ),
            const Divider(),
            SwitchListTile(
              title: const Text('Vieta film della stessa serie'),
              subtitle: const Text('Non ancora implementato'),
              value: settings.noSeries,
              onChanged: (v) => settings.update(noSeries: v),
            ),
            ListTile(
              title: const Text('Lingua dati'),
              trailing: DropdownButton<String>(
                value: settings.lang,
                items: const [
                  DropdownMenuItem(value: 'it-IT', child: Text('Italiano')),
                  DropdownMenuItem(value: 'en-US', child: Text('English')),
                ],
                onChanged: (v) => settings.update(lang: v),
              ),
            ),
            const Divider(),
            const ListTile(title: Text('Fonte dati')),
            RadioListTile<SourceId>(
              value: SourceId.tmdb,
              groupValue: settings.source,
              title: const Text('TMDB'),
              subtitle: Text(hasTmdbKey ? 'Cast e foto piu completi' : 'Avvia l\'app con TMDB_TOKEN per abilitarla'),
              onChanged: hasTmdbKey ? (v) => settings.update(source: v) : null,
            ),
            RadioListTile<SourceId>(
              value: SourceId.wikidata,
              groupValue: settings.source,
              title: const Text('Wikidata'),
              subtitle: const Text('Libera, senza chiave'),
              onChanged: (v) => settings.update(source: v),
            ),
          ]),
        ),
      );
}
