import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Libre Tab'**
  String get appTitle;

  /// No description provided for @tabSongbook.
  ///
  /// In en, this message translates to:
  /// **'Songbook'**
  String get tabSongbook;

  /// No description provided for @tabTuner.
  ///
  /// In en, this message translates to:
  /// **'Tuner'**
  String get tabTuner;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @addSong.
  ///
  /// In en, this message translates to:
  /// **'Add song'**
  String get addSong;

  /// No description provided for @editSong.
  ///
  /// In en, this message translates to:
  /// **'Edit song'**
  String get editSong;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @themeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeRedNight.
  ///
  /// In en, this message translates to:
  /// **'Red night'**
  String get themeRedNight;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @switchTheme.
  ///
  /// In en, this message translates to:
  /// **'Switch theme'**
  String get switchTheme;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search songs, artists or lyrics'**
  String get searchHint;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All songs'**
  String get filterAll;

  /// No description provided for @filterFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get filterFavorites;

  /// No description provided for @songCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song} other{{count} songs}}'**
  String songCount(int count);

  /// No description provided for @emptySongbook.
  ///
  /// In en, this message translates to:
  /// **'Your songbook is empty.\nAdd your first song.'**
  String get emptySongbook;

  /// No description provided for @noFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet.\nTap the star on a song to add it.'**
  String get noFavorites;

  /// No description provided for @loadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open your songbook.'**
  String get loadError;

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'No songs match your search.'**
  String get noMatches;

  /// No description provided for @keyLabel.
  ///
  /// In en, this message translates to:
  /// **'Key {key}'**
  String keyLabel(String key);

  /// No description provided for @capoLabel.
  ///
  /// In en, this message translates to:
  /// **'Capo {fret}'**
  String capoLabel(int fret);

  /// No description provided for @songNotFound.
  ///
  /// In en, this message translates to:
  /// **'This song isn\'t in your songbook.'**
  String get songNotFound;

  /// No description provided for @addFavorite.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addFavorite;

  /// No description provided for @removeFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFavorite;

  /// No description provided for @moreActions.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreActions;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete “{title}”?'**
  String deleteTitle(String title);

  /// No description provided for @deleteBody.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be undone.'**
  String get deleteBody;

  /// No description provided for @chorusLabel.
  ///
  /// In en, this message translates to:
  /// **'Chorus'**
  String get chorusLabel;

  /// No description provided for @bridgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Bridge'**
  String get bridgeLabel;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Add a title'**
  String get titleRequired;

  /// No description provided for @artistLabel.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get artistLabel;

  /// No description provided for @contentLabel.
  ///
  /// In en, this message translates to:
  /// **'Paste chords over lyrics, or ChordPro'**
  String get contentLabel;

  /// No description provided for @openFile.
  ///
  /// In en, this message translates to:
  /// **'Open file'**
  String get openFile;

  /// No description provided for @cameraLater.
  ///
  /// In en, this message translates to:
  /// **'Camera (later)'**
  String get cameraLater;

  /// No description provided for @notASongFile.
  ///
  /// In en, this message translates to:
  /// **'That file isn\'t a song (.cho, .chopro, .chordpro, .crd, .txt).'**
  String get notASongFile;

  /// No description provided for @resultLabel.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get resultLabel;

  /// No description provided for @previewTab.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get previewTab;

  /// No description provided for @chordProTab.
  ///
  /// In en, this message translates to:
  /// **'ChordPro'**
  String get chordProTab;

  /// No description provided for @importSummary.
  ///
  /// In en, this message translates to:
  /// **'Chord lines placed: {chordLines} · Sections found: {sections}'**
  String importSummary(int chordLines, int sections);

  /// No description provided for @alreadyChordPro.
  ///
  /// In en, this message translates to:
  /// **'Already in ChordPro format.'**
  String get alreadyChordPro;

  /// No description provided for @previewEmpty.
  ///
  /// In en, this message translates to:
  /// **'The song will appear here as you type.'**
  String get previewEmpty;

  /// No description provided for @discardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardTitle;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// No description provided for @saveError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the song.'**
  String get saveError;

  /// No description provided for @chordsMenu.
  ///
  /// In en, this message translates to:
  /// **'Chords'**
  String get chordsMenu;

  /// No description provided for @noChords.
  ///
  /// In en, this message translates to:
  /// **'This song has no chords.'**
  String get noChords;

  /// No description provided for @noDiagram.
  ///
  /// In en, this message translates to:
  /// **'No diagram for this chord yet.'**
  String get noDiagram;

  /// No description provided for @diagramLegend.
  ///
  /// In en, this message translates to:
  /// **'× don\'t play · ○ open string'**
  String get diagramLegend;

  /// No description provided for @keyStepper.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get keyStepper;

  /// No description provided for @capoStepper.
  ///
  /// In en, this message translates to:
  /// **'Capo'**
  String get capoStepper;

  /// No description provided for @capoNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get capoNone;

  /// No description provided for @transposeDown.
  ///
  /// In en, this message translates to:
  /// **'Transpose down'**
  String get transposeDown;

  /// No description provided for @transposeUp.
  ///
  /// In en, this message translates to:
  /// **'Transpose up'**
  String get transposeUp;

  /// No description provided for @capoDown.
  ///
  /// In en, this message translates to:
  /// **'Capo down'**
  String get capoDown;

  /// No description provided for @capoUp.
  ///
  /// In en, this message translates to:
  /// **'Capo up'**
  String get capoUp;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get textSize;

  /// No description provided for @smallerText.
  ///
  /// In en, this message translates to:
  /// **'Smaller text'**
  String get smallerText;

  /// No description provided for @largerText.
  ///
  /// In en, this message translates to:
  /// **'Larger text'**
  String get largerText;

  /// No description provided for @slower.
  ///
  /// In en, this message translates to:
  /// **'Scroll slower'**
  String get slower;

  /// No description provided for @faster.
  ///
  /// In en, this message translates to:
  /// **'Scroll faster'**
  String get faster;

  /// No description provided for @startScroll.
  ///
  /// In en, this message translates to:
  /// **'Start auto-scroll'**
  String get startScroll;

  /// No description provided for @pauseScroll.
  ///
  /// In en, this message translates to:
  /// **'Pause auto-scroll'**
  String get pauseScroll;

  /// No description provided for @speedLabel.
  ///
  /// In en, this message translates to:
  /// **'Speed {speed}'**
  String speedLabel(int speed);

  /// No description provided for @soundsIn.
  ///
  /// In en, this message translates to:
  /// **'Sounds in {key} · Capo {fret} · {shapes} shapes'**
  String soundsIn(String key, int fret, String shapes);

  /// No description provided for @tunerIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Tune your guitar'**
  String get tunerIntroTitle;

  /// No description provided for @tunerIntroBody.
  ///
  /// In en, this message translates to:
  /// **'The tuner listens to your guitar through the microphone. Nothing is recorded or saved.'**
  String get tunerIntroBody;

  /// No description provided for @startTuner.
  ///
  /// In en, this message translates to:
  /// **'Start tuner'**
  String get startTuner;

  /// No description provided for @micDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'The microphone is off'**
  String get micDeniedTitle;

  /// No description provided for @micDeniedBody.
  ///
  /// In en, this message translates to:
  /// **'Allow it in Settings → Libre Tab → Microphone, then try again.'**
  String get micDeniedBody;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @playAString.
  ///
  /// In en, this message translates to:
  /// **'Play a string'**
  String get playAString;

  /// No description provided for @inTune.
  ///
  /// In en, this message translates to:
  /// **'In tune'**
  String get inTune;

  /// No description provided for @tooLow.
  ///
  /// In en, this message translates to:
  /// **'Too low · tighten'**
  String get tooLow;

  /// No description provided for @tooHigh.
  ///
  /// In en, this message translates to:
  /// **'Too high · loosen'**
  String get tooHigh;

  /// No description provided for @centsOff.
  ///
  /// In en, this message translates to:
  /// **'{cents} cents'**
  String centsOff(String cents);

  /// No description provided for @tuningLabel.
  ///
  /// In en, this message translates to:
  /// **'Tuning'**
  String get tuningLabel;

  /// No description provided for @tuningStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get tuningStandard;

  /// No description provided for @tuningHalfStepDown.
  ///
  /// In en, this message translates to:
  /// **'Half-step down'**
  String get tuningHalfStepDown;

  /// No description provided for @tuningDropD.
  ///
  /// In en, this message translates to:
  /// **'Drop D'**
  String get tuningDropD;

  /// No description provided for @tuningDadgad.
  ///
  /// In en, this message translates to:
  /// **'DADGAD'**
  String get tuningDadgad;

  /// No description provided for @tuningOpenG.
  ///
  /// In en, this message translates to:
  /// **'Open G'**
  String get tuningOpenG;

  /// No description provided for @tuningOpenD.
  ///
  /// In en, this message translates to:
  /// **'Open D'**
  String get tuningOpenD;

  /// No description provided for @stringsLabel.
  ///
  /// In en, this message translates to:
  /// **'Strings'**
  String get stringsLabel;

  /// No description provided for @autoDetect.
  ///
  /// In en, this message translates to:
  /// **'Auto-detect'**
  String get autoDetect;

  /// No description provided for @stringNumber.
  ///
  /// In en, this message translates to:
  /// **'{number, select, 1{1st} 2{2nd} 3{3rd} other{{number}th}}'**
  String stringNumber(String number);

  /// No description provided for @stringButton.
  ///
  /// In en, this message translates to:
  /// **'{number} string, {note}'**
  String stringButton(String number, String note);

  /// No description provided for @a4Label.
  ///
  /// In en, this message translates to:
  /// **'A4 = {hz} Hz'**
  String a4Label(int hz);

  /// No description provided for @a4Title.
  ///
  /// In en, this message translates to:
  /// **'Reference pitch'**
  String get a4Title;

  /// No description provided for @a4Help.
  ///
  /// In en, this message translates to:
  /// **'Almost all music uses A4 = 440 Hz. Change it only to match another instrument.'**
  String get a4Help;

  /// No description provided for @a4Reset.
  ///
  /// In en, this message translates to:
  /// **'Back to 440'**
  String get a4Reset;

  /// No description provided for @filterSetlists.
  ///
  /// In en, this message translates to:
  /// **'Setlists'**
  String get filterSetlists;

  /// No description provided for @newSetlist.
  ///
  /// In en, this message translates to:
  /// **'New setlist'**
  String get newSetlist;

  /// No description provided for @setlistNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get setlistNameLabel;

  /// No description provided for @setlistNameHint.
  ///
  /// In en, this message translates to:
  /// **'Friday campfire'**
  String get setlistNameHint;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @noSetlists.
  ///
  /// In en, this message translates to:
  /// **'No setlists yet.\nMake one for your next campfire.'**
  String get noSetlists;

  /// No description provided for @noSetlistMatches.
  ///
  /// In en, this message translates to:
  /// **'No setlists match your search.'**
  String get noSetlistMatches;

  /// No description provided for @emptySetlist.
  ///
  /// In en, this message translates to:
  /// **'No songs in this setlist yet.'**
  String get emptySetlist;

  /// No description provided for @setlistNotFound.
  ///
  /// In en, this message translates to:
  /// **'This setlist doesn\'t exist anymore.'**
  String get setlistNotFound;

  /// No description provided for @addSongs.
  ///
  /// In en, this message translates to:
  /// **'Add songs'**
  String get addSongs;

  /// No description provided for @playSetlist.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playSetlist;

  /// No description provided for @renameSetlist.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameSetlist;

  /// No description provided for @deleteSetlistTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”?'**
  String deleteSetlistTitle(String name);

  /// No description provided for @deleteSetlistBody.
  ///
  /// In en, this message translates to:
  /// **'The songs stay in your songbook.'**
  String get deleteSetlistBody;

  /// No description provided for @removeFromSetlist.
  ///
  /// In en, this message translates to:
  /// **'Remove {title} from the setlist'**
  String removeFromSetlist(String title);

  /// No description provided for @addToSetlist.
  ///
  /// In en, this message translates to:
  /// **'Add to setlist'**
  String get addToSetlist;

  /// No description provided for @swipeHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe for the next song'**
  String get swipeHint;

  /// No description provided for @songbookSection.
  ///
  /// In en, this message translates to:
  /// **'Songbook'**
  String get songbookSection;

  /// No description provided for @exportSongs.
  ///
  /// In en, this message translates to:
  /// **'Export all songs'**
  String get exportSongs;

  /// No description provided for @exportSongsHint.
  ///
  /// In en, this message translates to:
  /// **'A .zip file with one .cho per song'**
  String get exportSongsHint;

  /// No description provided for @importSongs.
  ///
  /// In en, this message translates to:
  /// **'Import songs'**
  String get importSongs;

  /// No description provided for @importSongsHint.
  ///
  /// In en, this message translates to:
  /// **'A .zip from Export, or a single song file'**
  String get importSongsHint;

  /// No description provided for @addStarterSongs.
  ///
  /// In en, this message translates to:
  /// **'Add starter songs'**
  String get addStarterSongs;

  /// No description provided for @addStarterSongsHint.
  ///
  /// In en, this message translates to:
  /// **'Public-domain campfire classics'**
  String get addStarterSongsHint;

  /// No description provided for @songsImported.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No songs found in that file.} =1{1 song added.} other{{count} songs added.}}'**
  String songsImported(int count);

  /// No description provided for @starterSongsAdded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{The starter songs are already in your songbook.} =1{1 starter song added.} other{{count} starter songs added.}}'**
  String starterSongsAdded(int count);

  /// No description provided for @importError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read that file.'**
  String get importError;

  /// No description provided for @nothingToExport.
  ///
  /// In en, this message translates to:
  /// **'Your songbook is empty. There\'s nothing to export.'**
  String get nothingToExport;

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'Libre Tab is free software under the GNU GPL 3.0 or later. It works offline and collects no data.'**
  String get aboutBody;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get licenses;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get dangerZone;

  /// No description provided for @deleteAllSongs.
  ///
  /// In en, this message translates to:
  /// **'Delete all songs'**
  String get deleteAllSongs;

  /// No description provided for @deleteAllSongsHint.
  ///
  /// In en, this message translates to:
  /// **'Removes every song from this phone'**
  String get deleteAllSongsHint;

  /// No description provided for @deleteAllTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delete your only song?} other{Delete all {count} songs?}}'**
  String deleteAllTitle(int count);

  /// No description provided for @deleteAllBody.
  ///
  /// In en, this message translates to:
  /// **'Your setlists will be left empty. To keep a copy, export your songs first.'**
  String get deleteAllBody;

  /// No description provided for @exportFirst.
  ///
  /// In en, this message translates to:
  /// **'Export first'**
  String get exportFirst;

  /// No description provided for @deleteAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get deleteAllConfirm;

  /// No description provided for @songsDeleted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song deleted.} other{{count} songs deleted.}}'**
  String songsDeleted(int count);

  /// No description provided for @songDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted “{title}”.'**
  String songDeleted(String title);

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @swipeSetlist.
  ///
  /// In en, this message translates to:
  /// **'Setlist'**
  String get swipeSetlist;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
