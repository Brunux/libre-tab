import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/core/database/app_database.dart';
import 'package:libre_tab/features/library/data/setlist_repository.dart';
import 'package:libre_tab/features/library/data/song_repository.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late SetlistRepository setlists;
  late SongRepository songs;
  late int grace;
  late int susanna;
  late int cancion;

  setUp(() async {
    db = testDatabase();
    setlists = SetlistRepository(db);
    songs = SongRepository(db);
    grace = await songs.addSong(SampleSongs.amazingGrace);
    susanna = await songs.addSong(SampleSongs.ohSusanna);
    cancion = await songs.addSong(SampleSongs.cancion);
  });
  tearDown(() => db.close());

  Future<List<String>> titles(int setlist) => setlists
      .watchSongs(setlist)
      .first
      .then((list) => [for (final s in list) s.title]);

  test('a new setlist is empty and listed with its song count', () async {
    final id = await setlists.create('  Friday campfire ');
    expect(await titles(id), isEmpty);
    await setlists.addSong(id, grace);
    expect(await setlists.watchSetlists().first, [
      SetlistSummary(id: id, name: 'Friday campfire', songCount: 1),
    ]);
  });

  test('songs play in the order they were added, without repeats', () async {
    final id = await setlists.create('Friday');
    await setlists.addSong(id, susanna);
    await setlists.addSong(id, grace);
    await setlists.addSong(id, susanna);
    expect(await titles(id), ['Oh! Susanna', 'Amazing Grace']);
  });

  test('songs can be moved and removed', () async {
    final id = await setlists.create('Friday');
    await setlists.setSongs(id, [grace, susanna, cancion]);

    await setlists.moveSong(id, 0, 2);
    expect(await titles(id), [
      'Oh! Susanna',
      'Canción de cuna',
      'Amazing Grace',
    ]);

    await setlists.moveSong(id, 2, 0);
    expect(await titles(id), [
      'Amazing Grace',
      'Oh! Susanna',
      'Canción de cuna',
    ]);

    await setlists.removeSong(id, susanna);
    expect(await titles(id), ['Amazing Grace', 'Canción de cuna']);
    expect(await setlists.songIds(id), [grace, cancion]);
  });

  test('deleting a song takes it out of every setlist', () async {
    final a = await setlists.create('A');
    final b = await setlists.create('B');
    await setlists.setSongs(a, [grace, susanna]);
    await setlists.setSongs(b, [susanna]);

    await songs.deleteSong(susanna);

    expect(await titles(a), ['Amazing Grace']);
    expect(await titles(b), isEmpty);
  });

  test('deleting a setlist keeps its songs in the songbook', () async {
    final id = await setlists.create('Friday');
    await setlists.setSongs(id, [grace, susanna]);
    await setlists.delete(id);

    expect(await setlists.watchSetlists().first, isEmpty);
    expect(await songs.watchSongs().first, hasLength(3));
    expect(await db.select(db.setlistSongs).get(), isEmpty);
  });

  test('knows which setlists have a song', () async {
    final a = await setlists.create('A');
    final b = await setlists.create('B');
    await setlists.addSong(a, grace);
    await setlists.addSong(b, susanna);
    expect(await setlists.watchSetlistsWith(grace).first, {a});
  });

  test('renames, and refuses empty names', () async {
    final id = await setlists.create('Friday');
    await setlists.rename(id, 'Saturday');
    expect((await setlists.watchSetlist(id).first)?.name, 'Saturday');
    await expectLater(setlists.create('   '), throwsArgumentError);
    await expectLater(setlists.rename(id, ''), throwsArgumentError);
  });

  test('search matches names ignoring case and accents', () async {
    await setlists.create('Noche de fogata');
    await setlists.create('Canciones de misa');
    await setlists.create('Fogáta del sábado');

    Future<List<String>> names(String q) => setlists
        .watchSetlists(query: q)
        .first
        .then((list) => [for (final s in list) s.name]);

    expect(await names('FOGATA'), ['Fogáta del sábado', 'Noche de fogata']);
    expect(await names('sabado'), ['Fogáta del sábado']);
    expect(await names(''), hasLength(3));
  });
}
