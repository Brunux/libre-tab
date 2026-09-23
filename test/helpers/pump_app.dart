import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/app/app.dart';
import 'package:libre_tab/app/router.dart';
import 'package:libre_tab/app/settings/settings_store.dart';
import 'package:libre_tab/core/database/database_provider.dart';
import 'package:libre_tab/core/device/keep_awake.dart';
import 'package:libre_tab/core/files/song_files.dart';
import 'package:libre_tab/features/library/data/song_repository.dart';
import 'package:libre_tab/features/tuner/data/pitch_source.dart';

import 'test_database.dart';

/// Pumps the whole app on an in-memory database, optionally seeded with
/// [songs] (ChordPro; ids are 1, 2, 3… in order). Returns the provider
/// container so tests can read state and drive the router.
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  List<String> songs = const [],
  FakeSongFiles? files,
  FakeKeepAwake? keepAwake,
  SettingsStore? settings,
  FakePitchSource? pitch,
  List<Override> overrides = const [],
}) async {
  final db = testDatabase();
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      songFilesProvider.overrideWithValue(files ?? FakeSongFiles()),
      keepAwakeProvider.overrideWithValue(keepAwake ?? FakeKeepAwake()),
      settingsStoreProvider.overrideWithValue(
        settings ?? MemorySettingsStore(),
      ),
      // Never the real microphone in tests.
      pitchSourceProvider.overrideWithValue(pitch ?? FakePitchSource()),
      ...overrides,
    ],
  );
  // Tear-downs run last-registered-first: dispose the providers (and their
  // open queries) before closing the database, or close() waits forever.
  addTearDown(db.close);
  addTearDown(container.dispose);
  final repository = container.read(songRepositoryProvider);
  for (final song in songs) {
    await repository.addSong(song);
  }
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const LibreTabApp(),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/// The router's current location. Pushed routes (Add song, Settings) don't
/// change it; check the screen instead.
String currentPath(ProviderContainer container) =>
    container.read(routerProvider).routerDelegate.currentConfiguration.uri.path;

Finder navItem(String label) =>
    find.widgetWithText(NavigationDestination, label);

/// Every screen and how to reach it once [SampleSongs.amazingGrace] is
/// song 1.
const Map<String, String> screenPaths = {
  'Songbook': Routes.songbook,
  'Tuner': Routes.tuner,
  'Settings': Routes.settings,
  'Add song': Routes.addSong,
  'Song view': '/songs/1',
  'Edit song': '/songs/1/edit',
  'Missing song': '/songs/999',
};

/// Records shares and returns a preset file for "Open file".
class FakeSongFiles implements SongFiles {
  FakeSongFiles({this.pickedText, this.pickError});

  /// What "Open file" returns; null means the user cancelled.
  String? pickedText;

  /// Thrown by "Open file" instead, e.g. a [FormatException].
  Exception? pickError;

  final shared = <({String title, String body})>[];

  @override
  Future<String?> pickSongText() async {
    if (pickError case final Exception error) throw error;
    return pickedText;
  }

  @override
  Future<void> share({required String title, required String body}) async =>
      shared.add((title: title, body: body));
}

/// Counts screen-awake requests like the real [KeepAwake].
class FakeKeepAwake implements KeepAwake {
  var _requests = 0;

  @override
  bool get awake => _requests > 0;

  @override
  Future<void> enable() async => _requests++;

  @override
  Future<void> disable() async {
    if (_requests > 0) _requests--;
  }
}

/// A microphone that "hears" whatever the test plays.
class FakePitchSource implements PitchSource {
  FakePitchSource({this.access = MicAccess.granted});

  MicAccess access;
  void Function(double?)? _onPitch;
  bool get listening => _onPitch != null;

  @override
  Future<MicAccess> start(void Function(double? frequency) onPitch) async {
    if (access == MicAccess.granted) _onPitch = onPitch;
    return access;
  }

  @override
  Future<void> stop() async => _onPitch = null;

  /// Delivers one detected frequency (null = silence), as the mic would.
  void hear(double? frequency) => _onPitch?.call(frequency);
}
