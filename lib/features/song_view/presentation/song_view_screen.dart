import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:libre_tab/app/router.dart';
import 'package:libre_tab/app/settings/settings_store.dart';
import 'package:libre_tab/app/theme/app_theme.dart';
import 'package:libre_tab/app/theme/libre_colors.dart';
import 'package:libre_tab/app/theme/theme_controller.dart';
import 'package:libre_tab/core/chordpro/chordpro_parser.dart';
import 'package:libre_tab/core/database/app_database.dart';
import 'package:libre_tab/core/device/keep_awake.dart';
import 'package:libre_tab/core/files/song_files.dart';
import 'package:libre_tab/core/music/chord.dart';
import 'package:libre_tab/core/music/chord_voicings.dart';
import 'package:libre_tab/core/music/music_key.dart';
import 'package:libre_tab/core/music/transposition.dart';
import 'package:libre_tab/core/widgets/placeholder_body.dart';
import 'package:libre_tab/features/library/application/library_providers.dart';
import 'package:libre_tab/features/library/data/song_repository.dart';
import 'package:libre_tab/features/song_view/presentation/widgets/chord_diagram.dart';
import 'package:libre_tab/features/song_view/presentation/widgets/song_sheet.dart';
import 'package:libre_tab/l10n/l10n.dart';

/// "Campfire mode": the song with its chords, a dock to transpose, set the
/// capo, resize text and auto-scroll, and chord diagrams on tap
/// (docs/DESIGN.md § Song view).
class SongViewScreen extends ConsumerWidget {
  const SongViewScreen({required this.songId, super.key});

  /// Null when the route's id wasn't a number.
  final int? songId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = songId;
    if (id == null) return const _NotFound();
    return ref
        .watch(songProvider(id))
        .when(
          skipLoadingOnReload: true,
          loading: () => Scaffold(appBar: AppBar()),
          error: (_, _) => const _NotFound(),
          data: (entry) => entry == null ? const _NotFound() : _SongView(entry),
        );
  }
}

enum _Action { chords, edit, share, delete }

class _SongView extends ConsumerStatefulWidget {
  const _SongView(this.entry);

  final SongEntry entry;

  @override
  ConsumerState<_SongView> createState() => _SongViewState();
}

class _SongViewState extends ConsumerState<_SongView>
    with SingleTickerProviderStateMixin {
  /// Auto-scroll speeds, in pixels per second at the default text size.
  static const _speeds = [6.0, 10.0, 15.0, 22.0, 32.0, 45.0];
  static const _defaultSpeed = 2;

  final _scroll = ScrollController();
  late final Ticker _ticker = createTicker(_tick);
  Duration _lastTick = Duration.zero;
  late final KeepAwake _keepAwake = ref.read(keepAwakeProvider);

  late Transposition _transposition = Transposition.asWritten(
    ChordProParser.parse(widget.entry.body).capo?.clamp(0, 11),
  );
  late int _speed = (widget.entry.scrollSpeed ?? _defaultSpeed).clamp(
    1,
    _speeds.length,
  );

  bool get _playing => _ticker.isActive;

  @override
  void initState() {
    super.initState();
    unawaited(_keepAwake.enable());
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scroll.dispose();
    unawaited(_keepAwake.disable());
    super.dispose();
  }

  void _tick(Duration elapsed) {
    final seconds = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    final scale = ref.read(lyricsSizeProvider) / LyricsSizeController.initial;
    final next = position.pixels + _speeds[_speed - 1] * scale * seconds;
    if (next >= position.maxScrollExtent) {
      _scroll.jumpTo(position.maxScrollExtent);
      _setPlaying(false);
    } else {
      _scroll.jumpTo(next);
    }
  }

  void _setPlaying(bool play) {
    if (play == _playing) return;
    setState(() {
      if (play) {
        _lastTick = Duration.zero;
        unawaited(_ticker.start());
      } else {
        _ticker.stop();
      }
    });
  }

  void _togglePlay() {
    // At the end already: start again from the top.
    if (!_playing && _scroll.hasClients) {
      final p = _scroll.position;
      if (p.maxScrollExtent > 0 && p.pixels >= p.maxScrollExtent - 1) {
        _scroll.jumpTo(0);
      }
    }
    _setPlaying(!_playing);
  }

  void _changeSpeed(int delta) {
    final speed = (_speed + delta).clamp(1, _speeds.length);
    if (speed == _speed) return;
    setState(() => _speed = speed);
    unawaited(
      ref.read(songRepositoryProvider).setScrollSpeed(widget.entry.id, speed),
    );
  }

  void _transpose(int delta) => setState(() {
    final semitones = (_transposition.semitones + delta).clamp(-11, 11);
    _transposition = _transposition.copyWith(semitones: semitones);
  });

  void _moveCapo(int delta) => setState(() {
    final capo = (_transposition.capo + delta).clamp(0, 11);
    _transposition = _transposition.copyWith(capo: capo);
  });

  Future<void> _showChords(List<String> chords) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _ChordsSheet(chords: chords),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final entry = widget.entry;
    final song = ChordProParser.parse(entry.body);
    final key = song.effectiveKey;
    final t = _transposition;
    // Without a key, spell transposed chords with sharps.
    String shown(String chord) => t.chord(chord, key ?? const MusicKey(0));
    final sounding = key == null ? null : t.soundingKey(key).name;
    final fontSize = ref.watch(lyricsSizeProvider);
    final size = ref.read(lyricsSizeProvider.notifier);

    final subtitle = t.capo > 0 && key != null
        ? l10n.soundsIn(sounding!, t.capo, t.shapeKey(key).name)
        : [
            if (entry.artist.isNotEmpty) entry.artist,
            if (sounding != null) l10n.keyLabel(sounding),
            if (t.capo > 0) l10n.capoLabel(t.capo),
          ].join(' · ');

    final allChords = [
      ...{
        for (final chord in song.chords)
          if (Chord.tryParse(chord) != null) shown(chord),
      },
    ];

    final semitoneLabel = t.semitones == 0
        ? ''
        : ' (${t.semitones > 0 ? '+' : '−'}${t.semitones.abs()})';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                // Body font: the app bar's title style would make it serif.
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  fontVariations: const [],
                  letterSpacing: 0,
                  color: context.colors.muted,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: entry.favorite ? l10n.removeFavorite : l10n.addFavorite,
            icon: Icon(
              entry.favorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: entry.favorite ? context.colors.accent : null,
            ),
            onPressed: () => ref
                .read(songRepositoryProvider)
                .setFavorite(entry.id, favorite: !entry.favorite),
          ),
          IconButton(
            tooltip: l10n.switchTheme,
            icon: const Icon(Icons.dark_mode_outlined),
            onPressed: () => ref.read(themeVariantProvider.notifier).cycle(),
          ),
          PopupMenuButton<_Action>(
            tooltip: l10n.moreActions,
            onSelected: (action) => switch (action) {
              _Action.chords => _showChords(allChords),
              _Action.edit => context.push(Routes.editSong(entry.id)),
              _Action.share =>
                ref
                    .read(songFilesProvider)
                    .share(title: entry.title, body: entry.body),
              _Action.delete => _confirmDelete(context),
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _Action.chords,
                child: Text(l10n.chordsMenu),
              ),
              PopupMenuItem(value: _Action.edit, child: Text(l10n.editSong)),
              PopupMenuItem(value: _Action.share, child: Text(l10n.share)),
              PopupMenuItem(value: _Action.delete, child: Text(l10n.delete)),
            ],
          ),
        ],
      ),
      body: NotificationListener<ScrollStartNotification>(
        // Dragging the song yourself pauses auto-scroll.
        onNotification: (n) {
          if (n.dragDetails != null) _setPlaying(false);
          return false;
        },
        child: GestureDetector(
          // Tap the lyrics to pause or resume. The dock's play button is the
          // accessible control for the same thing.
          behavior: HitTestBehavior.translucent,
          excludeFromSemantics: true,
          onTap: _togglePlay,
          child: SingleChildScrollView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
            child: SongSheet(
              song: song,
              fontSize: fontSize,
              chordLabel: shown,
              onChordTap: (chord) => _showChords([chord]),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _Dock(
        rows: [
          [
            _StepperModel(
              label: l10n.keyStepper,
              value: sounding == null
                  ? semitoneLabel.trim()
                  : '$sounding$semitoneLabel',
              minus: (l10n.transposeDown, () => _transpose(-1)),
              plus: (l10n.transposeUp, () => _transpose(1)),
            ),
            _StepperModel(
              label: l10n.capoStepper,
              value: t.capo == 0 ? l10n.capoNone : '${t.capo}',
              minus: (l10n.capoDown, t.capo > 0 ? () => _moveCapo(-1) : null),
              plus: (l10n.capoUp, t.capo < 11 ? () => _moveCapo(1) : null),
            ),
          ],
          [
            _StepperModel(
              label: l10n.textSize,
              value: '${fontSize.round()}',
              minus: (l10n.smallerText, size.canShrink ? size.shrink : null),
              plus: (l10n.largerText, size.canGrow ? size.grow : null),
            ),
            _StepperModel(
              label: l10n.speedLabel(_speed),
              value: '',
              minus: (l10n.slower, _speed > 1 ? () => _changeSpeed(-1) : null),
              plus: (
                l10n.faster,
                _speed < _speeds.length ? () => _changeSpeed(1) : null,
              ),
              center: _PlayButton(
                playing: _playing,
                speed: _speed,
                onPressed: _togglePlay,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = context.l10n;
    final entry = widget.entry;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.deleteTitle(entry.title)),
        content: Text(l10n.deleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final repository = ref.read(songRepositoryProvider);
    context.pop();
    await repository.deleteSong(entry.id);
  }
}

/// A − / value / + control. [minus] and [plus] are (tooltip, action); a
/// null action disables the button.
class _StepperModel {
  const _StepperModel({
    required this.label,
    required this.value,
    required this.minus,
    required this.plus,
    this.center,
  });

  final String label;
  final String value;
  final (String, VoidCallback?) minus;
  final (String, VoidCallback?) plus;
  final Widget? center;
}

class _Dock extends StatelessWidget {
  const _Dock({required this.rows});

  final List<List<_StepperModel>> rows;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, row) in rows.indexed) ...[
                if (i > 0) const SizedBox(height: 10),
                Row(
                  children: [
                    for (final (j, model) in row.indexed) ...[
                      if (j > 0) const SizedBox(width: 10),
                      Expanded(child: _Stepper(model)),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper(this.model);

  final _StepperModel model;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (minusTip, onMinus) = model.minus;
    final (plusTip, onPlus) = model.plus;
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: minusTip,
            icon: const Icon(Icons.remove),
            onPressed: onMinus,
          ),
          Expanded(
            child:
                model.center ??
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        model.label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: colors.muted,
                        ),
                      ),
                      Text(
                        model.value,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
          ),
          IconButton(
            tooltip: plusTip,
            icon: const Icon(Icons.add),
            onPressed: onPlus,
          ),
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.playing,
    required this.speed,
    required this.onPressed,
  });

  final bool playing;
  final int speed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Tooltip(
      message: playing ? l10n.pauseScroll : l10n.startScroll,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(playing ? Icons.pause : Icons.play_arrow),
              const SizedBox(width: 4),
              Text(l10n.speedLabel(speed)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Diagrams for one chord (tapped in the song) or all of the song's chords.
class _ChordsSheet extends StatelessWidget {
  const _ChordsSheet({required this.chords});

  final List<String> chords;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        // Full width, so the sheet doesn't shrink to its content.
        child: chords.isEmpty
            ? SizedBox(
                width: double.infinity,
                child: Text(l10n.noChords, textAlign: TextAlign.center),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 28,
                    runSpacing: 20,
                    children: [
                      for (final chord in chords)
                        SizedBox(
                          width: 150,
                          child: Column(
                            children: [
                              Text(
                                chord,
                                style: AppFonts.displayStyle(36, colors.chord),
                              ),
                              const SizedBox(height: 8),
                              switch (ChordVoicings.forSymbol(chord)) {
                                final voicing? => ChordDiagram(
                                  voicing: voicing,
                                ),
                                null => SizedBox(
                                  height: 120,
                                  child: Center(
                                    child: Text(
                                      l10n.noDiagram,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: colors.muted),
                                    ),
                                  ),
                                ),
                              },
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.diagramLegend,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: colors.muted),
                  ),
                ],
              ),
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: PlaceholderBody(message: context.l10n.songNotFound),
  );
}
