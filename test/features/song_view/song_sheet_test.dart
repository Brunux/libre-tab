import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/app/theme/app_theme.dart';
import 'package:libre_tab/core/chordpro/chordpro_parser.dart';
import 'package:libre_tab/features/song_view/presentation/widgets/song_sheet.dart';
import 'package:libre_tab/l10n/l10n.dart';

String nb(String text) => text.replaceAll(' ', ' ');

Future<void> pumpSheet(
  WidgetTester tester,
  String chordPro, {
  double width = 400,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(AppThemeVariant.dark),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: SingleChildScrollView(
              child: SongSheet(song: ChordProParser.parse(chordPro)),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('each chord sits right above its syllable', (tester) async {
    await pumpSheet(tester, 'A-[G]mazing [G7]grace, how [C]sweet');

    for (final (chord, word) in [
      ('G', 'mazing '),
      ('G7', 'grace, '),
      ('C', 'sweet'),
    ]) {
      final c = tester.getTopLeft(find.text(chord));
      final w = tester.getTopLeft(find.text(nb(word)));
      expect(c.dx, w.dx, reason: '$chord over $word');
      expect(c.dy, lessThan(w.dy), reason: '$chord above $word');
    }
  });

  testWidgets('a word split by a chord never breaks across lines', (
    tester,
  ) async {
    // The test font draws every character 22 px wide, so this is narrow
    // enough to wrap the line but still fits the longest word, "A-mazing".
    // (A word wider than the whole screen does break, rather than overflow.)
    await pumpSheet(
      tester,
      'A-[G]mazing [G7]grace, how [C]sweet the [G]sound',
      width: 260,
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getTopLeft(find.text('A-')).dy,
      tester.getTopLeft(find.text(nb('mazing '))).dy,
    );
    // It did wrap: "sound" is lower than "A-".
    expect(
      tester.getTopLeft(find.text('sound')).dy,
      greaterThan(tester.getTopLeft(find.text('A-')).dy),
    );
    // And chords stayed on their words.
    expect(
      tester.getTopLeft(find.text('C')).dx,
      tester.getTopLeft(find.text(nb('sweet '))).dx,
    );
  });

  testWidgets('lines without chords have no empty chord row', (tester) async {
    await pumpSheet(tester, 'Just words\n[G]With chord');
    final plain = tester.getSize(find.text(nb('Just ')));
    final column = tester.getSize(
      find
          .ancestor(of: find.text(nb('Just ')), matching: find.byType(Column))
          .first,
    );
    expect(column.height, plain.height);
  });

  testWidgets('section labels, chorus repeat and comments', (tester) async {
    await pumpSheet(tester, '''
{sov: Verse 1}
[C]Hello
{eov}
{soc}
[F]Oh la la
{eoc}
{c: Softly}
{chorus}
{sob}
[G]Bridge line
{eob}''');

    expect(find.text('VERSE 1'), findsOneWidget);
    expect(find.text('CHORUS'), findsNWidgets(2)); // original + repeat
    expect(find.text(nb('la ')), findsNWidgets(2));
    expect(find.text('BRIDGE'), findsOneWidget);
    expect(find.text('Softly'), findsOneWidget);
  });

  testWidgets('{chorus} before any chorus shows just the label', (
    tester,
  ) async {
    await pumpSheet(tester, '[G]Verse\n\n{chorus}');
    expect(find.text('CHORUS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tabs are monospace and scroll sideways', (tester) async {
    await pumpSheet(tester, '{sot}\ne|--0--2--3--|\nB|--1--------|\n{eot}');
    final tab = find.textContaining('e|--0--2--3--|');
    final text = tester.widget<Text>(tab);
    expect(text.style!.fontFamily, AppFonts.mono);
    expect(text.softWrap, isFalse);
    final scrollers = find
        .ancestor(of: tab, matching: find.byType(SingleChildScrollView))
        .evaluate()
        .map((e) => (e.widget as SingleChildScrollView).scrollDirection);
    expect(scrollers, contains(Axis.horizontal));
  });

  testWidgets('chords-only lines show just the chords', (tester) async {
    await pumpSheet(tester, '[G] [C] [D]');
    for (final chord in ['G', 'C', 'D']) {
      expect(find.text(chord), findsOneWidget);
    }
  });
}
