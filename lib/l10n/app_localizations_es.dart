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
  String get editSong => 'Editar canción';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

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

  @override
  String get searchHint => 'Buscar canciones, artistas o letras';

  @override
  String get clearSearch => 'Borrar búsqueda';

  @override
  String get filterAll => 'Todas';

  @override
  String get filterFavorites => 'Favoritas';

  @override
  String songCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canciones',
      one: '1 canción',
    );
    return '$_temp0';
  }

  @override
  String get emptySongbook =>
      'Tu cancionero está vacío.\nAgrega tu primera canción.';

  @override
  String get noFavorites =>
      'Aún no hay favoritas.\nToca la estrella de una canción para agregarla.';

  @override
  String get loadError => 'No se pudo abrir tu cancionero.';

  @override
  String get noMatches => 'Ninguna canción coincide con tu búsqueda.';

  @override
  String keyLabel(String key) {
    return 'Tono $key';
  }

  @override
  String capoLabel(int fret) {
    return 'Cejilla $fret';
  }

  @override
  String get songNotFound => 'Esta canción no está en tu cancionero.';

  @override
  String get addFavorite => 'Agregar a favoritas';

  @override
  String get removeFavorite => 'Quitar de favoritas';

  @override
  String get moreActions => 'Más';

  @override
  String get share => 'Compartir';

  @override
  String get delete => 'Eliminar';

  @override
  String deleteTitle(String title) {
    return '¿Eliminar “$title”?';
  }

  @override
  String get deleteBody => 'No se puede deshacer.';

  @override
  String get chorusLabel => 'Coro';

  @override
  String get bridgeLabel => 'Puente';

  @override
  String get titleLabel => 'Título';

  @override
  String get titleRequired => 'Escribe un título';

  @override
  String get artistLabel => 'Artista';

  @override
  String get contentLabel => 'Pega acordes sobre la letra, o ChordPro';

  @override
  String get openFile => 'Abrir archivo';

  @override
  String get cameraLater => 'Cámara (pronto)';

  @override
  String get notASongFile =>
      'Ese archivo no es una canción (.cho, .chopro, .chordpro, .crd, .txt).';

  @override
  String get resultLabel => 'Resultado';

  @override
  String get previewTab => 'Vista previa';

  @override
  String get chordProTab => 'ChordPro';

  @override
  String importSummary(int chordLines, int sections) {
    return 'Líneas de acordes: $chordLines · Secciones: $sections';
  }

  @override
  String get alreadyChordPro => 'Ya está en formato ChordPro.';

  @override
  String get previewEmpty => 'La canción aparecerá aquí mientras escribes.';

  @override
  String get discardTitle => '¿Descartar cambios?';

  @override
  String get discard => 'Descartar';

  @override
  String get keepEditing => 'Seguir editando';

  @override
  String get saveError => 'No se pudo guardar la canción.';
}
