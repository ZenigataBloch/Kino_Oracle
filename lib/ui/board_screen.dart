import 'dart:math';
import 'package:flutter/material.dart';
import '../game/board_state.dart';
import '../main.dart';
import '../models/models.dart';
import 'metro_painter.dart';

class Suggestion {
  final Person? person;
  final Movie? movie;
  const Suggestion.person(Person p) : person = p, movie = null;
  const Suggestion.movie(Movie m) : movie = m, person = null;
  String get label => person?.name ?? '${movie!.title}${movie!.year == null ? '' : ' (${movie!.year})'}';
}

class BoardScreen extends StatefulWidget {
  final BoardState state;
  const BoardScreen(this.state, {super.key});
  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  TextEditingController? _field;
  bool _hasOptions = false;
  final _tc = TransformationController();
  Size _view = Size.zero;
  int _count = 0;
  BoardState get s => widget.state;

  @override
  void initState() {
    super.initState();
    s.addListener(_onState);
  }

  @override
  void dispose() {
    s.removeListener(_onState);
    s.dispose();
    _tc.dispose();
    super.dispose();
  }

  void _onState() {
    final n = s.people.length + s.movies.length;
    if (n != _count) {
      _count = n;
      WidgetsBinding.instance.addPostFrameCallback((_) => _fit());
    }
  }

  /// Adatta la mappa allo spazio disponibile.
  void _fit() {
    if (!mounted || _view.isEmpty) return;
    final sz = s.layout().size;
    final sc = min(1.0, min(_view.width / sz.width, _view.height / sz.height));
    final tx = (_view.width - sz.width * sc) / 2, ty = (_view.height - sz.height * sc) / 2;
    _tc.value = Matrix4(sc, 0, 0, 0, 0, sc, 0, 0, 0, 0, 1, 0, tx, ty, 0, 1);
  }

  Future<List<Suggestion>> _suggest(String q) async {
    if (q.trim().length < 2) return _noOptions();
    try {
      final pf = s.data.searchPeople(q), mf = s.data.searchMovies(q);
      final ppl = (await pf).where((p) => !s.people.containsKey(p.id)).take(4).toList();
      final mvs = (await mf).where((m) => !s.movies.containsKey(m.id)).take(4).toList();
      final out = <Suggestion>[];
      for (var i = 0; i < 4; i++) {
        if (i < mvs.length) out.add(Suggestion.movie(mvs[i]));
        if (i < ppl.length) out.add(Suggestion.person(ppl[i]));
      }
      _hasOptions = out.isNotEmpty;
      return out;
    } catch (_) {
      return _noOptions();
    }
  }

  List<Suggestion> _noOptions() {
    _hasOptions = false;
    return [];
  }

  Future<void> _select(Suggestion o) async {
    o.person != null ? await s.addPersonEntity(o.person!) : await s.addMovieEntity(o.movie!);
    _field?.clear();
  }

  Future<void> _addText() async {
    final q = _field?.text.trim() ?? '';
    if (q.isEmpty) return;
    await s.addByText(q);
    if (s.message == null) _field?.clear();
  }

  @override
  Widget build(BuildContext context) {
    final spec = settings.spec;
    return ListenableBuilder(
      listenable: s,
      builder: (_, __) => Scaffold(
        appBar: AppBar(
          backgroundColor: spec.bg,
          title: Text('${s.a.name}  ⇄  ${s.b.name}', style: const TextStyle(fontSize: 16)),
          actions: [Center(child: Padding(padding: const EdgeInsets.all(12), child: Text('Mosse: ${s.moves}')))],
        ),
        body: Column(children: [
          if (s.solved)
            MaterialBanner(
              content: Text(s.verdict),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Nuova partita'))],
            ),
          Expanded(
            child: LayoutBuilder(builder: (_, box) {
              final size = Size(box.maxWidth, box.maxHeight);
              if (size != _view) {
                _view = size;
                WidgetsBinding.instance.addPostFrameCallback((_) => _fit());
              }
              final lay = s.layout();
              return Stack(children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    transformationController: _tc,
                    constrained: false,
                    minScale: 0.2,
                    maxScale: 3,
                    boundaryMargin: const EdgeInsets.all(600),
                    child: CustomPaint(size: lay.size, painter: MetroPainter(s, spec, lay)),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: IconButton.filledTonal(
                    tooltip: 'Adatta la mappa',
                    onPressed: _fit,
                    icon: const Icon(Icons.fit_screen),
                  ),
                ),
              ]);
            }),
          ),
          if (s.message != null)
            Padding(padding: const EdgeInsets.all(8), child: Text(s.message!, style: TextStyle(color: spec.accent))),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(children: [
                Expanded(
                  child: Autocomplete<Suggestion>(
                    optionsViewOpenDirection: OptionsViewOpenDirection.up,
                    displayStringForOption: (o) => o.label,
                    optionsBuilder: (v) => _suggest(v.text),
                    onSelected: _select,
                    fieldViewBuilder: (_, ctl, focus, submit) {
                      _field = ctl;
                      return TextField(
                        controller: ctl,
                        focusNode: focus,
                        enabled: !s.busy && !s.solved,
                        onSubmitted: (_) => _hasOptions ? submit() : _addText(),
                        decoration: const InputDecoration(
                          hintText: 'Film o attore collegato a qualcosa sul tavolo…',
                          border: OutlineInputBorder(),
                        ),
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) => Align(
                      alignment: Alignment.bottomLeft,
                      child: Material(
                        elevation: 4,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 320, maxWidth: 460),
                          child: ListView(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            children: [
                              for (final o in options)
                                ListTile(
                                  dense: true,
                                  leading: Icon(o.person != null ? Icons.person : Icons.movie),
                                  title: Text(o.label),
                                  onTap: () => onSelected(o),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Aggiungi il testo digitato',
                  onPressed: s.busy || s.solved ? null : _addText,
                  icon: s.busy
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.add),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
