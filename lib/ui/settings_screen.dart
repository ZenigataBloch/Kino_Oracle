import 'package:flutter/material.dart';
import '../main.dart';
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
            const ListTile(title: Text('Aspetto')),
            for (final (a, label) in const [
              (Appearance.system, 'Sistema'),
              (Appearance.light, 'Chiaro'),
              (Appearance.dark, 'Scuro'),
              (Appearance.amoled, 'Scuro AMOLED (nero puro)'),
            ])
              RadioListTile<Appearance>(
                value: a,
                groupValue: settings.appearance,
                title: Text(label),
                onChanged: (v) => settings.update(appearance: v),
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
            const ListTile(title: Text('Chiave TMDB')),
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
              border: const OutlineInputBorder(),
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
