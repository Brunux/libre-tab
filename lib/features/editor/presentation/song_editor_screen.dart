import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:libre_tab/app/router.dart';
import 'package:libre_tab/app/theme/app_theme.dart';
import 'package:libre_tab/app/theme/libre_colors.dart';
import 'package:libre_tab/core/chordpro/chord_sheet_importer.dart';
import 'package:libre_tab/core/chordpro/chordpro_parser.dart';
import 'package:libre_tab/core/chordpro/song_header.dart';
import 'package:libre_tab/core/device/app_settings.dart';
import 'package:libre_tab/core/files/photo_picker.dart';
import 'package:libre_tab/core/files/song_files.dart';
import 'package:libre_tab/core/ocr/ocr_layout.dart';
import 'package:libre_tab/core/ocr/text_recognizer.dart';
import 'package:libre_tab/core/widgets/motion.dart';
import 'package:libre_tab/core/widgets/placeholder_body.dart';
import 'package:libre_tab/core/widgets/readable_width.dart';
import 'package:libre_tab/features/library/data/song_repository.dart';
import 'package:libre_tab/features/library/presentation/widgets/song_actions.dart';
import 'package:libre_tab/features/song_view/presentation/widgets/song_sheet.dart';
import 'package:libre_tab/l10n/l10n.dart';

/// Add a new song ([songId] null) or edit an existing one.
///
/// Title and artist are fields; everything else is one text box that takes
/// chords-over-lyrics or ChordPro. The preview shows exactly what will be
/// saved (docs/SONG_FORMAT.md § Importing chords-over-lyrics).
class SongEditorScreen extends ConsumerStatefulWidget {
  const SongEditorScreen({this.songId, this.initialText, super.key});

  final int? songId;

  /// A new song's text to start from, e.g. a file opened from another app.
  /// Handled like a file picked with "Open file"; nothing is saved yet.
  final String? initialText;

  @override
  ConsumerState<SongEditorScreen> createState() => _SongEditorScreenState();
}

class _SongEditorScreenState extends ConsumerState<SongEditorScreen> {
  final _title = TextEditingController();
  final _artist = TextEditingController();
  final _content = TextEditingController();

  late bool _loading = widget.songId != null;
  bool _missing = false;
  bool _saving = false;

  /// Edit the text, see it as a song, or see the ChordPro to be saved.
  _Mode _mode = _Mode.edit;

  /// While photos are being read: (photo, of how many).
  (int, int)? _scanning;
  String _savedState = _stateOf('', '', '');

  bool get _isNew => widget.songId == null;

  static String _stateOf(String title, String artist, String content) =>
      '$title\u0000$artist\u0000$content';

  String get _currentState =>
      _stateOf(_title.text, _artist.text, _content.text);

  bool get _dirty => _currentState != _savedState;

  @override
  void initState() {
    super.initState();
    for (final c in [_title, _artist, _content]) {
      c.addListener(_changed);
    }
    if (!_isNew) unawaited(_load());
    if (widget.initialText case final text? when _isNew) {
      _fill(SongHeader.split(text));
    }
  }

  @override
  void dispose() {
    for (final c in [_title, _artist, _content]) {
      c.dispose();
    }
    super.dispose();
  }

  void _changed() => setState(() {});

  Future<void> _load() async {
    final entry = await ref
        .read(songRepositoryProvider)
        .getSong(widget.songId!);
    if (!mounted) return;
    if (entry == null) {
      setState(() {
        _loading = false;
        _missing = true;
      });
      return;
    }
    _fill(SongHeader.split(entry.body));
    setState(() {
      _loading = false;
      _savedState = _currentState;
    });
  }

  void _fill(SongHeader header) {
    if (header.title.isNotEmpty) _title.text = header.title;
    if (header.artist.isNotEmpty) _artist.text = header.artist;
    _content.text = header.content;
  }

  /// What will be saved. Title/artist lines pasted into the text box are
  /// taken out of it; they fill the fields when those are empty.
  SongHeader _song(ImportResult result) {
    final pasted = SongHeader.split(result.chordPro);
    return SongHeader(
      title: _title.text.trim().isEmpty ? pasted.title : _title.text,
      artist: _artist.text.trim().isEmpty ? pasted.artist : _artist.text,
      content: pasted.content,
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final repository = ref.read(songRepositoryProvider);
    final body = _song(ChordSheetImporter.convert(_content.text)).compose();
    try {
      if (_isNew) {
        final id = await repository.addSong(body);
        if (mounted) context.pushReplacement(Routes.song(id));
      } else {
        await repository.updateSong(widget.songId!, body);
        // Navigator.pop, not maybePop: the song is saved, skip the guard.
        if (mounted) Navigator.of(context).pop();
      }
    } on Object {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack(context.l10n.saveError);
    }
  }

  /// Most songs come from a website or a note: one tap puts the copied
  /// text in, handled like a file.
  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (!mounted) return;
    if (text.isEmpty) {
      _snack(context.l10n.clipboardEmpty);
      return;
    }
    if (text.length > SongFiles.maxSongBytes) {
      _snack(context.l10n.pasteTooBig);
      return;
    }
    _fill(SongHeader.split(text));
  }

  Future<void> _openFile() async {
    try {
      final text = await ref.read(songFilesProvider).pickSongText();
      if (text != null && mounted) _fill(SongHeader.split(text));
    } on FormatException {
      if (mounted) _snack(context.l10n.notASongFile);
    } on FileTooBigException {
      if (mounted) _snack(context.l10n.fileTooBig);
    }
  }

  /// Camera import: a photo from the camera or the library, read on the
  /// device, laid out as chords-over-lyrics (lib/core/ocr/ocr_layout.dart)
  /// and put in the text box for review, like Open file. A second scan is
  /// added after the first, for songs that run over two pages.
  Future<void> _scan() async {
    final l10n = context.l10n;
    final source = await showModalBottomSheet<PhotoSource>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.takePhoto),
              onTap: () => Navigator.of(sheet).pop(PhotoSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.choosePhoto),
              onTap: () => Navigator.of(sheet).pop(PhotoSource.library),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    await _scanFrom(source);
  }

  Future<void> _scanFrom(PhotoSource source) async {
    final l10n = context.l10n;
    final List<String> paths;
    try {
      paths = await ref.read(photoPickerProvider).pick(source);
    } on PlatformException {
      // The camera was refused (or isn't there).
      if (mounted) await _cameraRefused();
      return;
    }
    if (paths.isEmpty || !mounted) return;

    final recognizer = ref.read(textRecognizerProvider);
    final photos = ref.read(photoPickerProvider);
    var readAny = false;
    var failed = false;
    try {
      // Pages in the order picked, each added below the last.
      for (final (i, path) in paths.indexed) {
        setState(() => _scanning = (i + 1, paths.length));
        try {
          final scanned = OcrLayout.read(await recognizer.recognize(path));
          if (!mounted) return;
          if (scanned.isEmpty) continue;
          readAny = true;
          if (scanned.title case final title? when _title.text.trim().isEmpty) {
            _title.text = title;
          }
          if (scanned.artist case final artist?
              when _artist.text.trim().isEmpty) {
            _artist.text = artist;
          }
          if (scanned.text.isEmpty) continue;
          final before = _content.text.trimRight();
          _content.text = before.isEmpty
              ? scanned.text
              : '$before\n\n${scanned.text}';
        } on TextRecognitionException {
          failed = true;
        } finally {
          unawaited(photos.discard(path));
        }
      }
    } finally {
      if (mounted) setState(() => _scanning = null);
    }
    if (!mounted) return;
    _snack(
      readAny
          ? l10n.scanDone
          : failed
          ? l10n.scanError
          : l10n.noTextFound,
    );
  }

  bool get _isBlank => [
    _title,
    _artist,
    _content,
  ].every((c) => c.text.trim().isEmpty);

  /// Add song only: empties title, artist and text to begin another song,
  /// with Undo in case it was tapped by mistake.
  void _startOver() {
    final l10n = context.l10n;
    final (title, artist, content) = (
      _title.text,
      _artist.text,
      _content.text,
    );
    _title.clear();
    _artist.clear();
    _content.clear();
    showUndoSnackBar(
      ScaffoldMessenger.of(context),
      l10n,
      message: l10n.startedOver,
      onUndo: () async {
        if (!mounted) return;
        _title.text = title;
        _artist.text = artist;
        _content.text = content;
      },
    );
  }

  /// The system asks for the camera only once. After a refusal, say where
  /// to allow it (with a way straight there), and offer the photo library,
  /// which needs no permission.
  Future<void> _cameraRefused() async {
    final l10n = context.l10n;
    final choice = await showDialog<_CameraChoice>(
      context: context,
      builder: (dialog) => AlertDialog(
        icon: const Icon(Icons.no_photography_outlined),
        title: Text(l10n.cameraDeniedTitle),
        content: Text(l10n.cameraDeniedBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(_CameraChoice.library),
            child: Text(l10n.choosePhoto),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialog).pop(_CameraChoice.settings),
            child: Text(l10n.openSettings),
          ),
        ],
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case _CameraChoice.library:
        await _scanFrom(PhotoSource.library);
      case _CameraChoice.settings:
        await ref.read(appSettingsProvider).open();
      case null:
        break;
    }
  }

  /// Replaces any message still showing, so the latest one is seen now.
  void _snack(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _confirmDiscard() async {
    final l10n = context.l10n;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.discardTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l10n.keepEditing),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l10n.discard),
          ),
        ],
      ),
    );
    if ((discard ?? false) && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final result = ChordSheetImporter.convert(_content.text);
    final song = _song(result);
    final canSave =
        !_saving &&
        song.title.trim().isNotEmpty &&
        song.content.trim().isNotEmpty;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_confirmDiscard());
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: l10n.cancel,
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(_isNew ? l10n.addSong : l10n.editSong),
          actions: [
            if (_isNew)
              IconButton(
                tooltip: l10n.startOver,
                icon: const Icon(Icons.restart_alt),
                onPressed: _isBlank ? null : _startOver,
              ),
            FilledButton(
              onPressed: canSave ? _save : null,
              child: Text(l10n.save),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: ReadableWidth(
          child: _loading
              ? const SizedBox.shrink()
              : _missing
              ? PlaceholderBody(message: l10n.songNotFound)
              : _form(context, result, song),
        ),
      ),
    );
  }

  Widget _form(BuildContext context, ImportResult result, SongHeader song) {
    final l10n = context.l10n;
    final colors = context.colors;
    final hasContent = _content.text.trim().isNotEmpty;
    final body = song.compose();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        TextField(
          controller: _title,
          inputFormatters: [
            LengthLimitingTextInputFormatter(SongFiles.maxNameChars),
          ],
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: l10n.titleLabel,
            errorText: hasContent && song.title.trim().isEmpty
                ? l10n.titleRequired
                : null,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _artist,
          inputFormatters: [
            LengthLimitingTextInputFormatter(SongFiles.maxNameChars),
          ],
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: l10n.artistLabel),
        ),
        const SizedBox(height: 16),
        SegmentedButton<_Mode>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: _Mode.edit, label: Text(l10n.editTab)),
            ButtonSegment(value: _Mode.preview, label: Text(l10n.previewTab)),
            ButtonSegment(value: _Mode.source, label: Text(l10n.chordProTab)),
          ],
          selected: {_mode},
          onSelectionChanged: (s) {
            // Seeing the result: the keyboard steps aside.
            if (s.single != _Mode.edit) FocusScope.of(context).unfocus();
            setState(() => _mode = s.single);
          },
        ),
        const SizedBox(height: 16),
        ...switch (_mode) {
          _Mode.edit => _editor(context, result, hasContent),
          _Mode.preview || _Mode.source => [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border.all(color: colors.line),
                borderRadius: BorderRadius.circular(14),
              ),
              child: !hasContent
                  ? Text(
                      l10n.previewEmpty,
                      style: TextStyle(color: colors.muted),
                    )
                  : _mode == _Mode.source
                  ? SelectableText(
                      body,
                      style: TextStyle(
                        fontFamily: AppFonts.mono,
                        fontSize: 12,
                        height: 1.6,
                        color: colors.text,
                      ),
                    )
                  : SongSheet(song: ChordProParser.parse(body), fontSize: 17),
            ),
          ],
        },
      ],
    );
  }

  /// The Edit tab: ways to bring a song in (big while there's nothing yet),
  /// the text box, and what the import made of it.
  List<Widget> _editor(
    BuildContext context,
    ImportResult result,
    bool hasContent,
  ) {
    final l10n = context.l10n;
    final colors = context.colors;
    final busy = _scanning != null;
    final sources = [
      (Icons.content_paste, l10n.paste, l10n.pasteHint, _paste),
      (
        Icons.document_scanner_outlined,
        l10n.scanPhoto,
        l10n.scanPhotoHint,
        _scan,
      ),
      (Icons.file_open_outlined, l10n.openFile, l10n.openFileHint, _openFile),
    ];
    return [
      // With text, the big cards fold down into two small buttons.
      AnimatedSize(
        duration: context.motion(const Duration(milliseconds: 240)),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: context.motion(const Duration(milliseconds: 200)),
          child: hasContent || busy
              ? Align(
                  key: const ValueKey('buttons'),
                  alignment: AlignmentDirectional.centerStart,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (icon, label, _, action) in sources.skip(1))
                        OutlinedButton.icon(
                          onPressed: busy ? null : action,
                          icon: Icon(icon),
                          label: Text(label),
                        ),
                    ],
                  ),
                )
              : Column(
                  key: const ValueKey('cards'),
                  children: [
                    for (final (icon, label, hint, action) in sources)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SourceCard(
                          icon: icon,
                          label: label,
                          hint: hint,
                          onTap: action,
                        ),
                      ),
                  ],
                ),
        ),
      ),
      if (_scanning case (final current, final total)) ...[
        const SizedBox(height: 12),
        Semantics(
          liveRegion: true,
          child: Row(
            children: [
              const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(
                total == 1
                    ? l10n.readingPhoto
                    : l10n.readingPhotoOf(current, total),
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 12),
      TextField(
        controller: _content,
        // No bigger than a song file may be, however it gets in (typing,
        // the system's paste): the importer runs on it at every change.
        inputFormatters: [
          LengthLimitingTextInputFormatter(SongFiles.maxSongBytes),
        ],
        minLines: 8,
        maxLines: 16,
        keyboardType: TextInputType.multiline,
        // Chord sheets depend on exact spacing and spelling: the iOS
        // keyboard would turn "G  " into "G. " and "mazing" into "maxing".
        autocorrect: false,
        enableSuggestions: false,
        smartDashesType: SmartDashesType.disabled,
        smartQuotesType: SmartQuotesType.disabled,
        spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
        style: TextStyle(
          fontFamily: AppFonts.mono,
          fontSize: 13,
          height: 1.5,
          color: colors.text,
        ),
        decoration: InputDecoration(
          hintText: hasContent ? null : l10n.contentHintOr,
          alignLabelWithHint: true,
        ),
      ),
      if (hasContent) ...[
        const SizedBox(height: 8),
        Text(
          result.alreadyChordPro
              ? l10n.alreadyChordPro
              : l10n.importSummary(result.chordLines, result.sections),
          style: TextStyle(fontSize: 14, color: colors.muted),
        ),
      ],
    ];
  }
}

/// One way to bring a song in, big enough to be the obvious first step.
class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.icon,
    required this.label,
    required this.hint,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface2,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: colors.accent, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      hint,
                      style: TextStyle(fontSize: 14, color: colors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _CameraChoice { library, settings }

enum _Mode { edit, preview, source }
