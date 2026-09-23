// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Libre Tab';

  @override
  String get tabSongbook => 'Cancionero';

  @override
  String get tabTuner => 'Afinador';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get addSong => 'Agregar canción';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get emptySongbook =>
      'Tu cancionero está vacío.\nAgrega tu primera canción.';

  @override
  String get songTitlePlaceholder => 'Canción';

  @override
  String get comingSoon => 'Llegará en una próxima etapa.';

  @override
  String get themeLabel => 'Tema';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeRedNight => 'Noche roja';

  @override
  String get themeLight => 'Claro';

  @override
  String get switchTheme => 'Cambiar tema';
}
