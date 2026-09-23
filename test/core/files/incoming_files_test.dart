import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/core/files/incoming_files.dart';
import 'package:libre_tab/features/editor/presentation/song_editor_screen.dart';
import 'package:libre_tab/features/library/data/song_repository.dart';
import 'package:libre_tab/features/library/data/songbook_archive.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChannelIncomingFiles', () {
    const channel = MethodChannel('libre_tab/incoming_files');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    late List<Map<String, Object>> pending;

    setUp(() {
      pending = [];
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method != 'takePending') return null;
        final taken = pending;
        pending = [];
        return taken;
      });
    });
    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    Map<String, Object> file(String name, String text) => {
      'name': name,
      'bytes': Uint8List.fromList(utf8.encode(text)),
    };

    test('delivers the file the app was launched with', () async {
      pending = [file('grace.cho', '{title: Amazing Grace}')];
      final received = <ReceivedFile>[];
      ChannelIncomingFiles().listen(received.add);
      await pumpEventQueue();

      expect(received.single.name, 'grace.cho');
      expect(utf8.decode(received.single.bytes), '{title: Amazing Grace}');
    });

    test('collects files announced later', () async {
      final received = <ReceivedFile>[];
      final files = ChannelIncomingFiles()..listen(received.add);
      await pumpEventQueue();
      expect(received, isEmpty);

      pending = [file('a.cho', 'A'), file('b.crd', 'B')];
      await messenger.handlePlatformMessage(
        channel.name,
        channel.codec.encodeMethodCall(const MethodCall('filesAvailable')),
        (_) {},
      );
      await pumpEventQueue();
      expect([for (final f in received) f.name], ['a.cho', 'b.crd']);

      files.dispose();
    });

    test('no host side is not an error', () async {
      messenger.setMockMethodCallHandler(channel, null);
      final received = <ReceivedFile>[];
      ChannelIncomingFiles().listen(received.add);
      await pumpEventQueue();
      expect(received, isEmpty);
    });
  });

  group('opening a file from another app', () {
    testWidgets('a song file opens in Add song, filled in', (tester) async {
      final incoming = FakeIncomingFiles();
      final container = await pumpApp(tester, incoming: incoming);
      final songs = container.read(songRepositoryProvider);

      incoming.send('grace.cho', SampleSongs.amazingGrace);
      await tester.pumpAndSettle();

      expect(find.byType(SongEditorScreen), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Amazing Grace'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'John Newton'), findsOneWidget);
      // Nothing is saved until Save.
      expect(await songs.getSong(1), isNull);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect((await songs.getSong(1))?.title, 'Amazing Grace');
    });

    testWidgets('chords-over-lyrics text files work too', (tester) async {
      final incoming = FakeIncomingFiles();
      await pumpApp(tester, incoming: incoming);

      incoming.send('song.TXT', 'G       C\nHello campfire');
      await tester.pumpAndSettle();

      expect(find.byType(SongEditorScreen), findsOneWidget);
      expect(find.textContaining('Chord lines placed: 1'), findsOneWidget);
    });

    testWidgets('a songbook zip is imported', (tester) async {
      final incoming = FakeIncomingFiles();
      final container = await pumpApp(tester, incoming: incoming);
      final zip = SongbookArchive.export([
        (title: 'Amazing Grace', body: SampleSongs.amazingGrace),
        (title: 'Oh! Susanna', body: SampleSongs.ohSusanna),
      ]);

      incoming.sendBytes('backup.zip', zip);
      await tester.pumpAndSettle();

      expect(find.text('2 songs added.'), findsOneWidget);
      final songs = container.read(songRepositoryProvider);
      expect(await songs.allSongs(), hasLength(2));
    });

    testWidgets("other files say they aren't songs", (tester) async {
      final incoming = FakeIncomingFiles();
      await pumpApp(tester, incoming: incoming);

      incoming.send('photo.jpg', 'not a song');
      await tester.pumpAndSettle();

      expect(find.byType(SongEditorScreen), findsNothing);
      expect(find.textContaining("That file isn't a song"), findsOneWidget);
    });
  });
}
