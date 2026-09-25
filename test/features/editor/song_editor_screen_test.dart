import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/app/router.dart';
import 'package:libre_tab/core/files/photo_picker.dart';
import 'package:libre_tab/core/files/song_files.dart';
import 'package:libre_tab/core/ocr/ocr_layout.dart';
import 'package:libre_tab/core/ocr/text_recognizer.dart';
import 'package:libre_tab/features/editor/presentation/song_editor_screen.dart';
import 'package:libre_tab/features/library/data/song_repository.dart';
import 'package:libre_tab/features/library/presentation/library_screen.dart';
import 'package:libre_tab/features/song_view/presentation/song_view_screen.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_database.dart';

Finder get titleField => find.widgetWithText(TextField, 'Title');
Finder get artistField => find.widgetWithText(TextField, 'Artist');
Finder get contentField => find.byType(TextField).at(2);

FilledButton saveButton(WidgetTester tester) =>
    tester.widget(find.widgetWithText(FilledButton, 'Save'));

Future<ProviderContainer> openEditor(
  WidgetTester tester, {
  FakeSongFiles? files,
}) async {
  final container = await pumpApp(tester, files: files);
  await tester.tap(find.text('Add song'));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('paste a chord sheet, preview it, add a title, save', (
    tester,
  ) async {
    final container = await openEditor(tester);
    // Nothing yet: the ways to bring a song in, big.
    expect(find.text('Copied from a website or a note'), findsOneWidget);

    await tester.enterText(contentField, '     G\nThat saved a wretch');
    await tester.pumpAndSettle();
    expect(
      find.text('Chord lines placed: 1 · Sections found: 0'),
      findsOneWidget,
    );
    // With text, the cards step down to buttons.
    expect(find.text('Copied from a website or a note'), findsNothing);
    expect(find.text('Add a title'), findsOneWidget);

    await tester.tap(find.text('Preview'));
    await tester.pumpAndSettle();
    expect(find.text('G'), findsOneWidget); // preview chord
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(saveButton(tester).onPressed, isNull);

    await tester.enterText(titleField, 'Grace');
    await tester.enterText(artistField, 'John Newton');
    await tester.pumpAndSettle();
    expect(find.text('Add a title'), findsNothing);
    expect(saveButton(tester).onPressed, isNotNull);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.byType(SongViewScreen), findsOneWidget);
    // No {key} given: it's guessed from the first chord.
    expect(find.text('John Newton · Key G'), findsOneWidget);
    final saved = await container.read(songRepositoryProvider).getSong(1);
    expect(
      saved!.body,
      '{title: Grace}\n{artist: John Newton}\n\nThat [G]saved a wretch',
    );
  });

  group('Paste', () {
    void clipboard(WidgetTester tester, String? text) {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => call.method == 'Clipboard.getData'
            ? (text == null ? null : {'text': text})
            : null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
    }

    testWidgets('puts a copied song in, like a file', (tester) async {
      await openEditor(tester);
      clipboard(tester, '{title: Grace}\n{artist: Newton}\n[G]Amazing');
      await tester.tap(find.text('Paste'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(titleField).controller!.text, 'Grace');
      expect(tester.widget<TextField>(artistField).controller!.text, 'Newton');
      expect(
        tester.widget<TextField>(contentField).controller!.text,
        '[G]Amazing',
      );
    });

    testWidgets('more than a song could be is refused', (tester) async {
      await openEditor(tester);
      clipboard(tester, 'la ' * SongFiles.maxSongBytes);
      await tester.tap(find.text('Paste'));
      await tester.pumpAndSettle();
      expect(find.text("That's too much text for one song."), findsOneWidget);
      expect(tester.widget<TextField>(contentField).controller!.text, isEmpty);
    });

    testWidgets('an empty clipboard says so', (tester) async {
      await openEditor(tester);
      clipboard(tester, null);
      await tester.tap(find.text('Paste'));
      await tester.pumpAndSettle();
      expect(find.text('Nothing to paste. Copy a song first.'), findsOneWidget);
    });
  });

  testWidgets('title and artist stop at a sensible length', (tester) async {
    await openEditor(tester);
    await tester.enterText(titleField, 'x' * 1000);
    await tester.enterText(artistField, 'y' * 1000);
    await tester.pump();
    expect(
      tester.widget<TextField>(titleField).controller!.text,
      hasLength(SongFiles.maxNameChars),
    );
    expect(
      tester.widget<TextField>(artistField).controller!.text,
      hasLength(SongFiles.maxNameChars),
    );
  });

  testWidgets('the ChordPro tab shows exactly what will be saved', (
    tester,
  ) async {
    await openEditor(tester);
    await tester.enterText(titleField, 'T');
    await tester.enterText(contentField, 'C\nHi');
    await tester.pumpAndSettle();

    await tester.tap(find.text('ChordPro'));
    await tester.pumpAndSettle();
    expect(find.text('{title: T}\n\n[C]Hi'), findsOneWidget);
  });

  testWidgets('pasted ChordPro with a title fills the title for you', (
    tester,
  ) async {
    await openEditor(tester);
    await tester.enterText(contentField, SampleSongs.amazingGrace);
    await tester.pumpAndSettle();

    expect(find.text('Already in ChordPro format.'), findsOneWidget);
    expect(find.text('Add a title'), findsNothing);
    expect(saveButton(tester).onPressed, isNotNull);
  });

  testWidgets('Open file fills title, artist and text', (tester) async {
    final files = FakeSongFiles(
      pickedText: '{title: From a File}\n{artist: Someone}\n\n[C]La la',
    );
    await openEditor(tester, files: files);

    await tester.tap(find.text('Open file'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'From a File'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Someone'), findsOneWidget);
    expect(find.widgetWithText(TextField, '[C]La la'), findsOneWidget);
  });

  testWidgets('a file that is not a song shows a message', (tester) async {
    final files = FakeSongFiles(pickError: const FormatException('x'));
    await openEditor(tester, files: files);

    await tester.tap(find.text('Open file'));
    await tester.pumpAndSettle();
    expect(find.textContaining("That file isn't a song"), findsOneWidget);
  });

  testWidgets('the keyboard never "corrects" the chord sheet', (tester) async {
    await openEditor(tester);
    final field = tester.widget<TextField>(contentField);
    expect(field.autocorrect, isFalse);
    expect(field.enableSuggestions, isFalse);
    expect(field.smartDashesType, SmartDashesType.disabled);
    expect(field.smartQuotesType, SmartQuotesType.disabled);
    expect(field.textCapitalization, TextCapitalization.none);
    expect(field.spellCheckConfiguration?.spellCheckService, isNull);
  });

  group('Scan photo', () {
    /// Words as Vision would return them for a printed song: a big title,
    /// then a chord line over a lyric line.
    List<RecognizedWord> photoOfGrace() {
      RecognizedWord w(String t, double l, double top, double r, double h) =>
          RecognizedWord(t, left: l, top: top, right: r, bottom: top + h);
      return [
        w('Amazing', 40, 0, 200, 40),
        w('Grace', 215, 0, 330, 40),
        // "A-mazing": G over the "m" (x 50), G7 over "grace" (x 111).
        w('G', 50, 70, 59, 18),
        w('G7', 111, 70, 129, 18),
        w('Amazing', 40, 92, 106, 20),
        w('grace', 111, 92, 152, 20),
      ];
    }

    Future<void> scanFrom(WidgetTester tester, String source) async {
      await tester.tap(find.text('Scan photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(source));
      await tester.pumpAndSettle();
    }

    testWidgets('a photo from the library fills title and chords', (
      tester,
    ) async {
      final photos = FakePhotoPicker();
      final recognizer = FakeTextRecognizer(words: photoOfGrace());
      final container = await pumpApp(
        tester,
        photos: photos,
        recognizer: recognizer,
      );
      await tester.tap(find.text('Add song'));
      await tester.pumpAndSettle();

      await scanFrom(tester, 'Choose from photos');

      expect(photos.picked, [PhotoSource.library]);
      expect(recognizer.read, ['/photos/song.jpg']);
      expect(photos.discarded, ['/photos/song.jpg'], reason: 'not kept');
      expect(
        tester.widget<TextField>(titleField).controller!.text,
        'Amazing Grace',
      );
      expect(
        find.text('Check the chords against the photo before saving.'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      final song = await container.read(songRepositoryProvider).getSong(1);
      expect(song!.body, contains('A[G]mazing [G7]grace'));
    });

    testWidgets('the camera works the same way', (tester) async {
      final photos = FakePhotoPicker();
      await pumpApp(
        tester,
        photos: photos,
        recognizer: FakeTextRecognizer(words: photoOfGrace()),
      );
      await tester.tap(find.text('Add song'));
      await tester.pumpAndSettle();
      await scanFrom(tester, 'Take a photo');
      expect(photos.picked, [PhotoSource.camera]);
      expect(
        tester.widget<TextField>(contentField).controller!.text,
        isNotEmpty,
      );
    });

    testWidgets('a second photo is added after the first', (tester) async {
      await pumpApp(
        tester,
        recognizer: FakeTextRecognizer(words: photoOfGrace()),
      );
      await tester.tap(find.text('Add song'));
      await tester.pumpAndSettle();
      await scanFrom(tester, 'Choose from photos');
      final once = tester.widget<TextField>(contentField).controller!.text;
      await scanFrom(tester, 'Choose from photos');
      final twice = tester.widget<TextField>(contentField).controller!.text;
      expect(twice, '$once\n\n$once');
    });

    testWidgets('several photos are read in the order picked', (
      tester,
    ) async {
      RecognizedWord w(String t, double l, double top) =>
          RecognizedWord(t, left: l, top: top, right: l + 60, bottom: top + 20);
      final photos = FakePhotoPicker(paths: ['/p/1.jpg', '/p/2.jpg']);
      final recognizer = FakeTextRecognizer(
        pages: {
          '/p/1.jpg': [w('Page', 40, 0), w('one', 110, 0)],
          '/p/2.jpg': [w('Page', 40, 0), w('two', 110, 0)],
        },
      );
      await pumpApp(tester, photos: photos, recognizer: recognizer);
      await tester.tap(find.text('Add song'));
      await tester.pumpAndSettle();
      await scanFrom(tester, 'Choose from photos');

      expect(recognizer.read, ['/p/1.jpg', '/p/2.jpg']);
      expect(photos.discarded, ['/p/1.jpg', '/p/2.jpg']);
      expect(
        tester.widget<TextField>(contentField).controller!.text,
        'Page one\n\nPage two',
      );
    });

    testWidgets('cancelling picks nothing and changes nothing', (tester) async {
      final recognizer = FakeTextRecognizer(words: photoOfGrace());
      await pumpApp(
        tester,
        photos: FakePhotoPicker(paths: []),
        recognizer: recognizer,
      );
      await tester.tap(find.text('Add song'));
      await tester.pumpAndSettle();
      await scanFrom(tester, 'Choose from photos');
      expect(recognizer.read, isEmpty);
      expect(tester.widget<TextField>(contentField).controller!.text, isEmpty);
    });

    testWidgets('a photo without text, or unreadable, says so', (
      tester,
    ) async {
      final recognizer = FakeTextRecognizer();
      await pumpApp(tester, recognizer: recognizer);
      await tester.tap(find.text('Add song'));
      await tester.pumpAndSettle();

      await scanFrom(tester, 'Choose from photos');
      expect(
        find.textContaining('No text found in that photo'),
        findsOneWidget,
      );

      recognizer.error = const TextRecognitionException('corrupt');
      await scanFrom(tester, 'Choose from photos');
      expect(find.text("Couldn't read that photo."), findsOneWidget);
    });

    testWidgets('a refused camera offers Settings or the photo library', (
      tester,
    ) async {
      final photos = FakePhotoPicker(
        error: PlatformException(code: 'camera_access_denied'),
      );
      final settings = FakeAppSettings();
      await pumpApp(
        tester,
        photos: photos,
        appSettings: settings,
        recognizer: FakeTextRecognizer(words: photoOfGrace()),
      );
      await tester.tap(find.text('Add song'));
      await tester.pumpAndSettle();

      await scanFrom(tester, 'Take a photo');
      expect(find.text('The camera is off'), findsOneWidget);
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();
      expect(settings.opened, 1);

      // The library needs no permission: offered right there.
      await scanFrom(tester, 'Take a photo');
      photos.error = null;
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Choose from photos'),
        ),
      );
      await tester.pumpAndSettle();
      expect(photos.picked, [
        PhotoSource.camera,
        PhotoSource.camera,
        PhotoSource.library,
      ]);
      expect(
        tester.widget<TextField>(titleField).controller!.text,
        'Amazing Grace',
      );
    });
  });

  group('Start over', () {
    testWidgets('is off until something is typed', (tester) async {
      await openEditor(tester);
      final button = find.widgetWithIcon(IconButton, Icons.restart_alt);
      expect(tester.widget<IconButton>(button).onPressed, isNull);
      await tester.enterText(titleField, 'Hymn');
      await tester.pump();
      expect(tester.widget<IconButton>(button).onPressed, isNotNull);
    });

    testWidgets('clears everything, and Undo brings it back', (tester) async {
      await openEditor(tester);
      await tester.enterText(titleField, 'Hymn');
      await tester.enterText(artistField, 'Someone');
      await tester.enterText(contentField, '[G]Hello');
      await tester.pump();

      await tester.tap(find.byTooltip('Start over'));
      await tester.pump();
      expect(tester.widget<TextField>(titleField).controller!.text, isEmpty);
      expect(tester.widget<TextField>(contentField).controller!.text, isEmpty);
      expect(find.text('Title, artist and text cleared.'), findsOneWidget);

      await tester.pumpAndSettle();
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(titleField).controller!.text, 'Hymn');
      expect(tester.widget<TextField>(artistField).controller!.text, 'Someone');
      expect(
        tester.widget<TextField>(contentField).controller!.text,
        '[G]Hello',
      );
    });

    testWidgets('is only in Add song, not Edit song', (tester) async {
      final container = await pumpApp(
        tester,
        songs: [SampleSongs.amazingGrace],
      );
      unawaited(container.read(routerProvider).push(Routes.editSong(1)));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Start over'), findsNothing);
    });
  });

  testWidgets('Cancel with no changes closes right away', (tester) async {
    await openEditor(tester);
    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(LibraryScreen), findsOneWidget);
    expect(find.byType(SongEditorScreen), findsNothing);
  });

  testWidgets('Cancel with changes asks before discarding', (tester) async {
    await openEditor(tester);
    await tester.enterText(titleField, 'Unsaved');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.byType(SongEditorScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.byType(SongEditorScreen), findsNothing);
    expect(find.byType(LibraryScreen), findsOneWidget);
  });

  testWidgets('editing a song loads it and saves changes', (tester) async {
    final container = await pumpApp(
      tester,
      songs: [SampleSongs.amazingGrace],
    );
    container.read(routerProvider).go(Routes.editSong(1));
    await tester.pumpAndSettle();

    expect(find.text('Edit song'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Amazing Grace'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'John Newton'), findsOneWidget);
    expect(saveButton(tester).onPressed, isNotNull);

    await tester.enterText(titleField, 'Amazing Grace (live)');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.byType(SongViewScreen), findsOneWidget);
    expect(find.text('Amazing Grace (live)'), findsOneWidget);
    final saved = await container.read(songRepositoryProvider).getSong(1);
    expect(saved!.body, startsWith('{title: Amazing Grace (live)}\n'));
    expect(saved.body, contains('A-[G]mazing'));
  });
}
