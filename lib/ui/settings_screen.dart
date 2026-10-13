import 'package:flutter/material.dart';
import '../data/filters.dart';
import '../data/regions.dart';
import '../main.dart';
import 'style_picker.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: settings,
        builder: (_, __) => Scaffold(
          appBar: AppBar(title: const Text('Impostazioni')),
          body: ListView(children: [
            const _Header('Stile grafico'),
            const StylePicker(),
            const _Header('Aspetto'),
            const AppearancePicker(),
            const _Header('Partita'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'movie', label: Text('Film')),
                  ButtonSegment(value: 'tv', label: Text('Serie')),
                  ButtonSegment(value: 'both', label: Text('Entrambi')),
                ],
                selected: {settings.mediaMode},
                onSelectionChanged: (s) => settings.update(mediaMode: s.first),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text('Tempo a disposizione'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Nessuno')),
                  ButtonSegment(value: 2, label: Text('2 min')),
                  ButtonSegment(value: 3, label: Text('3 min')),
                  ButtonSegment(value: 5, label: Text('5 min')),
                ],
                selected: {settings.timeLimit},
                onSelectionChanged: (v) => settings.update(timeLimit: v.first),
              ),
            ),
            SwitchListTile(
              title: const Text('Percorso obbligato'),
              subtitle: const Text('Un film o un attore assegnato da cui il collegamento deve passare'),
              value: settings.mustPass,
              onChanged: (v) => settings.update(mustPass: v),
            ),
            SwitchListTile(
              title: const Text('Vieta film della stessa serie'),
              subtitle: const Text('Non ancora implementato'),
              value: settings.noSeries,
              onChanged: (v) => settings.update(noSeries: v),
            ),
            const _Header(
              'Decenni e generi',
              subtitle: 'Limita film e serie ai decenni e ai generi scelti (nessuna scelta = nessun limite). '
                  'Vale per suggerimenti e collegamenti.',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(spacing: 8, runSpacing: 4, children: [
                for (final d in kDecades)
                  FilterChip(
                    label: Text('${d}s'),
                    selected: settings.decadeFilter.contains(d),
                    onSelected: (on) {
                      final x = {...settings.decadeFilter};
                      on ? x.add(d) : x.remove(d);
                      settings.update(decadeFilter: x);
                    },
                  ),
              ]),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(spacing: 8, runSpacing: 4, children: [
                for (final g in kGenres.entries)
                  FilterChip(
                    label: Text(g.value),
                    selected: settings.genreFilter.contains(g.key),
                    onSelected: (on) {
                      final x = {...settings.genreFilter};
                      on ? x.add(g.key) : x.remove(g.key);
                      settings.update(genreFilter: x);
                    },
                  ),
              ]),
            ),
            const _Header(
              'Cinematografie da escludere',
              subtitle: 'Esclude i film in queste lingue originali e gli attori noti soprattutto per quei film. '
                  'Un attore asiatico in un film americano resta giocabile.',
            ),
            for (final r in Region.values)
              SwitchListTile(
                title: Text(r.label),
                value: settings.excludedRegions.contains(r.name),
                onChanged: (on) {
                  final s = {...settings.excludedRegions};
                  on ? s.add(r.name) : s.remove(r.name);
                  settings.update(excludedRegions: s);
                },
              ),
            const _Header('Dati'),
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
            const _Header('Chiave TMDB'),
            const _TokenTile(),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Text(
                'This product uses the TMDB API but is not endorsed or certified by TMDB.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ]),
        ),
      );
}

/// Intestazione di sezione: titolo in maiuscolo con il colore dell'accento.
class _Header extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _Header(this.title, {this.subtitle});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: scheme.primary),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle!, style: TextStyle(fontSize: 13, color: scheme.onSurface.withValues(alpha: .7))),
        ],
      ]),
    );
  }
}

/// Campo per incollare la chiave TMDB: "Read Access Token" (v4, inizia con eyJ) o "API Key" (v3).
class _TokenTile extends StatefulWidget {
  const _TokenTile();
  @override
  State<_TokenTile> createState() => _TokenTileState();
}

class _TokenTileState extends State<_TokenTile> {
  late final _ctl = TextEditingController(text: settings.tmdbToken);
  bool _hide = true;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _save() {
    FocusScope.of(context).unfocus();
    settings.update(tmdbToken: _ctl.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_ctl.text.trim().isEmpty ? 'Chiave rimossa' : 'Chiave salvata')),
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(
            controller: _ctl,
            obscureText: _hide,
            autocorrect: false,
            enableSuggestions: false,
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(
              labelText: 'Read Access Token o API Key',
              helperText: 'Gratis su themoviedb.org: Impostazioni > API',
              helperMaxLines: 2,
              suffixIcon: IconButton(
                tooltip: _hide ? 'Mostra' : 'Nascondi',
                icon: Icon(_hide ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _hide = !_hide),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerRight, child: FilledButton(onPressed: _save, child: const Text('Salva'))),
        ]),
      );
}
