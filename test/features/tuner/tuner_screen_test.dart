import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/app/router.dart';
import 'package:libre_tab/app/settings/settings_store.dart';
import 'package:libre_tab/core/music/tunings.dart';
import 'package:libre_tab/features/library/data/song_repository.dart';
import 'package:libre_tab/features/song_view/presentation/song_view_screen.dart';
import 'package:libre_tab/features/tuner/application/tuner_controller.dart';
import 'package:libre_tab/features/tuner/data/pitch_source.dart';
import 'package:libre_tab/features/tuner/presentation/widgets/tuner_gauge.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_database.dart';

/// A fake clock the tuner reads for its 300 ms "in tune" hold.
Duration now = Duration.zero;

Future<(ProviderContainer, FakePitchSource)> openTuner(
  WidgetTester tester, {
  bool askedBefore = true,
  MicAccess access = MicAccess.granted,
  SettingsStore? settings,
  FakeKeepAwake? keepAwake,
  FakeAppSettings? appSettings,
  List<String> songs = const [],
}) async {
  now = Duration.zero;
  final pitch = FakePitchSource(access: access);
  final store =
      settings ??
      MemorySettingsStore({if (askedBefore) SettingsKeys.micAsked: 1});
  final container = await pumpApp(
    tester,
    pitch: pitch,
    settings: store,
    keepAwake: keepAwake,
    appSettings: appSettings,
    songs: songs,
    overrides: [tunerClockProvider.overrideWithValue(() => now)],
  );
  await tester.tap(navItem('Tuner'));
  await tester.pumpAndSettle();
  return (container, pitch);
}

/// Plays [hz] for [times] readings, 50 ms apart.
Future<void> hear(
  WidgetTester tester,
  FakePitchSource pitch,
  double? hz, {
  int times = 1,
}) async {
  for (var i = 0; i < times; i++) {
    pitch.hear(hz);
    now += const Duration(milliseconds: 50);
  }
  await tester.pumpAndSettle();
}

/// Scrolls the string buttons into view (below the fold in the 800×600
/// test window), then taps the one with this accessible label.
Future<void> tapString(WidgetTester tester, String label) async {
  await tester.dragUntilVisible(
    find.bySemanticsLabel(label),
    find.byType(ListView),
    const Offset(0, -200),
  );
  await tester.tap(find.bySemanticsLabel(label));
  await tester.pumpAndSettle();
}

/// Scrolls down to the string buttons (below [chipLabel], the chip beside
/// them).
Future<void> scrollToStrings(WidgetTester tester, String chipLabel) async {
  // Only a very short screen scrolls; otherwise the strings are in view.
  if (find.byType(ListView).evaluate().isEmpty) return;
  await tester.dragUntilVisible(
    find.text(chipLabel),
    find.byType(ListView),
    const Offset(0, -200),
  );
  await tester.dragUntilVisible(
    find.bySemanticsLabel(RegExp('^6(th string|ª cuerda)')),
    find.byType(ListView),
    const Offset(0, -100),
  );
}

void main() {
  group('microphone permission', () {
    testWidgets('the first visit explains before asking', (tester) async {
      final settings = MemorySettingsStore();
      final (_, pitch) = await openTuner(
        tester,
        askedBefore: false,
        settings: settings,
      );
      expect(find.text('Tune your guitar'), findsOneWidget);
      expect(find.textContaining('Nothing is recorded'), findsOneWidget);
      expect(pitch.listening, isFalse);

      await tester.tap(find.text('Start tuner'));
      await tester.pumpAndSettle();
      expect(pitch.listening, isTrue);
      expect(find.text('Play a string'), findsOneWidget);
      expect(settings.getInt(SettingsKeys.micAsked), 1);
    });

    testWidgets('refused: opens Settings, and can try again', (
      tester,
    ) async {
      final settings = FakeAppSettings();
      final (_, pitch) = await openTuner(
        tester,
        access: MicAccess.denied,
        appSettings: settings,
      );
      expect(find.text('The microphone is off'), findsOneWidget);
      expect(find.textContaining('Allow it for Libre Tab'), findsOneWidget);

      // The system won't ask twice: go straight to the app's settings.
      await tester.tap(find.text('Open Settings'));
      await tester.pump();
      expect(settings.opened, 1);

      pitch.access = MicAccess.granted;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(pitch.listening, isTrue);
      expect(find.text('Play a string'), findsOneWidget);
    });
  });

  group('after a refusal', () {
    Future<void> leaveAndComeBack(WidgetTester tester) async {
      tester.binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
        ..handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
    }

    testWidgets('coming back never asks again (no prompt loop)', (
      tester,
    ) async {
      final (_, pitch) = await openTuner(tester, access: MicAccess.denied);
      final asked = pitch.asks;
      // On Android the permission screen itself pauses and resumes the app.
      for (var i = 0; i < 3; i++) {
        await leaveAndComeBack(tester);
      }
      expect(pitch.asks, asked);
      expect(find.text('The microphone is off'), findsOneWidget);
    });

    testWidgets('allowed in Settings: coming back starts the tuner', (
      tester,
    ) async {
      final (_, pitch) = await openTuner(tester, access: MicAccess.denied);
      final asked = pitch.asks;
      pitch.access = MicAccess.granted; // the user allowed it in Settings
      await leaveAndComeBack(tester);
      expect(pitch.listening, isTrue);
      expect(pitch.asks, asked, reason: 'checked, not asked');
      expect(find.text('Play a string'), findsOneWidget);
    });
  });

  group('listening only while the tuner is on screen', () {
    testWidgets('starts on the tab, stops when leaving it', (tester) async {
      final (_, pitch) = await openTuner(tester);
      expect(pitch.listening, isTrue);

      await tester.tap(navItem('Songbook'));
      await tester.pumpAndSettle();
      expect(pitch.listening, isFalse);

      await tester.tap(navItem('Tuner'));
      await tester.pumpAndSettle();
      expect(pitch.listening, isTrue);
    });

    testWidgets('stops when the app goes to the background', (tester) async {
      final (_, pitch) = await openTuner(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();
      expect(pitch.listening, isFalse);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(pitch.listening, isTrue);
    });

    testWidgets('keeps the screen on, and never switches it off under a '
        'song opened on top', (tester) async {
      final keepAwake = FakeKeepAwake();
      final (container, _) = await openTuner(
        tester,
        keepAwake: keepAwake,
        songs: [SampleSongs.amazingGrace],
      );
      expect(keepAwake.awake, isTrue);

      container.read(routerProvider).go(Routes.song(1));
      await tester.pumpAndSettle();
      expect(keepAwake.awake, isTrue, reason: 'the song needs it');

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(keepAwake.awake, isFalse, reason: 'songbook tab: nobody needs it');
    });
  });

  group('readings', () {
    testWidgets('a flat A string: note, Hz, direction and cents', (
      tester,
    ) async {
      final (_, pitch) = await openTuner(tester);
      await hear(tester, pitch, 108, times: 3);

      expect(find.text('A'), findsWidgets); // big note + string button
      expect(find.text('108.0 Hz'), findsOneWidget);
      expect(find.text('Too low · tighten'), findsOneWidget);
      expect(find.text('−32 cents'), findsOneWidget);
    });

    testWidgets('sharp reads "Too high · loosen"', (tester) async {
      final (_, pitch) = await openTuner(tester);
      await hear(tester, pitch, 112, times: 3);
      expect(find.text('Too high · loosen'), findsOneWidget);
      expect(find.text('+31 cents'), findsOneWidget);
    });

    testWidgets('in tune after 300 ms in the zone, with one buzz', (
      tester,
    ) async {
      final haptics = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add('${call.arguments}');
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      final (container, pitch) = await openTuner(tester);
      await hear(tester, pitch, 110.2, times: 3); // 100 ms: not yet
      expect(container.read(tunerProvider).inTune, isFalse);

      await hear(tester, pitch, 110.2, times: 6); // past 300 ms
      expect(container.read(tunerProvider).inTune, isTrue);
      expect(find.text('In tune'), findsOneWidget);
      expect(haptics, hasLength(1));

      await hear(tester, pitch, 110.2, times: 4); // stays in tune
      expect(haptics, hasLength(1), reason: 'one buzz, not one per frame');
    });

    testWidgets('silence clears the reading', (tester) async {
      final (_, pitch) = await openTuner(tester);
      await hear(tester, pitch, 108, times: 2);
      await hear(tester, pitch, null);
      expect(find.text('Play a string'), findsOneWidget);
      expect(find.text('108.0 Hz'), findsNothing);
    });
  });

  group('listening and tuned strings', () {
    /// Standard tuning, low E to high E.
    const standard = [82.41, 110.0, 146.83, 196.0, 246.94, 329.63];

    Future<void> tuneString(
      WidgetTester tester,
      FakePitchSource pitch,
      double hz,
    ) async {
      await hear(tester, pitch, hz, times: 8); // held past 300 ms
      await hear(tester, pitch, null, times: 2);
    }

    testWidgets('before a note, a ring shows the tuner hears', (
      tester,
    ) async {
      final (container, pitch) = await openTuner(tester);
      expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);

      pitch.hear(null, level: 0.4);
      await tester.pumpAndSettle();
      expect(container.read(tunerProvider).level, closeTo(0.4, 0.01));
      // It falls back gently, not at once.
      pitch.hear(null, level: 0);
      await tester.pumpAndSettle();
      expect(container.read(tunerProvider).level, closeTo(0.28, 0.01));

      await hear(tester, pitch, 110, times: 3);
      expect(find.byIcon(Icons.mic_none_rounded), findsNothing);
    });

    testWidgets('a string that was in tune keeps a check', (tester) async {
      final (container, pitch) = await openTuner(tester);
      await tuneString(tester, pitch, 110);
      expect(container.read(tunerProvider).tuned, {1});
      await scrollToStrings(tester, 'Auto-detect');
      expect(find.bySemanticsLabel('5th string, A, tuned'), findsOneWidget);
      expect(find.bySemanticsLabel('6th string, E'), findsOneWidget);
    });

    testWidgets('all six tuned: on to the last song played', (tester) async {
      final (container, pitch) = await openTuner(
        tester,
        songs: [SampleSongs.amazingGrace],
      );
      await container.read(songRepositoryProvider).recordOpened(1);
      for (final hz in standard) {
        await tuneString(tester, pitch, hz);
      }
      expect(container.read(tunerProvider).allTuned, isTrue);
      expect(find.text("All tuned — let's play!"), findsOneWidget);

      await tester.ensureVisible(find.text('Play Amazing Grace'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Play Amazing Grace'));
      await tester.pumpAndSettle();
      expect(find.byType(SongViewScreen), findsOneWidget);
      expect(find.text('John Newton · Key G'), findsOneWidget);
    });

    testWidgets('a new tuning starts the checks over', (tester) async {
      final (container, pitch) = await openTuner(tester);
      await tuneString(tester, pitch, 110);
      container.read(tunerProvider.notifier).tuning = Tuning.dropD;
      expect(container.read(tunerProvider).tuned, isEmpty);
    });

    test('input level: silence 0, a quiet room low, a string high', () {
      expect(MicPitchSource.levelOf(List.filled(4096, 0)), 0);
      expect(MicPitchSource.levelOf(List.filled(4096, 0.0005)), lessThan(0.2));
      expect(MicPitchSource.levelOf(List.filled(4096, 0.3)), 1);
    });
  });

  group('strings, tunings and reference pitch', () {
    testWidgets('on a short 16:9 phone the gauge shrinks to fit the strings', (
      tester,
    ) async {
      // 1080 × 1920 at 3×: 360 × 640 points.
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await openTuner(tester);

      // Drawn smaller (the readout is scaled down), not its full 320.
      expect(tester.getRect(find.byType(TunerGauge)).width, lessThan(300));
      final screen = tester.getRect(find.byType(Scaffold).first);
      for (final label in ['6th string, E', '1st string, E']) {
        final button = tester.getRect(find.bySemanticsLabel(label));
        expect(screen.contains(button.bottomRight), isTrue, reason: label);
      }
    });

    testWidgets('locking a string measures everything against it', (
      tester,
    ) async {
      final (container, pitch) = await openTuner(tester);
      await tapString(tester, '6th string, E');
      expect(container.read(tunerProvider).lockedString, 0);

      await hear(tester, pitch, 110, times: 2);
      expect(find.text('Too high · loosen'), findsOneWidget); // A vs low E

      await tester.tap(find.text('Auto-detect'));
      await tester.pumpAndSettle();
      expect(container.read(tunerProvider).lockedString, isNull);
      await hear(tester, pitch, 110, times: 2);
      expect(find.text('Too high · loosen'), findsNothing);
    });

    testWidgets('tapping the locked string again goes back to auto', (
      tester,
    ) async {
      final (container, _) = await openTuner(tester);
      await tapString(tester, '1st string, E');
      expect(container.read(tunerProvider).lockedString, 5);
      await tapString(tester, '1st string, E');
      expect(container.read(tunerProvider).lockedString, isNull);
    });

    testWidgets('choosing Drop D changes the strings and is remembered', (
      tester,
    ) async {
      final settings = MemorySettingsStore({SettingsKeys.micAsked: 1});
      await openTuner(tester, settings: settings);

      await tester.tap(find.byType(DropdownMenu<Tuning>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Drop D · D A D G B E').last);
      await tester.pumpAndSettle();

      await scrollToStrings(tester, 'Auto-detect');
      expect(find.bySemanticsLabel('6th string, D'), findsOneWidget);
      expect(settings.getString(SettingsKeys.tuning), 'dropD');
    });

    testWidgets('a tuning can be picked while the tuner is hearing a string', (
      tester,
    ) async {
      final (container, pitch) = await openTuner(tester);
      await hear(tester, pitch, 110);

      await tester.tap(find.byType(DropdownMenu<Tuning>));
      await tester.pumpAndSettle();
      // A reading lands between finger down and finger up.
      final press = await tester.startGesture(
        tester.getCenter(find.text('Drop D · D A D G B E').last),
      );
      await hear(tester, pitch, 111);
      await press.up();
      await tester.pumpAndSettle();

      expect(container.read(tunerProvider).tuning, Tuning.dropD);
    });

    testWidgets('changing A4 to 432 Hz is shown and remembered', (
      tester,
    ) async {
      final settings = MemorySettingsStore({SettingsKeys.micAsked: 1});
      final (container, pitch) = await openTuner(tester, settings: settings);
      await hear(tester, pitch, 110, times: 2);
      expect(find.text('0 cents'), findsOneWidget);

      await tester.tap(find.text('A4 = 440 Hz'));
      await tester.pumpAndSettle();
      container.read(tunerProvider.notifier).a4 = 432;
      await tester.pumpAndSettle();

      expect(find.text('A4 = 432 Hz'), findsWidgets);
      expect(settings.getInt(SettingsKeys.a4), 432);
      // The sound still playing is measured against the new reference.
      expect(find.text('+32 cents'), findsOneWidget);

      await tester.tap(find.text('Back to 440'));
      await tester.pumpAndSettle();
      expect(container.read(tunerProvider).a4, 440);
    });

    testWidgets('saved tuning and A4 are used on the next launch', (
      tester,
    ) async {
      final (container, _) = await openTuner(
        tester,
        settings: MemorySettingsStore({
          SettingsKeys.micAsked: 1,
          SettingsKeys.tuning: 'openG',
          SettingsKeys.a4: 442,
        }),
      );
      final state = container.read(tunerProvider);
      expect(state.tuning, Tuning.openG);
      expect(state.a4, 442);
      expect(find.text('A4 = 442 Hz'), findsOneWidget);
    });
  });

  testWidgets('the whole tuner fits a small phone with 200% text', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(320, 568)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final (_, pitch) = await openTuner(tester);
    await hear(tester, pitch, 108, times: 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Spanish tuner', (tester) async {
    tester.platformDispatcher.localesTestValue = [const Locale('es')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    now = Duration.zero;
    final pitch = FakePitchSource();
    await pumpApp(
      tester,
      pitch: pitch,
      settings: MemorySettingsStore({SettingsKeys.micAsked: 1}),
      overrides: [tunerClockProvider.overrideWithValue(() => now)],
    );
    await tester.tap(navItem('Afinador'));
    await tester.pumpAndSettle();
    await hear(tester, pitch, 108, times: 3);

    expect(find.text('Muy baja · aprieta'), findsOneWidget);
    expect(find.text('La4 = 440 Hz'), findsOneWidget);
    await scrollToStrings(tester, 'Detección automática');
    expect(find.text('Detección automática'), findsOneWidget);
    expect(find.bySemanticsLabel('6ª cuerda, E'), findsOneWidget);
  });
}
