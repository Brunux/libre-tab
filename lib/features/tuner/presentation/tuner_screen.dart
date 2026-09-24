import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:libre_tab/app/router.dart';
import 'package:libre_tab/app/theme/app_theme.dart';
import 'package:libre_tab/app/theme/libre_colors.dart';
import 'package:libre_tab/core/device/app_settings.dart';
import 'package:libre_tab/core/device/keep_awake.dart';
import 'package:libre_tab/core/music/tunings.dart';
import 'package:libre_tab/core/widgets/readable_width.dart';
import 'package:libre_tab/features/library/application/library_providers.dart';
import 'package:libre_tab/features/tuner/application/tuner_controller.dart';
import 'package:libre_tab/features/tuner/presentation/widgets/tuner_gauge.dart';
import 'package:libre_tab/l10n/l10n.dart';

/// Listens only while this tab is on screen and the app is in front, so
/// the microphone is never on in the background.
class TunerScreen extends ConsumerStatefulWidget {
  const TunerScreen({super.key});

  @override
  ConsumerState<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends ConsumerState<TunerScreen> {
  late final AppLifecycleListener _lifecycle;
  late final KeepAwake _keepAwake = ref.read(keepAwakeProvider);
  var _visible = false;
  var _active = false;

  TunerController get _tuner => ref.read(tunerProvider.notifier);

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onStateChange: (_) => _sync());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Hidden tabs and screens covered by another route have tickers off.
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible != _visible) {
      _visible = visible;
      WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    if (_active) unawaited(_keepAwake.disable());
    super.dispose();
  }

  void _sync() {
    if (!mounted) return;
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    final foreground =
        lifecycle == null || lifecycle == AppLifecycleState.resumed;
    final active = _visible && foreground;
    if (active == _active) return;
    _active = active;
    if (active) {
      unawaited(_keepAwake.enable());
      // Check, don't ask: a prompt here would pause and resume the app
      // (on Android), which would land here again. Coming back from
      // Settings with the microphone allowed still starts the tuner.
      if (_tuner.micAskedBefore) unawaited(_tuner.start(ask: false));
    } else {
      unawaited(_keepAwake.disable());
      unawaited(_tuner.stop());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(tunerProvider);
    final firstTime =
        state.status == TunerStatus.idle && !_tuner.micAskedBefore;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 20,
        title: Text(
          l10n.tabTuner,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        actions: [
          // Capped so large text shrinks the label instead of pushing
          // the title off a small screen.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: TextButton(
              onPressed: () => _showA4Sheet(context),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(l10n.a4Label(state.a4)),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ReadableWidth(
        maxWidth: 640,
        child: switch (state.status) {
          // The system asks only once: point to Settings, and come back
          // to a running tuner (it retries when the app returns).
          TunerStatus.denied => _Message(
            icon: Icons.mic_off_outlined,
            title: l10n.micDeniedTitle,
            body: l10n.micDeniedBody,
            action: l10n.openSettings,
            onAction: () => ref.read(appSettingsProvider).open(),
            secondary: l10n.tryAgain,
            onSecondary: _tuner.start,
          ),
          _ when firstTime => _Message(
            icon: Icons.mic_none_outlined,
            title: l10n.tunerIntroTitle,
            body: l10n.tunerIntroBody,
            action: l10n.startTuner,
            onAction: _tuner.start,
          ),
          _ => _TunerBody(state: state),
        },
      ),
    );
  }

  Future<void> _showA4Sheet(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const _A4Sheet(),
  );
}

class _TunerBody extends ConsumerWidget {
  const _TunerBody({required this.state});

  final TunerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final tuner = ref.read(tunerProvider.notifier);
    final reading = state.reading;
    final target =
        reading?.target ??
        (state.lockedString == null
            ? null
            : state.tuning.strings[state.lockedString!]);
    final statusColor = reading == null
        ? colors.muted
        : state.inTune
        ? colors.good
        : colors.accent;
    final status = reading == null
        ? l10n.playAString
        : state.inTune || reading.withinTolerance
        ? l10n.inTune
        : reading.tooLow
        ? l10n.tooLow
        : l10n.tooHigh;
    final rounded = reading?.cents.round();
    final sign = switch (rounded) {
      null || 0 => '',
      > 0 => '+',
      _ => '−',
    };
    final centsText = rounded == null
        ? ''
        : l10n.centsOff('$sign${rounded.abs()}');

    // The note, the gauge and what to do.
    final readout = Semantics(
      liveRegion: true,
      label: [
        if (target != null) '${target.name}${target.octave}',
        status,
        centsText,
      ].where((s) => s.isNotEmpty).join(', '),
      child: ExcludeSemantics(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (target == null)
                  // Nothing to tune yet: show that the microphone hears.
                  _ListeningRing(level: state.level)
                else
                  Text(
                    _pretty(target.name),
                    style: AppFonts.displayStyle(104, statusColor),
                  ),
                if (target != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      '${target.octave}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: colors.muted,
                      ),
                    ),
                  ),
              ],
            ),
            Text(
              reading == null
                  ? ' '
                  : '${reading.frequency.toStringAsFixed(1)} Hz',
              style: TextStyle(fontSize: 16, color: colors.muted),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: TunerGauge(
                cents: reading?.cents,
                inTune: state.inTune,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              status,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
            Text(
              centsText,
              style: TextStyle(fontSize: 15, color: colors.muted),
            ),
          ],
        ),
      ),
    );

    // Under it, the strings to tune.
    final strings = [
      const SizedBox(height: 20),
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          Text(
            l10n.stringsLabel.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: colors.muted,
            ),
          ),
          FilterChip(
            label: Text(l10n.autoDetect),
            selected: state.lockedString == null,
            onSelected: (_) => tuner.autoDetect(),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          for (final (i, string) in state.tuning.strings.indexed) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: _StringButton(
                string: string,
                number: 6 - i,
                targeted:
                    state.lockedString == i ||
                    (state.lockedString == null && reading?.stringIndex == i),
                locked: state.lockedString == i,
                inTune: state.inTune && reading?.stringIndex == i,
                tuned: state.tuned.contains(i),
                onPressed: () => tuner.toggleString(i),
              ),
            ),
          ],
        ],
      ),
    ];

    // The strings stay at the bottom and the readout fills the room above,
    // shrinking on a short screen (a 16:9 phone) so the strings stay in
    // view while tuning. Too short even for that (a phone on its side):
    // scroll.
    return LayoutBuilder(
      builder: (context, constraints) {
        const padding = EdgeInsets.fromLTRB(20, 4, 20, 24);
        if (constraints.maxHeight < 420) {
          return ListView(
            padding: padding,
            children: [
              const _TuningMenu(),
              const SizedBox(height: 16),
              readout,
              if (state.allTuned) const _AllTunedCard(),
              ...strings,
            ],
          );
        }
        return Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _TuningMenu(),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: FittedBox(fit: BoxFit.scaleDown, child: readout),
                ),
              ),
              if (state.allTuned) const _AllTunedCard(),
              ...strings,
            ],
          ),
        );
      },
    );
  }
}

/// Kept apart from [_TunerBody], which rebuilds on every pitch reading:
/// rebuilding the menu that often recreates its items and swallows taps.
class _TuningMenu extends ConsumerWidget {
  const _TuningMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tuning = ref.watch(tunerProvider.select((s) => s.tuning));
    return DropdownMenu<Tuning>(
      expandedInsets: EdgeInsets.zero,
      label: Text(l10n.tuningLabel),
      initialSelection: tuning,
      onSelected: (tuning) {
        if (tuning != null) ref.read(tunerProvider.notifier).tuning = tuning;
      },
      dropdownMenuEntries: [
        for (final tuning in Tuning.values)
          DropdownMenuEntry(
            value: tuning,
            label: '${_tuningName(l10n, tuning)} · ${tuning.notes}',
          ),
      ],
    );
  }
}

/// A microphone with a soft ring that grows with the sound heard, so it's
/// clear the tuner is listening before a note is found.
class _ListeningRing extends StatelessWidget {
  const _ListeningRing({required this.level});

  final double level;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: 132,
      height: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(end: level),
            duration: const Duration(milliseconds: 150),
            builder: (context, level, _) => Container(
              width: 64 + 64 * level,
              height: 64 + 64 * level,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.accent.withValues(alpha: 0.10 + 0.20 * level),
              ),
            ),
          ),
          // Screen readers hear "Play a string" for the whole readout.
          Icon(Icons.mic_none_rounded, size: 36, color: colors.accent),
        ],
      ),
    );
  }
}

/// Every string has been in tune: on to the music.
class _AllTunedCard extends ConsumerWidget {
  const _AllTunedCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final last = ref.watch(recentSongsProvider).value?.firstOrNull;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: colors.good.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: colors.good),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.allTuned,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Flexible(
                child: TextButton(
                  onPressed: () => last == null
                      ? context.go(Routes.songbook)
                      : context.push(Routes.song(last.id)),
                  child: Text(
                    last == null
                        ? l10n.openSongbook
                        : l10n.playSong(last.title),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StringButton extends StatelessWidget {
  const _StringButton({
    required this.string,
    required this.number,
    required this.targeted,
    required this.locked,
    required this.inTune,
    required this.tuned,
    required this.onPressed,
  });

  final GuitarString string;

  /// Has been in tune this time: a check stays on it.
  final bool tuned;

  /// 6 = lowest string … 1 = highest.
  final int number;
  final bool targeted;
  final bool locked;
  final bool inTune;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final background = inTune
        ? colors.good
        : targeted
        ? colors.accent
        : colors.surface;
    final foreground = targeted || inTune ? colors.onAccent : colors.text;
    final ordinal = l10n.stringNumber('$number');
    return Semantics(
      button: true,
      selected: locked,
      label: [
        l10n.stringButton(ordinal, string.name),
        if (tuned) l10n.stringTuned,
      ].join(', '),
      excludeSemantics: true,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: targeted || inTune ? background : colors.line,
          ),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 64,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _pretty(string.name),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: foreground,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (tuned) ...[
                          Icon(
                            Icons.check,
                            size: 12,
                            color: targeted || inTune
                                ? foreground
                                : colors.good,
                          ),
                          const SizedBox(width: 2),
                        ],
                        Text(
                          ordinal,
                          style: TextStyle(fontSize: 11, color: foreground),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.onAction,
    this.secondary,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback onAction;
  final String? secondary;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(icon, size: 56, color: colors.muted),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, color: colors.muted),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: onAction, child: Text(action)),
            if (secondary case final label?) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: onSecondary, child: Text(label)),
            ],
          ],
        ),
      ),
    );
  }
}

class _A4Sheet extends ConsumerWidget {
  const _A4Sheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final a4 = ref.watch(tunerProvider.select((s) => s.a4));
    final tuner = ref.read(tunerProvider.notifier);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.a4Title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.a4Label(a4),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            Slider(
              value: a4.toDouble(),
              min: TunerController.minA4.toDouble(),
              max: TunerController.maxA4.toDouble(),
              divisions: TunerController.maxA4 - TunerController.minA4,
              label: '$a4 Hz',
              onChanged: (value) => tuner.a4 = value.round(),
            ),
            Text(
              l10n.a4Help,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.muted),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: a4 == 440 ? null : () => tuner.a4 = 440,
              child: Text(l10n.a4Reset),
            ),
          ],
        ),
      ),
    );
  }
}

String _tuningName(AppLocalizations l10n, Tuning tuning) => switch (tuning) {
  Tuning.standard => l10n.tuningStandard,
  Tuning.halfStepDown => l10n.tuningHalfStepDown,
  Tuning.dropD => l10n.tuningDropD,
  Tuning.dadgad => l10n.tuningDadgad,
  Tuning.openG => l10n.tuningOpenG,
  Tuning.openD => l10n.tuningOpenD,
};

/// E♭ and F♯ rather than Eb and F#.
String _pretty(String note) => note.replaceAll('#', '♯').replaceAll('b', '♭');
