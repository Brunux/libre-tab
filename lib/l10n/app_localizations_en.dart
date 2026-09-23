// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Libre Tab';

  @override
  String get tabSongbook => 'Songbook';

  @override
  String get tabTuner => 'Tuner';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get addSong => 'Add song';

  @override
  String get editSong => 'Edit song';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get comingSoon => 'Coming in a later milestone.';

  @override
  String get themeLabel => 'Theme';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeRedNight => 'Red night';

  @override
  String get themeLight => 'Light';

  @override
  String get switchTheme => 'Switch theme';

  @override
  String get searchHint => 'Search songs, artists or lyrics';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get filterAll => 'All songs';

  @override
  String get filterFavorites => 'Favorites';

  @override
  String songCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return '$_temp0';
  }

  @override
  String get emptySongbook => 'Your songbook is empty.\nAdd your first song.';

  @override
  String get noFavorites =>
      'No favorites yet.\nTap the star on a song to add it.';

  @override
  String get loadError => 'Couldn\'t open your songbook.';

  @override
  String get noMatches => 'No songs match your search.';

  @override
  String keyLabel(String key) {
    return 'Key $key';
  }

  @override
  String capoLabel(int fret) {
    return 'Capo $fret';
  }

  @override
  String get songNotFound => 'This song isn\'t in your songbook.';

  @override
  String get addFavorite => 'Add to favorites';

  @override
  String get removeFavorite => 'Remove from favorites';

  @override
  String get moreActions => 'More';

  @override
  String get share => 'Share';

  @override
  String get delete => 'Delete';

  @override
  String deleteTitle(String title) {
    return 'Delete “$title”?';
  }

  @override
  String get deleteBody => 'This can\'t be undone.';

  @override
  String get chorusLabel => 'Chorus';

  @override
  String get bridgeLabel => 'Bridge';

  @override
  String get titleLabel => 'Title';

  @override
  String get titleRequired => 'Add a title';

  @override
  String get artistLabel => 'Artist';

  @override
  String get contentLabel => 'Paste chords over lyrics, or ChordPro';

  @override
  String get openFile => 'Open file';

  @override
  String get cameraLater => 'Camera (later)';

  @override
  String get notASongFile =>
      'That file isn\'t a song (.cho, .chopro, .chordpro, .crd, .txt).';

  @override
  String get resultLabel => 'Result';

  @override
  String get previewTab => 'Preview';

  @override
  String get chordProTab => 'ChordPro';

  @override
  String importSummary(int chordLines, int sections) {
    return 'Chord lines placed: $chordLines · Sections found: $sections';
  }

  @override
  String get alreadyChordPro => 'Already in ChordPro format.';

  @override
  String get previewEmpty => 'The song will appear here as you type.';

  @override
  String get discardTitle => 'Discard changes?';

  @override
  String get discard => 'Discard';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String get saveError => 'Couldn\'t save the song.';

  @override
  String get chordsMenu => 'Chords';

  @override
  String get noChords => 'This song has no chords.';

  @override
  String get noDiagram => 'No diagram for this chord yet.';

  @override
  String get diagramLegend => '× don\'t play · ○ open string';

  @override
  String get keyStepper => 'Key';

  @override
  String get capoStepper => 'Capo';

  @override
  String get capoNone => 'None';

  @override
  String get transposeDown => 'Transpose down';

  @override
  String get transposeUp => 'Transpose up';

  @override
  String get capoDown => 'Capo down';

  @override
  String get capoUp => 'Capo up';

  @override
  String get textSize => 'Text';

  @override
  String get smallerText => 'Smaller text';

  @override
  String get largerText => 'Larger text';

  @override
  String get slower => 'Scroll slower';

  @override
  String get faster => 'Scroll faster';

  @override
  String get startScroll => 'Start auto-scroll';

  @override
  String get pauseScroll => 'Pause auto-scroll';

  @override
  String speedLabel(int speed) {
    return 'Speed $speed';
  }

  @override
  String soundsIn(String key, int fret, String shapes) {
    return 'Sounds in $key · Capo $fret · $shapes shapes';
  }
}
