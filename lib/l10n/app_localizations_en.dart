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
  String get themeLabel => 'Theme';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeRedNight => 'Red night';

  @override
  String get themeLight => 'Light';

  @override
  String get leaveRedNight => 'Leave red night';

  @override
  String get chooseTheme => 'Choose theme';

  @override
  String get searchHint => 'Search songs, artists or lyrics';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get browseSongs => 'Browse songs';

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
  String get openFile => 'Open file';

  @override
  String get notASongFile =>
      'That file isn\'t a song (.cho, .chopro, .chordpro, .crd, .txt).';

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
  String get diagramLegend =>
      '× don\'t play · ○ open · left: fret numbers · below: the fret for each string (0 = open)';

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

  @override
  String get tunerIntroTitle => 'Tune your guitar';

  @override
  String get tunerIntroBody =>
      'The tuner listens to your guitar through the microphone. Nothing is recorded or saved.';

  @override
  String get startTuner => 'Start tuner';

  @override
  String get micDeniedTitle => 'The microphone is off';

  @override
  String get micDeniedBody =>
      'To tune, Libre Tab needs the microphone. Allow it for Libre Tab in Settings, then come back here.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get playAString => 'Play a string';

  @override
  String get inTune => 'In tune';

  @override
  String get tooLow => 'Too low · tighten';

  @override
  String get tooHigh => 'Too high · loosen';

  @override
  String centsOff(String cents) {
    return '$cents cents';
  }

  @override
  String get tuningLabel => 'Tuning';

  @override
  String get tuningStandard => 'Standard';

  @override
  String get tuningHalfStepDown => 'Half-step down';

  @override
  String get tuningDropD => 'Drop D';

  @override
  String get tuningDadgad => 'DADGAD';

  @override
  String get tuningOpenG => 'Open G';

  @override
  String get tuningOpenD => 'Open D';

  @override
  String get stringsLabel => 'Strings';

  @override
  String get autoDetect => 'Auto-detect';

  @override
  String stringNumber(String number) {
    String _temp0 = intl.Intl.selectLogic(number, {
      '1': '1st',
      '2': '2nd',
      '3': '3rd',
      'other': '${number}th',
    });
    return '$_temp0';
  }

  @override
  String stringButton(String number, String note) {
    return '$number string, $note';
  }

  @override
  String a4Label(int hz) {
    return 'A4 = $hz Hz';
  }

  @override
  String get a4Title => 'Reference pitch';

  @override
  String get a4Help =>
      'Almost all music uses A4 = 440 Hz. Change it only to match another instrument.';

  @override
  String get a4Reset => 'Back to 440';

  @override
  String get tabSetlists => 'Setlists';

  @override
  String get newSetlist => 'New setlist';

  @override
  String get setlistNameLabel => 'Name';

  @override
  String get setlistNameHint => 'Friday campfire';

  @override
  String get create => 'Create';

  @override
  String get done => 'Done';

  @override
  String get noSetlists => 'No setlists yet.\nMake one for your next campfire.';

  @override
  String get noSetlistMatches => 'No setlists match your search.';

  @override
  String get emptySetlist => 'No songs in this setlist yet.';

  @override
  String get setlistNotFound => 'This setlist doesn\'t exist anymore.';

  @override
  String get addSongs => 'Add songs';

  @override
  String get playSetlist => 'Play';

  @override
  String get renameSetlist => 'Rename';

  @override
  String deleteSetlistTitle(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get deleteSetlistBody => 'The songs stay in your songbook.';

  @override
  String removeFromSetlist(String title) {
    return 'Remove $title from the setlist';
  }

  @override
  String get addToSetlist => 'Add to setlist';

  @override
  String get swipeHint => 'Swipe for the next song';

  @override
  String get songbookSection => 'Songbook';

  @override
  String get exportSongs => 'Export all songs';

  @override
  String get exportSongsHint => 'A .zip file with one .cho per song';

  @override
  String get importSongs => 'Import songs';

  @override
  String get importSongsHint => 'A .zip from Export, or a single song file';

  @override
  String get addStarterSongs => 'Add starter songs';

  @override
  String get addStarterSongsHint => 'Public-domain campfire classics';

  @override
  String songsImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs added.',
      one: '1 song added.',
      zero: 'No songs found in that file.',
    );
    return '$_temp0';
  }

  @override
  String starterSongsAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count starter songs added.',
      one: '1 starter song added.',
      zero: 'The starter songs are already in your songbook.',
    );
    return '$_temp0';
  }

  @override
  String get importError => 'Couldn\'t read that file.';

  @override
  String get nothingToExport =>
      'Your songbook is empty. There\'s nothing to export.';

  @override
  String get aboutSection => 'About';

  @override
  String get aboutBody =>
      'Libre Tab is free software under the GNU GPL 3.0 or later. It works offline and collects no data.';

  @override
  String get licenses => 'Licenses';

  @override
  String versionLabel(String version, int build) {
    return 'Version $version ($build)';
  }

  @override
  String get dangerZone => 'Danger zone';

  @override
  String get deleteAllSongs => 'Delete all songs';

  @override
  String get deleteAllSongsHint => 'Removes every song from this phone';

  @override
  String deleteAllTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete all $count songs?',
      one: 'Delete your only song?',
    );
    return '$_temp0';
  }

  @override
  String get deleteAllBody =>
      'Your setlists will be left empty. To keep a copy, export your songs first.';

  @override
  String get exportFirst => 'Export first';

  @override
  String get deleteAllConfirm => 'Delete all';

  @override
  String songsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs deleted.',
      one: '1 song deleted.',
    );
    return '$_temp0';
  }

  @override
  String songDeleted(String title) {
    return 'Deleted “$title”.';
  }

  @override
  String get undo => 'Undo';

  @override
  String get swipeSetlist => 'Setlist';

  @override
  String get findDuplicates => 'Find duplicates';

  @override
  String get findDuplicatesHint => 'Songs with the same title and artist';

  @override
  String get noDuplicates => 'No duplicates found.';

  @override
  String get exactCopies => 'Exact copies';

  @override
  String get exactCopiesHint =>
      'Same title, artist and text. One of each is kept, along with any favorite star and setlist places the copies had.';

  @override
  String removeCopies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Remove $count copies',
      one: 'Remove 1 copy',
    );
    return '$_temp0';
  }

  @override
  String copiesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count copies',
      one: '1 copy',
    );
    return '$_temp0';
  }

  @override
  String copiesRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count copies removed.',
      one: '1 copy removed.',
    );
    return '$_temp0';
  }

  @override
  String get differentVersions => 'Same title, different text';

  @override
  String get differentVersionsHint =>
      'These may be different versions. Open them to compare, and delete the one you don\'t want.';

  @override
  String addedOn(String date) {
    return 'Added $date';
  }

  @override
  String get scanPhoto => 'Scan photo';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get choosePhoto => 'Choose from photos';

  @override
  String get readingPhoto => 'Reading the photo…';

  @override
  String get noTextFound =>
      'No text found in that photo. Try a closer, sharper photo in good light.';

  @override
  String get scanDone => 'Check the chords against the photo before saving.';

  @override
  String get scanError => 'Couldn\'t read that photo.';

  @override
  String readingPhotoOf(int current, int total) {
    return 'Reading photo $current of $total…';
  }

  @override
  String get startOver => 'Start over';

  @override
  String get startedOver => 'Title, artist and text cleared.';

  @override
  String get fretMuted => 'not played';

  @override
  String get fretOpen => 'open';

  @override
  String diagramFrets(String frets) {
    return 'Frets from the thickest string: $frets';
  }

  @override
  String get searchSetlistsHint => 'Search setlists';

  @override
  String get fileTooBig => 'That file is too big to be a song.';

  @override
  String get privacyTitle => 'Privacy';

  @override
  String get privacySummary =>
      'Libre Tab collects no data. It has no account, no ads and no analytics, and it never connects to the internet.';

  @override
  String get privacySongsTitle => 'Your songs';

  @override
  String get privacySongsBody =>
      'Your songs, setlists, settings and play history (which songs you opened, and how often) stay on this device. They leave it only when you share or export them. Your device\'s own backup includes them, like any app\'s data.';

  @override
  String get privacyMicTitle => 'Microphone';

  @override
  String get privacyMicBody =>
      'The tuner listens only while the Tuner tab is on screen. The sound is analyzed on the device and thrown away at once: nothing is recorded, saved or sent.';

  @override
  String get privacyPhotosTitle => 'Camera and photos';

  @override
  String get privacyPhotosBody =>
      'Scan photo reads a song from a photo you take or choose. The text is read on the device and the photo isn\'t kept. When you choose photos, the app only sees the ones you pick.';

  @override
  String get privacyMore => 'Full privacy policy and questions:';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get cameraDeniedTitle => 'The camera is off';

  @override
  String get cameraDeniedBody =>
      'To take photos of songs, allow the camera for Libre Tab in Settings. You can still choose photos you already have.';

  @override
  String get sortLabel => 'Sort';

  @override
  String get sortTitle => 'A–Z';

  @override
  String get sortArtist => 'Artist';

  @override
  String get sortRecent => 'Recent';

  @override
  String get sortMostPlayed => 'Most played';

  @override
  String get recentlyPlayed => 'Recently played';

  @override
  String playedTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Played $count×',
      one: 'Played once',
    );
    return '$_temp0';
  }

  @override
  String get playedToday => 'Played today';

  @override
  String get playedYesterday => 'Played yesterday';

  @override
  String playedDaysAgo(int days) {
    return 'Played $days days ago';
  }

  @override
  String playedOn(String date) {
    return 'Played $date';
  }

  @override
  String jumpToLetter(String letter) {
    return 'Jump to $letter';
  }

  @override
  String get upNext => 'Up next';

  @override
  String nextSongIn(int seconds) {
    return 'Next song in $seconds';
  }

  @override
  String get stay => 'Stay';

  @override
  String get allTuned => 'All tuned — let\'s play!';

  @override
  String playSong(String title) {
    return 'Play $title';
  }

  @override
  String get openSongbook => 'Open songbook';

  @override
  String get stringTuned => 'tuned';

  @override
  String get editTab => 'Edit';

  @override
  String get paste => 'Paste';

  @override
  String get pasteHint => 'Copied from a website or a note';

  @override
  String get scanPhotoHint =>
      'A printed chord sheet, from the camera or photos';

  @override
  String get openFileHint => 'A .cho, .chordpro or .txt file';

  @override
  String get clipboardEmpty => 'Nothing to paste. Copy a song first.';

  @override
  String get contentHintOr =>
      'Or type or paste chords over lyrics, or ChordPro';

  @override
  String get pasteTooBig => 'That\'s too much text for one song.';
}
