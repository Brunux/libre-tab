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
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get emptySongbook => 'Your songbook is empty.\nAdd your first song.';

  @override
  String get songTitlePlaceholder => 'Song';

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
}
