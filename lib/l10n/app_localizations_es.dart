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
  String get themeLabel => 'Tema';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeRedNight => 'Noche roja';

  @override
  String get themeLight => 'Claro';

  @override
  String get leaveRedNight => 'Salir de noche roja';

  @override
  String get chooseTheme => 'Elegir tema';

  @override
  String get searchHint => 'Buscar canciones, artistas o letras';

  @override
  String get clearSearch => 'Borrar búsqueda';

  @override
  String get browseSongs => 'Ver canciones';

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

  @override
  String get chordsMenu => 'Acordes';

  @override
  String get noChords => 'Esta canción no tiene acordes.';

  @override
  String get noDiagram => 'Aún no hay diagrama para este acorde.';

  @override
  String get diagramLegend =>
      '× no tocar · ○ al aire · a la izquierda: trastes · abajo: el traste de cada cuerda (0 = al aire)';

  @override
  String get keyStepper => 'Tono';

  @override
  String get capoStepper => 'Cejilla';

  @override
  String get capoNone => 'Sin';

  @override
  String get transposeDown => 'Bajar tono';

  @override
  String get transposeUp => 'Subir tono';

  @override
  String get capoDown => 'Bajar cejilla';

  @override
  String get capoUp => 'Subir cejilla';

  @override
  String get textSize => 'Letra';

  @override
  String get smallerText => 'Letra más pequeña';

  @override
  String get largerText => 'Letra más grande';

  @override
  String get slower => 'Más lento';

  @override
  String get faster => 'Más rápido';

  @override
  String get startScroll => 'Iniciar desplazamiento';

  @override
  String get pauseScroll => 'Pausar desplazamiento';

  @override
  String speedLabel(int speed) {
    return 'Velocidad $speed';
  }

  @override
  String soundsIn(String key, int fret, String shapes) {
    return 'Suena en $key · Cejilla $fret · posiciones de $shapes';
  }

  @override
  String get tunerIntroTitle => 'Afina tu guitarra';

  @override
  String get tunerIntroBody =>
      'El afinador escucha tu guitarra con el micrófono. No se graba ni se guarda nada.';

  @override
  String get startTuner => 'Iniciar afinador';

  @override
  String get micDeniedTitle => 'El micrófono está desactivado';

  @override
  String get micDeniedBody =>
      'Para afinar, Libre Tab necesita el micrófono. Permítelo para Libre Tab en Ajustes y vuelve aquí.';

  @override
  String get tryAgain => 'Reintentar';

  @override
  String get playAString => 'Toca una cuerda';

  @override
  String get inTune => 'Afinada';

  @override
  String get tooLow => 'Muy baja · aprieta';

  @override
  String get tooHigh => 'Muy alta · afloja';

  @override
  String centsOff(String cents) {
    return '$cents cents';
  }

  @override
  String get tuningLabel => 'Afinación';

  @override
  String get tuningStandard => 'Estándar';

  @override
  String get tuningHalfStepDown => 'Medio tono abajo';

  @override
  String get tuningDropD => 'Drop D';

  @override
  String get tuningDadgad => 'DADGAD';

  @override
  String get tuningOpenG => 'Sol abierta';

  @override
  String get tuningOpenD => 'Re abierta';

  @override
  String get stringsLabel => 'Cuerdas';

  @override
  String get autoDetect => 'Detección automática';

  @override
  String stringNumber(String number) {
    return '$numberª';
  }

  @override
  String stringButton(String number, String note) {
    return '$number cuerda, $note';
  }

  @override
  String a4Label(int hz) {
    return 'La4 = $hz Hz';
  }

  @override
  String get a4Title => 'Tono de referencia';

  @override
  String get a4Help =>
      'Casi toda la música usa La4 = 440 Hz. Cámbialo solo para igualar otro instrumento.';

  @override
  String get a4Reset => 'Volver a 440';

  @override
  String get filterSetlists => 'Repertorios';

  @override
  String get newSetlist => 'Nuevo repertorio';

  @override
  String get setlistNameLabel => 'Nombre';

  @override
  String get setlistNameHint => 'Fogata del viernes';

  @override
  String get create => 'Crear';

  @override
  String get done => 'Listo';

  @override
  String get noSetlists =>
      'Aún no hay repertorios.\nHaz uno para tu próxima fogata.';

  @override
  String get noSetlistMatches => 'Ningún repertorio coincide con tu búsqueda.';

  @override
  String get emptySetlist => 'Este repertorio aún no tiene canciones.';

  @override
  String get setlistNotFound => 'Este repertorio ya no existe.';

  @override
  String get addSongs => 'Agregar canciones';

  @override
  String get playSetlist => 'Tocar';

  @override
  String get renameSetlist => 'Cambiar nombre';

  @override
  String deleteSetlistTitle(String name) {
    return '¿Borrar “$name”?';
  }

  @override
  String get deleteSetlistBody => 'Las canciones se quedan en tu cancionero.';

  @override
  String removeFromSetlist(String title) {
    return 'Quitar $title del repertorio';
  }

  @override
  String get addToSetlist => 'Agregar a repertorio';

  @override
  String get swipeHint => 'Desliza para la siguiente canción';

  @override
  String get songbookSection => 'Cancionero';

  @override
  String get exportSongs => 'Exportar todas las canciones';

  @override
  String get exportSongsHint => 'Un archivo .zip con un .cho por canción';

  @override
  String get importSongs => 'Importar canciones';

  @override
  String get importSongsHint => 'Un .zip de Exportar, o un archivo de canción';

  @override
  String get addStarterSongs => 'Agregar canciones de ejemplo';

  @override
  String get addStarterSongsHint => 'Clásicos de fogata de dominio público';

  @override
  String songsImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se agregaron $count canciones.',
      one: 'Se agregó 1 canción.',
      zero: 'No se encontraron canciones en ese archivo.',
    );
    return '$_temp0';
  }

  @override
  String starterSongsAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se agregaron $count canciones de ejemplo.',
      one: 'Se agregó 1 canción de ejemplo.',
      zero: 'Las canciones de ejemplo ya están en tu cancionero.',
    );
    return '$_temp0';
  }

  @override
  String get importError => 'No se pudo leer ese archivo.';

  @override
  String get nothingToExport =>
      'Tu cancionero está vacío. No hay nada que exportar.';

  @override
  String get aboutSection => 'Acerca de';

  @override
  String get aboutBody =>
      'Libre Tab es software libre bajo la GNU GPL 3.0 o posterior. Funciona sin conexión y no recopila datos.';

  @override
  String get licenses => 'Licencias';

  @override
  String versionLabel(String version, int build) {
    return 'Versión $version ($build)';
  }

  @override
  String get dangerZone => 'Zona de riesgo';

  @override
  String get deleteAllSongs => 'Borrar todas las canciones';

  @override
  String get deleteAllSongsHint => 'Quita todas las canciones de este teléfono';

  @override
  String deleteAllTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¿Borrar las $count canciones?',
      one: '¿Borrar tu única canción?',
    );
    return '$_temp0';
  }

  @override
  String get deleteAllBody =>
      'Tus repertorios quedarán vacíos. Para guardar una copia, exporta tus canciones primero.';

  @override
  String get exportFirst => 'Exportar primero';

  @override
  String get deleteAllConfirm => 'Borrar todo';

  @override
  String songsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se borraron $count canciones.',
      one: 'Se borró 1 canción.',
    );
    return '$_temp0';
  }

  @override
  String songDeleted(String title) {
    return 'Se borró “$title”.';
  }

  @override
  String get undo => 'Deshacer';

  @override
  String get swipeSetlist => 'Repertorio';

  @override
  String get findDuplicates => 'Buscar duplicados';

  @override
  String get findDuplicatesHint => 'Canciones con el mismo título y artista';

  @override
  String get noDuplicates => 'No se encontraron duplicados.';

  @override
  String get exactCopies => 'Copias exactas';

  @override
  String get exactCopiesHint =>
      'Mismo título, artista y letra. Se conserva una de cada una, con la estrella de favorita y los lugares en repertorios que tenían las copias.';

  @override
  String removeCopies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Quitar $count copias',
      one: 'Quitar 1 copia',
    );
    return '$_temp0';
  }

  @override
  String copiesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count copias',
      one: '1 copia',
    );
    return '$_temp0';
  }

  @override
  String copiesRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se quitaron $count copias.',
      one: 'Se quitó 1 copia.',
    );
    return '$_temp0';
  }

  @override
  String get differentVersions => 'Mismo título, distinta letra';

  @override
  String get differentVersionsHint =>
      'Pueden ser versiones distintas. Ábrelas para compararlas y borra la que no quieras.';

  @override
  String addedOn(String date) {
    return 'Agregada el $date';
  }

  @override
  String get scanPhoto => 'Escanear foto';

  @override
  String get takePhoto => 'Tomar una foto';

  @override
  String get choosePhoto => 'Elegir de tus fotos';

  @override
  String get readingPhoto => 'Leyendo la foto…';

  @override
  String get noTextFound =>
      'No se encontró texto en esa foto. Prueba una foto más cercana y nítida, con buena luz.';

  @override
  String get scanDone => 'Revisa los acordes contra la foto antes de guardar.';

  @override
  String get scanError => 'No se pudo leer esa foto.';

  @override
  String readingPhotoOf(int current, int total) {
    return 'Leyendo la foto $current de $total…';
  }

  @override
  String get startOver => 'Empezar de nuevo';

  @override
  String get startedOver => 'Se vaciaron el título, el artista y el texto.';

  @override
  String get fretMuted => 'no se toca';

  @override
  String get fretOpen => 'al aire';

  @override
  String diagramFrets(String frets) {
    return 'Trastes desde la cuerda más gruesa: $frets';
  }

  @override
  String get searchSetlistsHint => 'Buscar repertorios';

  @override
  String get fileTooBig =>
      'Ese archivo es demasiado grande para ser una canción.';

  @override
  String get privacyTitle => 'Privacidad';

  @override
  String get privacySummary =>
      'Libre Tab no recopila datos. No tiene cuenta, anuncios ni analíticas, y nunca se conecta a internet.';

  @override
  String get privacySongsTitle => 'Tus canciones';

  @override
  String get privacySongsBody =>
      'Tus canciones, repertorios y ajustes se quedan en este dispositivo. Solo salen cuando los compartes o exportas. El respaldo de tu dispositivo los incluye, como los datos de cualquier app.';

  @override
  String get privacyMicTitle => 'Micrófono';

  @override
  String get privacyMicBody =>
      'El afinador solo escucha mientras la pestaña Afinador está en pantalla. El sonido se analiza en el dispositivo y se descarta al instante: nada se graba, guarda ni envía.';

  @override
  String get privacyPhotosTitle => 'Cámara y fotos';

  @override
  String get privacyPhotosBody =>
      'Escanear foto lee una canción de una foto que tomas o eliges. El texto se lee en el dispositivo y la foto no se guarda. Al elegir fotos, la app solo ve las que eliges.';

  @override
  String get privacyMore => 'Política de privacidad completa y preguntas:';

  @override
  String get openSettings => 'Abrir Ajustes';

  @override
  String get cameraDeniedTitle => 'La cámara está desactivada';

  @override
  String get cameraDeniedBody =>
      'Para tomar fotos de canciones, permite la cámara para Libre Tab en Ajustes. Aun así puedes elegir fotos que ya tienes.';
}
