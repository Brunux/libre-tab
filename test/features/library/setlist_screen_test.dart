import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/app/router.dart';
import 'package:libre_tab/features/library/data/setlist_repository.dart';
import 'package:libre_tab/features/library/data/song_repository.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_database.dart';

const List<String> _all = [
  SampleSongs.ohSusanna, // id 1
  SampleSongs.amazingGrace, // id 2
  SampleSongs.cancion, // id 3
];

/// Makes setlist "Friday" with songs [ids] and opens it.
Future<(ProviderContainer, int)> openSetlist(
  WidgetTester tester,
  List<int> ids,
) async {
  final container = await pumpApp(tester, songs: _all);
  final setlists = container.read(setlistRepositoryProvider);
  final id = await setlists.create('Friday');
  await setlists.setSongs(id, ids);
  unawaited(container.read(routerProvider).push(Routes.setlist(id)));
  await tester.pumpAndSettle();
  return (container, id);
}

Future<List<int>> songIds(ProviderContainer container, int setlist) =>
    container.read(setlistRepositoryProvider).songIds(setlist);

void main() {
  testWidgets('the Setlists tab lists setlists, with an empty message', (
    tester,
  ) async {
    await pumpApp(tester, songs: _all);
    // A tab of its own now, not a chip in the songbook.
    expect(find.widgetWithText(ChoiceChip, 'Setlists'), findsNothing);
    await tester.tap(navItem('Setlists'));
    await tester.pumpAndSettle();

    expect(find.textContaining('No setlists yet'), findsOneWidget);
    // The floating button, and the same action under the message.
    expect(
      find.widgetWithText(FloatingActionButton, 'New setlist'),
      findsOneWidget,
    );
    expect(find.widgetWithText(OutlinedButton, 'New setlist'), findsOneWidget);
    expect(find.text('Add song'), findsNothing);
  });

  testWidgets('New setlist asks for a name and opens it', (tester) async {
    final container = await pumpApp(tester, songs: _all);
    await tester.tap(find.text('Setlists'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FloatingActionButton, 'New setlist'));
    await tester.pumpAndSettle();

    final create = find.widgetWithText(TextButton, 'Create');
    expect(tester.widget<TextButton>(create).onPressed, isNull);
    await tester.enterText(find.byType(TextField).last, 'Friday campfire');
    await tester.pump();
    await tester.tap(create);
    await tester.pumpAndSettle();

    expect(find.text('Friday campfire'), findsOneWidget);
    expect(find.text('No songs in this setlist yet.'), findsOneWidget);
    final list = await container
        .read(setlistRepositoryProvider)
        .watchSetlists()
        .first;
    expect(list.single.name, 'Friday campfire');

    // Back in the Setlists tab it's listed with its count.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Friday campfire'), findsOneWidget);
    expect(find.text('0 songs'), findsOneWidget);
  });

  testWidgets('Add songs ticks songs; new ones go to the end', (tester) async {
    final (container, id) = await openSetlist(tester, [2]);

    await tester.tap(find.text('Add songs'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Oh! Susanna'));
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Canción de cuna'));
    await tester.pump();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(await songIds(container, id), [2, 1, 3]);
    expect(find.text('3'), findsOneWidget); // position numbers
  });

  testWidgets('Add songs can untick a song to take it out', (tester) async {
    final (container, id) = await openSetlist(tester, [1, 2]);
    await tester.tap(find.text('Add songs'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Oh! Susanna'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(await songIds(container, id), [2]);
  });

  testWidgets('play shows n/total and swiping moves between songs', (
    tester,
  ) async {
    await openSetlist(tester, [2, 1]);
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();

    expect(find.text('Amazing Grace'), findsOneWidget);
    expect(find.textContaining('1/2 · John Newton'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(-600, 0), 1500);
    await tester.pumpAndSettle();
    expect(find.text('Oh! Susanna'), findsOneWidget);
    expect(find.textContaining('2/2 · '), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(600, 0), 1500);
    await tester.pumpAndSettle();
    expect(find.text('Amazing Grace'), findsOneWidget);
  });

  group('up next', () {
    /// A song longer than the screen, so auto-scroll has somewhere to go.
    String long(String title) => [
      '{title: $title}',
      for (var i = 0; i < 40; i++) '[G]$title line $i',
    ].join('\n');

    Future<void> play(WidgetTester tester) async {
      final container = await pumpApp(
        tester,
        songs: [long('First song'), long('Second song')],
      );
      final setlists = container.read(setlistRepositoryProvider);
      final id = await setlists.create('Friday');
      await setlists.setSongs(id, [1, 2]);
      unawaited(container.read(routerProvider).push(Routes.playSetlist(id, 0)));
      await tester.pumpAndSettle();
    }

    Future<void> scrollToTheEnd(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Start auto-scroll'));
      await tester.pump();
      await tester.pump(const Duration(minutes: 10));
      await tester.pump();
    }

    testWidgets('after the last line, the next song is a tap away', (
      tester,
    ) async {
      await play(tester);
      await tester.ensureVisible(find.text('UP NEXT'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Second song'));
      await tester.pumpAndSettle();
      expect(find.textContaining('2/2 · '), findsOneWidget);
      // The last song has nothing after it.
      expect(find.text('UP NEXT'), findsNothing);
    });

    testWidgets('auto-scroll to the end moves on, and keeps scrolling', (
      tester,
    ) async {
      await play(tester);
      await scrollToTheEnd(tester);
      expect(find.text('NEXT SONG IN 5'), findsOneWidget);
      // A ring fills around the arrow as it counts.
      final ring = find.descendant(
        of: find.byType(Stack),
        matching: find.byType(CircularProgressIndicator),
      );
      expect(ring, findsOneWidget);
      double filled() => tester.widget<CircularProgressIndicator>(ring).value!;
      await tester.pump(const Duration(milliseconds: 500));
      final early = filled();
      await tester.pump(const Duration(milliseconds: 400));
      expect(early, greaterThan(0));
      expect(filled(), greaterThan(early));

      await tester.pump(const Duration(seconds: 5));
      // The page slide (not pumpAndSettle: that would also run the next
      // song's auto-scroll to its end).
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.textContaining('2/2 · '), findsOneWidget);
      expect(find.byTooltip('Start auto-scroll'), findsOneWidget);
      // A second at the top, then it scrolls on its own.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.byTooltip('Pause auto-scroll'), findsOneWidget);
      await tester.tap(find.byTooltip('Pause auto-scroll'));
      await tester.pump();
    });

    testWidgets('Stay stops the countdown', (tester) async {
      await play(tester);
      await scrollToTheEnd(tester);
      await tester.tap(find.text('Stay'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      expect(find.textContaining('1/2 · '), findsOneWidget);
      expect(find.text('UP NEXT'), findsOneWidget);
    });
  });

  testWidgets('tapping a row plays from that song', (tester) async {
    await openSetlist(tester, [2, 1]);
    await tester.tap(find.text('Oh! Susanna'));
    await tester.pumpAndSettle();
    expect(find.textContaining('2/2 · '), findsOneWidget);
  });

  testWidgets('dragging the handle reorders the songs', (tester) async {
    final (container, id) = await openSetlist(tester, [1, 2, 3]);

    final handle = find.byIcon(Icons.drag_handle).first;
    final gesture = await tester.startGesture(tester.getCenter(handle));
    for (var i = 0; i < 8; i++) {
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    final order = await songIds(container, id);
    expect(order.first, isNot(1));
    expect(order, containsAll([1, 2, 3]));
  });

  testWidgets('the remove button takes a song out, not the songbook', (
    tester,
  ) async {
    final (container, id) = await openSetlist(tester, [1, 2]);
    await tester.tap(find.byTooltip('Remove Oh! Susanna from the setlist'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // The row folds away first; then the song leaves the setlist.
    expect(await songIds(container, id), [1, 2]);
    await tester.pumpAndSettle();

    expect(await songIds(container, id), [2]);
    expect(await container.read(songRepositoryProvider).getSong(1), isNotNull);
  });

  testWidgets('rename and delete from the menu', (tester) async {
    final (container, _) = await openSetlist(tester, [1]);

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Saturday');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Saturday'), findsOneWidget);

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('The songs stay in your songbook.'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(
      await container.read(setlistRepositoryProvider).watchSetlists().first,
      isEmpty,
    );
    expect(await container.read(songRepositoryProvider).getSong(1), isNotNull);
    expect(find.text('Oh! Susanna'), findsOneWidget); // back in the songbook
  });

  testWidgets('a missing setlist says so', (tester) async {
    final container = await pumpApp(tester);
    unawaited(container.read(routerProvider).push(Routes.setlist(99)));
    await tester.pumpAndSettle();
    expect(find.text("This setlist doesn't exist anymore."), findsOneWidget);
  });

  testWidgets('song view: Add to setlist toggles membership', (tester) async {
    final container = await pumpApp(tester, songs: _all);
    final setlists = container.read(setlistRepositoryProvider);
    final friday = await setlists.create('Friday');
    unawaited(container.read(routerProvider).push(Routes.song(2)));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to setlist'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(CheckboxListTile, 'Friday'));
    await tester.pumpAndSettle();
    expect(await setlists.songIds(friday), [2]);
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Friday'));
    await tester.pumpAndSettle();
    expect(await setlists.songIds(friday), isEmpty);

    // "New setlist" makes one with this song in it.
    await tester.tap(find.text('New setlist'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Road trip');
    await tester.pump();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    final all = await setlists.watchSetlists().first;
    final trip = all.firstWhere((s) => s.name == 'Road trip');
    expect(await setlists.songIds(trip.id), [2]);
  });
}
