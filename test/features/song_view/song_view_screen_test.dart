import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/app/router.dart';
import 'package:libre_tab/features/editor/presentation/song_editor_screen.dart';
import 'package:libre_tab/features/library/data/song_repository.dart';
import 'package:libre_tab/features/library/presentation/library_screen.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_database.dart';

/// Lyric words are drawn with non-breaking spaces.
String nb(String text) => text.replaceAll(' ', ' ');

/// Opens song 1 (Amazing Grace).
Future<(ProviderContainer, FakeSongFiles)> openSong(WidgetTester tester) async {
  final files = FakeSongFiles();
  final container = await pumpApp(
    tester,
    songs: [SampleSongs.amazingGrace],
    files: files,
  );
  container.read(routerProvider).go(Routes.song(1));
  await tester.pumpAndSettle();
  return (container, files);
}

Future<void> chooseFromMenu(WidgetTester tester, String item) async {
  await tester.tap(find.byTooltip('More'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(item));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows title, details, chords and lyrics', (tester) async {
    await openSong(tester);

    expect(find.text('Amazing Grace'), findsOneWidget);
    expect(find.text('John Newton · Key G'), findsOneWidget);
    expect(find.text('G7'), findsOneWidget);
    expect(find.text(nb('grace, ')), findsOneWidget);
    expect(find.text(nb('wretch ')), findsOneWidget);
  });

  testWidgets('star toggles the favorite', (tester) async {
    final (container, _) = await openSong(tester);
    final repository = container.read(songRepositoryProvider);

    await tester.tap(find.byTooltip('Add to favorites'));
    await tester.pumpAndSettle();
    expect((await repository.getSong(1))!.favorite, isTrue);
    expect(find.byTooltip('Remove from favorites'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove from favorites'));
    await tester.pumpAndSettle();
    expect((await repository.getSong(1))!.favorite, isFalse);
  });

  testWidgets('Share sends the ChordPro text', (tester) async {
    final (_, files) = await openSong(tester);

    await chooseFromMenu(tester, 'Share');
    expect(files.shared.single.title, 'Amazing Grace');
    expect(files.shared.single.body, SampleSongs.amazingGrace);
  });

  testWidgets('Edit opens the editor with the song', (tester) async {
    await openSong(tester);

    await chooseFromMenu(tester, 'Edit song');
    expect(find.byType(SongEditorScreen), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Amazing Grace'), findsOneWidget);
  });

  testWidgets('Delete asks first; Cancel keeps the song', (tester) async {
    final (container, _) = await openSong(tester);

    await chooseFromMenu(tester, 'Delete');
    expect(find.text('Delete “Amazing Grace”?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('John Newton · Key G'), findsOneWidget);
    expect(await container.read(songRepositoryProvider).getSong(1), isNotNull);
  });

  testWidgets('Delete removes the song and returns to the list', (
    tester,
  ) async {
    final (container, _) = await openSong(tester);

    await chooseFromMenu(tester, 'Delete');
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.byType(LibraryScreen), findsOneWidget);
    expect(find.textContaining('Your songbook is empty'), findsOneWidget);
    expect(await container.read(songRepositoryProvider).getSong(1), isNull);
  });

  for (final path in ['/songs/999', '/songs/abc', '/songs/abc/edit']) {
    testWidgets('$path says the song is not in the songbook', (tester) async {
      final container = await pumpApp(tester);
      container.read(routerProvider).go(path);
      await tester.pumpAndSettle();
      expect(find.text("This song isn't in your songbook."), findsOneWidget);
    });
  }
}
