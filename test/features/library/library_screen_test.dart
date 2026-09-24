import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/features/library/data/song_repository.dart';
import 'package:libre_tab/features/song_view/presentation/song_view_screen.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_database.dart';

const List<String> _all = [
  SampleSongs.ohSusanna, // id 1
  SampleSongs.amazingGrace, // id 2
  SampleSongs.cancion, // id 3
];

/// Song titles on screen, top to bottom.
List<String> shownTitles(WidgetTester tester) {
  const titles = {'Amazing Grace', 'Canción de cuna', 'Oh! Susanna'};
  final texts = find.byType(Text).evaluate().map((e) => e.widget as Text);
  return [
    for (final t in texts)
      if (titles.contains(t.data)) t.data!,
  ];
}

void main() {
  testWidgets('an empty songbook shows the first-run message', (tester) async {
    await pumpApp(tester);
    expect(find.textContaining('Your songbook is empty'), findsOneWidget);
  });

  testWidgets('lists songs by title with key, artist and capo', (
    tester,
  ) async {
    await pumpApp(tester, songs: _all);

    expect(find.text('3 SONGS'), findsOneWidget);
    expect(shownTitles(tester), [
      'Amazing Grace',
      'Canción de cuna',
      'Oh! Susanna',
    ]);
    expect(find.text('John Newton'), findsOneWidget);
    expect(find.text('Stephen Foster · Capo 2'), findsOneWidget);
    expect(find.text('G'), findsOneWidget); // key badges
    expect(find.text('C'), findsOneWidget);
    expect(find.byIcon(Icons.music_note), findsOneWidget); // no {key}
  });

  testWidgets('search filters as you type and ignores accents', (
    tester,
  ) async {
    await pumpApp(tester, songs: _all);

    await tester.enterText(find.byType(TextField), 'cancion');
    await tester.pumpAndSettle();
    expect(shownTitles(tester), ['Canción de cuna']);
    expect(find.text('1 SONG'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'wretch');
    await tester.pumpAndSettle();
    expect(shownTitles(tester), ['Amazing Grace']);
  });

  testWidgets('no matches, then clearing the search', (tester) async {
    await pumpApp(tester, songs: _all);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No songs match your search.'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(shownTitles(tester), hasLength(3));
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);
    expect(find.byTooltip('Clear search'), findsNothing);
  });

  testWidgets('favorites filter', (tester) async {
    final container = await pumpApp(tester, songs: _all);

    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No favorites yet'), findsOneWidget);

    await container.read(songRepositoryProvider).setFavorite(1, favorite: true);
    await tester.pumpAndSettle();
    expect(shownTitles(tester), ['Oh! Susanna']);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);

    await tester.tap(find.text('All songs'));
    await tester.pumpAndSettle();
    expect(shownTitles(tester), hasLength(3));
  });

  testWidgets('empty states offer the way out', (tester) async {
    await pumpApp(tester, songs: _all);

    // No favorites: "Browse songs" goes back to all of them.
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Browse songs'));
    await tester.pumpAndSettle();
    expect(shownTitles(tester), hasLength(3));

    // No matches: the button under the message clears the search.
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Clear search'));
    await tester.pumpAndSettle();
    expect(shownTitles(tester), hasLength(3));
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);
  });

  testWidgets('tapping a song opens it', (tester) async {
    await pumpApp(tester, songs: _all);

    await tester.tap(find.text('Amazing Grace'));
    await tester.pumpAndSettle();
    expect(find.byType(SongViewScreen), findsOneWidget);
    expect(find.text('John Newton · Key G'), findsOneWidget);
  });

  group('swipe actions', () {
    Future<void> swipeLeft(WidgetTester tester, String title) async {
      await tester.drag(find.text(title), const Offset(-500, 0));
      await tester.pumpAndSettle();
    }

    testWidgets('swiping left shows Setlist, Share and Delete', (tester) async {
      await pumpApp(tester, songs: _all);
      await swipeLeft(tester, 'Amazing Grace');

      expect(find.text('Setlist'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('Delete removes the song at once, and Undo brings it back', (
      tester,
    ) async {
      final container = await pumpApp(tester, songs: _all);
      final songs = container.read(songRepositoryProvider);
      await swipeLeft(tester, 'Amazing Grace');
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Amazing Grace'), findsNothing);
      expect(find.text('Deleted “Amazing Grace”.'), findsOneWidget);
      expect(await songs.getSong(2), isNull);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(await songs.getSong(2), isNotNull);
      expect(find.text('Amazing Grace'), findsOneWidget);
    });

    testWidgets('Share shares the song file', (tester) async {
      final files = FakeSongFiles();
      await pumpApp(tester, songs: _all, files: files);
      await swipeLeft(tester, 'Oh! Susanna');
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      expect(files.shared.single.title, 'Oh! Susanna');
    });

    testWidgets('Setlist opens the Add to setlist sheet', (tester) async {
      await pumpApp(tester, songs: _all);
      await swipeLeft(tester, 'Oh! Susanna');
      await tester.tap(find.text('Setlist'));
      await tester.pumpAndSettle();
      expect(find.text('Add to setlist'), findsOneWidget);
      expect(find.text('New setlist'), findsOneWidget);
    });

    testWidgets('screen readers get the same actions', (tester) async {
      await pumpApp(tester, songs: _all);
      final node = tester.getSemantics(find.text('Amazing Grace'));
      final ids = node.getSemanticsData().customSemanticsActionIds ?? [];
      final labels = [
        for (final int id in ids) CustomSemanticsAction.getAction(id)!.label,
      ];
      expect(labels, ['Add to setlist', 'Share', 'Delete']);
    });
  });
}
