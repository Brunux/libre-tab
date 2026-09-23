import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/app/settings/settings_store.dart';
import 'package:libre_tab/core/chordpro/chordpro_parser.dart';
import 'package:libre_tab/core/database/app_database.dart';
import 'package:libre_tab/core/music/chord_voicings.dart';
import 'package:libre_tab/features/library/data/song_repository.dart';
import 'package:libre_tab/features/library/data/starter_songs.dart';

import '../../helpers/test_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SongRepository songs;
  late StarterSongs starters;

  setUp(() {
    db = testDatabase();
    songs = SongRepository(db);
    starters = StarterSongs(songs, rootBundle);
  });
  tearDown(() => db.close());

  test(
    'every starter song is complete and every chord has a diagram',
    () async {
      final bodies = await starters.load();
      expect(bodies, hasLength(StarterSongs.files.length));
      for (final body in bodies) {
        final song = ChordProParser.parse(body);
        final title = song.title;
        expect(title, isNotEmpty);
        expect(song.artist, isNotEmpty, reason: '$title artist');
        expect(song.key, isNotNull, reason: '$title key');
        expect(song.blocks.length, greaterThan(1), reason: '$title sections');
        expect(song.chords, isNotEmpty, reason: '$title chords');
        for (final chord in song.chords) {
          expect(
            ChordVoicings.forSymbol(chord),
            isNotNull,
            reason: '$title: no diagram for $chord',
          );
        }
      }
    },
  );

  test('adds the missing ones only', () async {
    await songs.addSong(SampleSongs.amazingGrace);
    expect(await starters.addMissing(), StarterSongs.files.length - 1);
    expect(await starters.addMissing(), 0);
    expect(await songs.allSongs(), hasLength(StarterSongs.files.length));
  });

  test('the first launch fills an empty songbook, once', () async {
    final settings = MemorySettingsStore();
    await starters.addOnFirstLaunch(settings);
    expect(await songs.allSongs(), hasLength(StarterSongs.files.length));

    for (final song in await songs.allSongs()) {
      await songs.deleteSong(song.id);
    }
    await starters.addOnFirstLaunch(settings);
    expect(await songs.allSongs(), isEmpty);
  });

  test("an existing songbook (an update) doesn't get them", () async {
    await songs.addSong(SampleSongs.cancion);
    final settings = MemorySettingsStore();
    await starters.addOnFirstLaunch(settings);
    expect(await songs.allSongs(), hasLength(1));
    expect(settings.getInt(SettingsKeys.starterSongs), 1);
  });
}
