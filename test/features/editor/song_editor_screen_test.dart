import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/app/router.dart';
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
    expect(find.text('The song will appear here as you type.'), findsOneWidget);

    await tester.enterText(contentField, '     G\nThat saved a wretch');
    await tester.pumpAndSettle();
    expect(
      find.text('Chord lines placed: 1 · Sections found: 0'),
      findsOneWidget,
    );
    expect(find.text('G'), findsOneWidget); // preview chord
    expect(find.text('Add a title'), findsOneWidget);
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

  testWidgets('the camera button is shown but not usable yet', (tester) async {
    await openEditor(tester);
    final camera = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text('Camera (later)'),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );
    expect(camera.onPressed, isNull);
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
