import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
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
import 'package:libre_tab/core/widgets/motion.dart';
import 'package:libre_tab/core/widgets/placeholder_body.dart';
import 'package:libre_tab/core/widgets/readable_width.dart';
import 'package:libre_tab/features/library/application/library_providers.dart';
import 'package:libre_tab/features/library/data/song_repository.dart';
import 'package:libre_tab/features/library/presentation/widgets/song_actions.dart';
import 'package:libre_tab/features/song_view/presentation/widgets/chord_diagram.dart';
import 'package:libre_tab/features/song_view/presentation/widgets/song_sheet.dart';
import 'package:libre_tab/features/song_view/presentation/widgets/song_title_hero.dart';
import 'package:libre_tab/l10n/l10n.dart';

/// "Campfire mode": the song with its chords, a dock to transpose, set the
/// capo, resize text and auto-scroll, and chord diagrams on tap
/// (docs/DESIGN.md § Song view).
class SongViewScreen extends ConsumerWidget {
  const SongViewScreen({
    required this.songId,
    this.position,
    this.upNext,
    this.autoPlay = false,
    super.key,
  });

  /// Null when the route's id wasn't a number.
  final int? songId;

  /// (n, total) while playing a setlist: shown as "n/total".
  final (int, int)? position;

  /// In a setlist: the next song, shown after this one's last line.
  final UpNext? upNext;

  /// Starts auto-scrolling on its own (the previous song ran into this one).
  final bool autoPlay;

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
          data: (entry) => entry == null
              ? const _NotFound()
              : _SongView(entry, position, upNext, autoPlay: autoPlay),
        );
  }
}

enum _Action { chords, addToSetlist, edit, share, delete }

/// The song after this one in a setlist, and how to go to it
/// (`autoPlay`: keep auto-scrolling there).
final class UpNext {
  const UpNext({required this.title, required this.go});

  final String title;
  final void Function({required bool autoPlay}) go;
}

class _SongView extends ConsumerStatefulWidget {
  const _SongView(
    this.entry,
    this.position,
    this.upNext, {
    required this.autoPlay,
  });

  final SongEntry entry;
  final (int, int)? position;
  final UpNext? upNext;
  final bool autoPlay;

  @override
  ConsumerState<_SongView> createState() => _SongViewState();
}

class _SongViewState extends ConsumerState<_SongView>
    with SingleTickerProviderStateMixin {
  /// Auto-scroll speeds, in pixels per second at the default text size.
  static const _speeds = [6.0, 10.0, 15.0, 22.0, 32.0, 45.0];
  static const _defaultSpeed = 2;

  /// Room to scroll past the song's first and last lines: half the visible
  /// height, so auto-scroll can bring the last lines up to the middle. The
  /// song opens scrolled past the top room, so it starts at the top.
  double _room = 0;
  double? _roomWidth;
  late final ScrollController _scroll;

  /// How far through the song auto-scroll has got (0–1), for the line under
  /// the title.
  final _progress = ValueNotifier<double>(0);
  bool _scrollReady = false;
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  late final KeepAwake _keepAwake = ref.read(keepAwakeProvider);

  late Transposition _transposition = Transposition.asWritten(
    ChordProParser.parse(widget.entry.body).capo?.clamp(0, 11),
  );
  late int _speed = (widget.entry.scrollSpeed ?? _defaultSpeed).clamp(
    1,
    _speeds.length,
  );

  /// Whether auto-scroll is on (the Play button). It only moves while no
  /// finger is on the lyrics and the user isn't scrolling them.
  bool _playing = false;
  int _fingers = 0;
  bool _userScrolling = false;

  bool get _moving => _playing && _fingers == 0 && !_userScrolling;

  /// Seconds until the next song in a setlist, once auto-scroll has
  /// reached the end; null when not counting down.
  int? _countdown;
  Timer? _countdownTimer;
  static const _countdownFrom = 5;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    unawaited(_keepAwake.enable());
    // For "Recently played" and "Played 12×" in the songbook.
    unawaited(ref.read(songRepositoryProvider).recordOpened(widget.entry.id));
    // For the one-time thank-you after the 10th song.
    final store = ref.read(settingsStoreProvider);
    store.setInt(
      SettingsKeys.songsOpened,
      (store.getInt(SettingsKeys.songsOpened) ?? 0) + 1,
    );
    if (widget.autoPlay) {
      // A moment at the top first, to see where the song starts.
      _countdownTimer = Timer(const Duration(seconds: 1), () {
        if (mounted) _setPlaying(true);
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _countdownTimer?.cancel();
    _progress.dispose();
    if (_scrollReady) _scroll.dispose();
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
      // Hands-free to the end of a setlist song: on to the next one.
      if (widget.upNext != null) _startCountdown();
    } else {
      _scroll.jumpTo(next);
    }
  }

  void _setPlaying(bool play) {
    if (play == _playing) return;
    setState(() => _playing = play);
    _syncTicker();
  }

  void _syncTicker() {
    if (_moving == _ticker.isActive) return;
    if (_moving) {
      _lastTick = Duration.zero;
      _ticker.start();
    } else {
      _ticker.stop();
    }
  }

  /// Scrolling by hand moves the song; auto-scroll then carries on from
  /// there once the scroll (and any fling) has settled.
  bool _onScroll(ScrollNotification n) {
    if (n is ScrollStartNotification && n.dragDetails != null) {
      _userScrolling = true;
    } else if (n is ScrollEndNotification && _userScrolling) {
      _userScrolling = false;
    }
    _syncTicker();
    // From the first line at the top (past the room) to the end.
    final m = n.metrics;
    if (m.maxScrollExtent > _room) {
      _progress.value = ((m.pixels - _room) / (m.maxScrollExtent - _room))
          .clamp(0.0, 1.0);
    }
    return false;
  }

  /// Sets the room above and below the song. The first time, the scroll
  /// view opens past the top room; later (rotation) the song keeps its place.
  /// Only a new width (rotation, split view) changes it: the dock folding
  /// away while playing shouldn't nudge the song.
  void _fitRoom(double room, double width) {
    if (!_scrollReady) {
      _room = room;
      _roomWidth = width;
      _scroll = ScrollController(initialScrollOffset: room);
      _scrollReady = true;
      return;
    }
    if (width == _roomWidth || room == _room) return;
    _roomWidth = width;
    final shift = room - _room;
    _room = room;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(
          (_scroll.offset + shift).clamp(0, _scroll.position.maxScrollExtent),
        );
      }
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _countdown = _countdownFrom);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final left = (_countdown ?? 0) - 1;
      if (left > 0) {
        setState(() => _countdown = left);
        return;
      }
      timer.cancel();
      setState(() => _countdown = null);
      widget.upNext?.go(autoPlay: true);
    });
  }

  /// "Stay", or any touch on the song: no moving on.
  void _stopCountdown() {
    if (_countdown == null) return;
    _countdownTimer?.cancel();
    setState(() => _countdown = null);
  }

  void _fingerDown() {
    _stopCountdown();
    _fingers++;
    _syncTicker();
  }

  void _fingerUp() {
    if (_fingers > 0) _fingers--;
    _syncTicker();
  }

  void _togglePlay() {
    unawaited(HapticFeedback.lightImpact());
    // At the end already: start again from the top.
    if (!_playing && _scroll.hasClients) {
      final p = _scroll.position;
      if (p.maxScrollExtent > 0 && p.pixels >= p.maxScrollExtent - 1) {
        _scroll.jumpTo(_room);
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

    final position = switch (widget.position) {
      (final n, final total) => '$n/$total',
      null => null,
    };
    final subtitle = [
      ?position,
      if (t.capo > 0 && key != null)
        l10n.soundsIn(sounding!, t.capo, t.shapeKey(key).name)
      else ...[
        if (entry.artist.isNotEmpty) entry.artist,
        if (sounding != null) l10n.keyLabel(sounding),
        if (t.capo > 0) l10n.capoLabel(t.capo),
      ],
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
            SongTitleHero(
              songId: entry.id,
              title: entry.title,
              inSongView: true,
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
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
          _FavoriteStar(
            favorite: entry.favorite,
            onPressed: () {
              unawaited(HapticFeedback.selectionClick());
              unawaited(
                ref
                    .read(songRepositoryProvider)
                    .setFavorite(entry.id, favorite: !entry.favorite),
              );
            },
          ),
          const _ThemeSwitch(),
          PopupMenuButton<_Action>(
            tooltip: l10n.moreActions,
            onSelected: (action) => switch (action) {
              _Action.chords => _showChords(allChords),
              _Action.addToSetlist => _addToSetlist(),
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
              PopupMenuItem(
                value: _Action.addToSetlist,
                child: Text(l10n.addToSetlist),
              ),
              PopupMenuItem(value: _Action.edit, child: Text(l10n.editSong)),
              PopupMenuItem(value: _Action.share, child: Text(l10n.share)),
              PopupMenuItem(value: _Action.delete, child: Text(l10n.delete)),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: ExcludeSemantics(
            child: ValueListenableBuilder(
              valueListenable: _progress,
              builder: (context, progress, _) => LinearProgressIndicator(
                value: progress,
                minHeight: 2,
                backgroundColor: Colors.transparent,
                color: context.colors.accent.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ),
      // A finger on the lyrics holds auto-scroll still, so the text isn't
      // pulled out from under it.
      body: ReadableWidth(
        maxWidth: 900,
        child: Listener(
          onPointerDown: (_) => _fingerDown(),
          onPointerUp: (_) => _fingerUp(),
          onPointerCancel: (_) => _fingerUp(),
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: GestureDetector(
              // Tap the lyrics to pause or resume. The dock's play button is
              // the accessible control for the same thing.
              behavior: HitTestBehavior.translucent,
              excludeFromSemantics: true,
              onTap: _togglePlay,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _fitRoom(constraints.maxHeight / 2, constraints.maxWidth);
                  return SingleChildScrollView(
                    controller: _scroll,
                    padding: EdgeInsets.fromLTRB(
                      20,
                      12 + _room,
                      20,
                      48 + _room,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SongSheet(
                          song: song,
                          fontSize: fontSize,
                          chordLabel: shown,
                          onChordTap: (chord) => _showChords([chord]),
                        ),
                        if (widget.upNext case final next?)
                          Padding(
                            padding: const EdgeInsets.only(top: 32),
                            child: _UpNextCard(
                              next: next,
                              countdown: _countdown,
                              onStay: _stopCountdown,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
      // While auto-scroll plays, the dock folds down to the speed control,
      // leaving the song the room; pausing (tap the lyrics) brings it back.
      bottomNavigationBar: AnimatedSize(
        duration: context.motion(const Duration(milliseconds: 220)),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: _Dock(
          compact: _playing,
          rows: [
            if (!_playing)
              [
                _StepperModel(
                  label: l10n.keyStepper,
                  value: sounding == null
                      ? semitoneLabel.trim()
                      : '$sounding$semitoneLabel',
                  minus: (
                    l10n.transposeDown,
                    t.semitones > -11 ? () => _transpose(-1) : null,
                  ),
                  plus: (
                    l10n.transposeUp,
                    t.semitones < 11 ? () => _transpose(1) : null,
                  ),
                ),
                _StepperModel(
                  label: l10n.capoStepper,
                  value: t.capo == 0 ? l10n.capoNone : '${t.capo}',
                  minus: (
                    l10n.capoDown,
                    t.capo > 0 ? () => _moveCapo(-1) : null,
                  ),
                  plus: (l10n.capoUp, t.capo < 11 ? () => _moveCapo(1) : null),
                ),
              ],
            [
              if (!_playing)
                _StepperModel(
                  label: l10n.textSize,
                  value: '${fontSize.round()}',
                  minus: (
                    l10n.smallerText,
                    size.canShrink ? size.shrink : null,
                  ),
                  plus: (l10n.largerText, size.canGrow ? size.grow : null),
                ),
              _StepperModel(
                label: l10n.speedLabel(_speed),
                value: '',
                minus: (
                  l10n.slower,
                  _speed > 1 ? () => _changeSpeed(-1) : null,
                ),
                plus: (
                  l10n.faster,
                  _speed < _speeds.length ? () => _changeSpeed(1) : null,
                ),
                center: _PlayButton(
                  playing: _playing,
                  label: l10n.speedLabel(_speed),
                  onPressed: _togglePlay,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _addToSetlist() =>
      showAddToSetlistSheet(context, songId: widget.entry.id);

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

/// After the last line of a setlist song: the next one, to go to it, or a
/// countdown to it after auto-scroll got here (with "Stay").
class _UpNextCard extends StatelessWidget {
  const _UpNextCard({
    required this.next,
    required this.countdown,
    required this.onStay,
  });

  final UpNext next;
  final int? countdown;
  final VoidCallback onStay;

  /// The countdown's length, in seconds.
  static const int from = _SongViewState._countdownFrom;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final seconds = countdown;
    return Material(
      color: colors.surface2,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => next.go(autoPlay: false),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (seconds == null ? l10n.upNext : l10n.nextSongIn(seconds))
                          .toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: colors.accent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      next.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              // Counting down: a ring fills around the arrow, so the time
              // left reads at a glance from across the fire.
              SizedBox.square(
                dimension: 36,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (seconds != null)
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 0,
                          end:
                              (_UpNextCard.from - seconds + 1) /
                              _UpNextCard.from,
                        ),
                        duration: context.motion(const Duration(seconds: 1)),
                        builder: (context, value, _) =>
                            CircularProgressIndicator(
                              value: value,
                              strokeWidth: 3,
                              color: colors.accent,
                              backgroundColor: colors.line,
                            ),
                      ),
                    Icon(Icons.arrow_forward, size: 20, color: colors.accent),
                  ],
                ),
              ),
              if (seconds != null)
                TextButton(onPressed: onStay, child: Text(l10n.stay)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The favorite star: starring a song bounces it, with a few sparks in the
/// flame's colour (like the chords rising off the logo).
class _FavoriteStar extends StatefulWidget {
  const _FavoriteStar({required this.favorite, required this.onPressed});

  final bool favorite;
  final VoidCallback onPressed;

  @override
  State<_FavoriteStar> createState() => _FavoriteStarState();
}

class _FavoriteStarState extends State<_FavoriteStar>
    with SingleTickerProviderStateMixin {
  late final _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  static final _bounce = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1,
        end: 1.35,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1.35,
        end: 1,
      ).chain(CurveTween(curve: Curves.elasticOut)),
      weight: 65,
    ),
  ]);

  @override
  void didUpdateWidget(_FavoriteStar old) {
    super.didUpdateWidget(old);
    if (widget.favorite && !old.favorite && !context.calm) {
      _burst.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accent = context.colors.accent;
    return IconButton(
      tooltip: widget.favorite ? l10n.removeFavorite : l10n.addFavorite,
      onPressed: widget.onPressed,
      icon: AnimatedBuilder(
        animation: _burst,
        builder: (context, star) => CustomPaint(
          painter: _burst.isAnimating
              ? _SparksPainter(progress: _burst.value, color: accent)
              : null,
          child: Transform.scale(
            scale: _burst.isAnimating ? _bounce.evaluate(_burst) : 1,
            child: star,
          ),
        ),
        child: Icon(
          widget.favorite ? Icons.star_rounded : Icons.star_outline_rounded,
          color: widget.favorite ? accent : null,
        ),
      ),
    );
  }
}

/// Six sparks flying out of the star and fading.
class _SparksPainter extends CustomPainter {
  const _SparksPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final t = Curves.easeOutCubic.transform(progress);
    final paint = Paint()
      ..color = color.withValues(alpha: color.a * (1 - progress));
    for (var i = 0; i < 6; i++) {
      final angle = -math.pi / 2 + i * math.pi / 3;
      final distance = 10 + 14 * t;
      canvas.drawCircle(
        center + Offset(math.cos(angle), math.sin(angle)) * distance,
        2.2 * (1 - progress) + 0.6,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SparksPainter old) =>
      old.progress != progress || old.color != color;
}

/// Tap: red night on or off. Long-press: all three themes to choose from.
class _ThemeSwitch extends ConsumerWidget {
  const _ThemeSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = ref.watch(themeVariantProvider);
    final themes = ref.read(themeVariantProvider.notifier);
    final night = theme == AppThemeVariant.redNight;
    final label = night ? l10n.leaveRedNight : l10n.themeRedNight;
    return MenuAnchor(
      menuChildren: [
        for (final (variant, name) in [
          (AppThemeVariant.dark, l10n.themeDark),
          (AppThemeVariant.redNight, l10n.themeRedNight),
          (AppThemeVariant.light, l10n.themeLight),
        ])
          MenuItemButton(
            leadingIcon: Icon(
              Icons.check,
              color: variant == theme ? null : Colors.transparent,
            ),
            onPressed: () => themes.variant = variant,
            child: Text(name),
          ),
      ],
      builder: (context, menu, _) {
        void open() {
          unawaited(HapticFeedback.mediumImpact());
          menu.open();
        }

        // One control for screen readers: the switch, with "Choose theme"
        // as its long-press action.
        return MergeSemantics(
          child: Semantics(
            onLongPressHint: l10n.chooseTheme,
            child: GestureDetector(
              onLongPress: open,
              // The tooltip would pop up on the same long press.
              child: Tooltip(
                message: label,
                triggerMode: TooltipTriggerMode.manual,
                excludeFromSemantics: true,
                child: IconButton(
                  icon: Icon(
                    night ? Icons.nightlight : Icons.nightlight_outlined,
                    semanticLabel: label,
                  ),
                  onPressed: () {
                    unawaited(HapticFeedback.selectionClick());
                    themes.toggleRedNight();
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
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
  const _Dock({required this.rows, this.compact = false});

  final List<List<_StepperModel>> rows;

  /// Just the speed control, narrow and centered (while playing).
  final bool compact;

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
        // Full-width background; the controls themselves stay phone-sized
        // on big screens.
        child: ReadableWidth(
          maxWidth: compact ? 280 : 760,
          fillHeight: false,
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
    final (minusTip, minus) = model.minus;
    final (plusTip, plus) = model.plus;
    VoidCallback? withClick(VoidCallback? action) => action == null
        ? null
        : () {
            unawaited(HapticFeedback.selectionClick());
            action();
          };
    final onMinus = withClick(minus);
    final onPlus = withClick(plus);
    final label = Text(
      model.label.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: colors.muted,
      ),
    );
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
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // A center control (play) carries its own caption.
                  if (model.center case final center?)
                    center
                  else ...[
                    label,
                    Text(
                      model.value,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
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

/// Play / pause, with the speed it plays at under the icon ("SPEED 2").
class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.playing,
    required this.label,
    required this.onPressed,
  });

  final bool playing;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Tooltip(
      message: playing ? l10n.pauseScroll : l10n.startScroll,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size(72, 48),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(playing ? Icons.pause : Icons.play_arrow, size: 22),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                height: 1.1,
              ),
            ),
          ],
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
    body: PlaceholderBody(
      icon: Icons.music_off_outlined,
      message: context.l10n.songNotFound,
    ),
  );
}
