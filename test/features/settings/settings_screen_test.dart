import 'dart:async';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/app/router.dart';
import 'package:libre_tab/features/library/data/song_repository.dart';
import 'package:libre_tab/features/library/data/songbook_archive.dart';
import 'package:libre_tab/features/library/data/starter_songs.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_database.dart';

Future<void> openSettings(WidgetTester tester, ProviderContainer c) async {
  unawaited(c.read(routerProvider).push(Routes.settings));
  await tester.pumpAndSettle();
}

/// Starter songs are read from the asset bundle: real file reads, which
/// fake-time pumping never finishes. Let real time pass until [finder]
/// shows up.
Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(finder, findsOneWidget);
}

/// Scrolls the settings list until [text]'s tile is fully on screen.
Future<void> showTile(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(find.text(text), 100);
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
}

Future<int> songCount(ProviderContainer c) =>
    c.read(songRepositoryProvider).allSongs().then((s) => s.length);

void main() {
  testWidgets('Export all songs shares a zip with every song', (tester) async {
    final files = FakeSongFiles();
    final container = await pumpApp(
      tester,
      files: files,
      songs: [SampleSongs.amazingGrace, SampleSongs.cancion],
    );
    await openSettings(tester, container);

    await tester.tap(find.text('Export all songs'));
    await tester.pumpAndSettle();

    final MapEntry(key: name, value: zip) = files.exports.entries.single;
    expect(name, matches(RegExp(r'^libre-tab-songs-\d{4}-\d{2}-\d{2}\.zip$')));
    expect(
      [for (final f in ZipDecoder().decodeBytes(zip)) f.name],
      ['Amazing Grace.cho', 'Canción de cuna.cho'],
    );
  });

  testWidgets('exporting an empty songbook says so', (tester) async {
    final files = FakeSongFiles();
    final container = await pumpApp(tester, files: files);
    await openSettings(tester, container);

    await tester.tap(find.text('Export all songs'));
    await tester.pumpAndSettle();
    expect(files.exports, isEmpty);
    expect(find.textContaining("There's nothing to export"), findsOneWidget);
  });

  testWidgets('Import songs adds a zip once, not twice', (tester) async {
    final zip = SongbookArchive.export([
      (title: 'Amazing Grace', body: SampleSongs.amazingGrace),
      (title: 'Oh! Susanna', body: SampleSongs.ohSusanna),
    ]);
    final files = FakeSongFiles()
      ..pickedFile = (name: 'backup.zip', bytes: zip);
    final container = await pumpApp(tester, files: files);
    await openSettings(tester, container);

    await tester.tap(find.text('Import songs'));
    await tester.pumpAndSettle();
    expect(find.text('2 songs added.'), findsOneWidget);
    expect(await songCount(container), 2);

    ScaffoldMessenger.of(
      tester.element(find.text('Import songs')),
    ).removeCurrentSnackBar();
    await tester.tap(find.text('Import songs'));
    await tester.pumpAndSettle();
    expect(find.text('No songs found in that file.'), findsOneWidget);
    expect(await songCount(container), 2);
  });

  testWidgets('Import songs takes a single song file too', (tester) async {
    final files = FakeSongFiles()
      ..pickedFile = (
        name: 'grace.cho',
        bytes: utf8.encode(SampleSongs.amazingGrace),
      );
    final container = await pumpApp(tester, files: files);
    await openSettings(tester, container);
    await tester.tap(find.text('Import songs'));
    await tester.pumpAndSettle();
    expect(find.text('1 song added.'), findsOneWidget);
    expect(await songCount(container), 1);
  });

  testWidgets('importing a file that is not a song says so', (tester) async {
    final files = FakeSongFiles()
      ..pickedFile = (name: 'photo.jpg', bytes: utf8.encode('jpg'));
    final container = await pumpApp(tester, files: files);
    await openSettings(tester, container);
    await tester.tap(find.text('Import songs'));
    await tester.pumpAndSettle();
    expect(find.textContaining("That file isn't a song"), findsOneWidget);
  });

  testWidgets('Add starter songs adds only the missing ones', (tester) async {
    final container = await pumpApp(tester, songs: [SampleSongs.amazingGrace]);
    await openSettings(tester, container);

    await tester.tap(find.text('Add starter songs'));
    final added = StarterSongs.files.length - 1;
    await pumpUntilFound(tester, find.text('$added starter songs added.'));
    expect(await songCount(container), StarterSongs.files.length);
  });

  testWidgets('the empty songbook offers the starter songs', (tester) async {
    final container = await pumpApp(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Add starter songs'));
    await pumpUntilFound(tester, find.text('7 starter songs added.'));

    expect(await songCount(container), StarterSongs.files.length);
    expect(find.text('Amazing Grace'), findsOneWidget);
    expect(find.text('Cielito Lindo'), findsOneWidget);
  });

  testWidgets('About shows the license and opens the licenses page', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    await openSettings(tester, container);
    await showTile(tester, 'Licenses');
    expect(find.textContaining('GNU GPL 3.0 or later'), findsOneWidget);

    await tester.tap(find.text('Licenses'));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });

  group('Delete all songs', () {
    Future<void> openDeleteAll(WidgetTester tester) async {
      await tester.scrollUntilVisible(find.text('Delete all songs'), 100);
      await tester.tap(find.text('Delete all songs'));
      await tester.pumpAndSettle();
    }

    testWidgets('is off when the songbook is empty', (tester) async {
      final container = await pumpApp(tester);
      await openSettings(tester, container);
      await tester.scrollUntilVisible(find.text('Delete all songs'), 100);
      final tile = tester.widget<ListTile>(
        find.widgetWithText(ListTile, 'Delete all songs'),
      );
      expect(tile.enabled, isFalse);
    });

    testWidgets('says how many, and Cancel keeps everything', (tester) async {
      final container = await pumpApp(
        tester,
        songs: [SampleSongs.amazingGrace, SampleSongs.cancion],
      );
      await openSettings(tester, container);
      await openDeleteAll(tester);

      expect(find.text('Delete all 2 songs?'), findsOneWidget);
      expect(
        find.textContaining('setlists will be left empty'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await songCount(container), 2);
    });

    testWidgets('Export first exports and deletes nothing', (tester) async {
      final files = FakeSongFiles();
      final container = await pumpApp(
        tester,
        files: files,
        songs: [SampleSongs.amazingGrace],
      );
      await openSettings(tester, container);
      await openDeleteAll(tester);
      await tester.tap(find.text('Export first'));
      await tester.pumpAndSettle();

      expect(files.exports, hasLength(1));
      expect(await songCount(container), 1);
    });

    testWidgets('Delete all empties the songbook; Undo restores it', (
      tester,
    ) async {
      final container = await pumpApp(
        tester,
        songs: [SampleSongs.amazingGrace, SampleSongs.cancion],
      );
      await openSettings(tester, container);
      await openDeleteAll(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete all'));
      await tester.pumpAndSettle();

      expect(await songCount(container), 0);
      expect(find.text('2 songs deleted.'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(await songCount(container), 2);
    });
  });

  group('Find duplicates', () {
    const grace = SampleSongs.amazingGrace;
    const graceCopy = '$grace\n\n';
    final graceInA = grace.replaceAll('[G]', '[A]');

    Future<void> openDuplicates(WidgetTester tester) async {
      await tester.tap(find.text('Find duplicates'));
      await tester.pumpAndSettle();
    }

    testWidgets('lists copies and versions; Remove, then Undo', (tester) async {
      final container = await pumpApp(
        tester,
        songs: [grace, graceCopy, graceInA, SampleSongs.ohSusanna],
      );
      await openSettings(tester, container);
      await openDuplicates(tester);

      expect(find.text('EXACT COPIES'), findsOneWidget);
      expect(find.text('John Newton · 1 copy'), findsOneWidget);
      expect(find.text('SAME TITLE, DIFFERENT TEXT'), findsOneWidget);

      await tester.tap(find.text('Remove 1 copy'));
      await tester.pumpAndSettle();
      expect(find.text('1 copy removed.'), findsOneWidget);
      expect(await songCount(container), 3);
      expect(find.text('EXACT COPIES'), findsNothing);
      expect(find.text('SAME TITLE, DIFFERENT TEXT'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(await songCount(container), 4);
      expect(find.text('EXACT COPIES'), findsOneWidget);
    });

    testWidgets('a songbook without duplicates says so', (tester) async {
      final container = await pumpApp(
        tester,
        songs: [grace, SampleSongs.ohSusanna],
      );
      await openSettings(tester, container);
      await openDuplicates(tester);
      expect(find.text('No duplicates found.'), findsOneWidget);
    });
  });

  testWidgets('Privacy is one tap away, and works offline', (tester) async {
    final container = await pumpApp(tester);
    await openSettings(tester, container);
    await showTile(tester, 'Privacy');
    await tester.tap(find.text('Privacy'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Libre Tab collects no data'), findsOneWidget);
    expect(find.text('Microphone'), findsOneWidget);
    expect(find.text('Camera and photos'), findsOneWidget);
    await tester.dragUntilVisible(
      find.byType(SelectableText),
      find.byType(ListView),
      const Offset(0, -200),
    );
    final link = tester.widget<SelectableText>(find.byType(SelectableText));
    expect(link.data, endsWith('PRIVACY.md'));
    // Nothing here names another platform (App Store guideline 2.3.10).
    expect(find.textContaining('Android'), findsNothing);
  });
}
