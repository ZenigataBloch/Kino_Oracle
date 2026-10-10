import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game/board_state.dart';
import '../game/game_log.dart';
import '../game/recap.dart';
import '../main.dart';
import '../models/models.dart';
import '../theme/kino_theme.dart';
import 'map_nodes.dart';
import 'metro_painter.dart';
import 'win_overlay.dart';

class Suggestion {
  final Person? person;
  final Movie? movie;
  const Suggestion.person(Person p) : person = p, movie = null;
  const Suggestion.movie(Movie m) : movie = m, person = null;
  String? get imageUrl => person?.photoUrl ?? movie?.posterUrl;
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
  bool _vertical = false; // telefono: mappa verticale
  int _count = 0;
  bool _showWin = false; // riepilogo di vittoria visibile
  bool _winSeen = false; // la vittoria e gia stata festeggiata
  bool _logged = false; // la partita e gia nel log
  BoardState get s => widget.state;

  @override
  void initState() {
    super.initState();
    s.addListener(_onState);
  }

  @override
  void dispose() {
    s.removeListener(_onState);
    if (s.solved) _saveLog(); // se si esce prima che il minimo sia calcolato
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
    if (s.solved && !_winSeen) {
      _winSeen = true;
      HapticFeedback.mediumImpact();
      setState(() => _showWin = true);
    }
    // Il log si scrive appena il percorso minimo e noto (le stelle dipendono da quello).
    if (s.solved && s.optimalReady) _saveLog();
  }

  void _saveLog() {
    if (_logged) return;
    _logged = true;
    GameLog.add(GameRecord.of(s)).catchError((_) {});
  }

  /// Chiude la partita: la home azzera i due attori scelti.
  void _newGame() => Navigator.pop(context, true);

  /// Parte subito una nuova partita con la coppia suggerita.
  void _playHint(PairingHint h) {
    final game = BoardState(h.x, h.y, s.data);
    Navigator.pushReplacement<bool, bool>(
      context,
      MaterialPageRoute<bool>(builder: (_) => BoardScreen(game)),
      result: true,
    );
  }

  /// Adatta la mappa allo spazio disponibile.
  void _fit() {
    if (!mounted || _view.isEmpty) return;
    final sz = s.layout(vertical: _vertical).size;
    double sc, tx, ty;
    if (_vertical) {
      // Telefono: adatta in larghezza, ma non sotto 0.75 (leggibilita); in altezza si scorre.
      sc = max(0.75, min(1.0, _view.width / sz.width));
      tx = sz.width * sc <= _view.width ? (_view.width - sz.width * sc) / 2 : 8;
      ty = sz.height * sc <= _view.height ? (_view.height - sz.height * sc) / 2 : 8;
    } else {
      sc = min(1.0, min(_view.width / sz.width, _view.height / sz.height));
      tx = (_view.width - sz.width * sc) / 2;
      ty = (_view.height - sz.height * sc) / 2;
    }
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
          title: Text('${s.a.name}  ⇄  ${s.b.name}',
              maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(
                avatar: const Icon(Icons.alt_route, size: 18),
                label: Text('Mosse: ${s.moves}'),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        body: Stack(children: [
          Column(children: [
            if (s.solved && !_showWin)
              MaterialBanner(
                content: Text(s.verdict),
                actions: [
                  TextButton(onPressed: () => setState(() => _showWin = true), child: const Text('Riepilogo')),
                  TextButton(onPressed: _newGame, child: const Text('Nuova partita')),
                ],
              ),
            Expanded(child: _map(spec)),
            if (s.message != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: spec.accent.withOpacity(.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: spec.accent.withOpacity(.4)),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline, size: 18, color: spec.accent),
                  const SizedBox(width: 8),
                  Expanded(child: Text(s.message!, style: TextStyle(color: spec.accent, fontSize: 15, fontWeight: FontWeight.w600))),
                ]),
              ),
            SafeArea(child: Padding(padding: const EdgeInsets.all(8), child: _inputRow())),
          ]),
          if (_showWin)
            Positioned.fill(
              child: WinOverlay(
                state: s,
                spec: spec,
                onNewGame: _newGame,
                onClose: () => setState(() => _showWin = false),
                onPlayHint: _playHint,
              ),
            ),
        ]),
      ),
    );
  }

  Widget _map(StyleSpec spec) {
    return LayoutBuilder(builder: (_, box) {
      final size = Size(box.maxWidth, box.maxHeight);
      final vertical = box.maxWidth < 600; // telefoni: catena dall'alto verso il basso
      if (size != _view || vertical != _vertical) {
        _view = size;
        _vertical = vertical;
        WidgetsBinding.instance.addPostFrameCallback((_) => _fit());
      }
      final lay = s.layout(vertical: vertical);
      final deg = <int, int>{}; // film per attore: 2+ = scambio
      for (final (p, _) in s.links) {
        deg[p] = (deg[p] ?? 0) + 1;
      }
      return Stack(children: [
        Positioned.fill(
          child: InteractiveViewer(
            transformationController: _tc,
            constrained: false,
            minScale: 0.2,
            maxScale: 3,
            boundaryMargin: EdgeInsets.all(vertical ? 200 : 600),
            child: SizedBox(
              width: lay.size.width,
              height: lay.size.height,
              child: Stack(clipBehavior: Clip.none, children: [
                Positioned.fill(child: CustomPaint(painter: MetroPainter(s, spec, lay, vertical: vertical))),
                for (final m in s.movies.values) _movieAt(m, lay, spec),
                for (final p in s.people.values) _personAt(p, lay, spec, deg[p.id] ?? 0),
              ]),
            ),
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
    });
  }

  Widget _personAt(Person p, MapLayout lay, StyleSpec spec, int films) {
    final node = PersonNode(
      person: p,
      spec: spec,
      isA: p.id == s.a.id,
      isB: p.id == s.b.id,
      hub: films >= 2,
      onTap: () => showNodeDetail(context, title: p.name, imageUrl: p.photoUrl, round: true, spec: spec),
    );
    final o = lay.pos['p${p.id}']!;
    return Positioned(left: o.dx - PersonNode.width / 2, top: o.dy - node.size / 2, width: PersonNode.width, child: node);
  }

  Widget _movieAt(Movie m, MapLayout lay, StyleSpec spec) {
    final node = MovieNode(
      movie: m,
      spec: spec,
      color: MetroPainter.lineColor(spec, m.id),
      onTap: () => showNodeDetail(
          context, title: m.title, subtitle: m.year, imageUrl: m.posterUrl, round: false, spec: spec),
    );
    final o = lay.pos['m${m.id}']!;
    return Positioned(left: o.dx - MovieNode.width / 2, top: o.dy - MovieNode.posterH / 2, width: MovieNode.width, child: node);
  }

  Widget _inputRow() {
    return Row(children: [
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
              decoration: InputDecoration(
                hintText: 'Film o attore collegato a qualcosa sul tavolo…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) => Align(
            alignment: Alignment.bottomLeft,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360, maxWidth: 460),
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: [
                    for (final o in options)
                      ListTile(
                        leading: SizedBox(
                          width: 40,
                          height: o.person != null ? 40 : 56,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(o.person != null ? 20 : 6),
                            child: NodeImage(
                              url: o.imageUrl,
                              fallback: o.person != null ? Icons.person : Icons.movie,
                              color: settings.spec.ink,
                            ),
                          ),
                        ),
                        title: Text(o.label, style: const TextStyle(fontSize: 16)),
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
    ]);
  }
}
