import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:libre_tab/app/router.dart';
import 'package:libre_tab/app/theme/app_theme.dart';
import 'package:libre_tab/app/theme/libre_colors.dart';
import 'package:libre_tab/core/chordpro/chord_sheet_importer.dart';
import 'package:libre_tab/core/chordpro/chordpro_parser.dart';
import 'package:libre_tab/core/chordpro/song_header.dart';
import 'package:libre_tab/core/files/song_files.dart';
import 'package:libre_tab/core/widgets/placeholder_body.dart';
import 'package:libre_tab/features/library/data/song_repository.dart';
import 'package:libre_tab/features/song_view/presentation/widgets/song_sheet.dart';
import 'package:libre_tab/l10n/l10n.dart';

/// Add a new song ([songId] null) or edit an existing one.
///
/// Title and artist are fields; everything else is one text box that takes
/// chords-over-lyrics or ChordPro. The preview shows exactly what will be
/// saved (docs/SONG_FORMAT.md § Importing chords-over-lyrics).
class SongEditorScreen extends ConsumerStatefulWidget {
  const SongEditorScreen({this.songId, super.key});

  final int? songId;

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
  bool _showSource = false;
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

  Future<void> _openFile() async {
    try {
      final text = await ref.read(songFilesProvider).pickSongText();
      if (text != null && mounted) _fill(SongHeader.split(text));
    } on FormatException {
      if (mounted) _snack(context.l10n.notASongFile);
    }
  }

  void _snack(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

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
            FilledButton(
              onPressed: canSave ? _save : null,
              child: Text(l10n.save),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: _loading
            ? const SizedBox.shrink()
            : _missing
            ? PlaceholderBody(message: l10n.songNotFound)
            : _form(context, result, song),
      ),
    );
  }

  Widget _form(BuildContext context, ImportResult result, SongHeader song) {
    final l10n = context.l10n;
    final colors = context.colors;
    final hasContent = _content.text.trim().isNotEmpty;
    final body = song.compose();
    final sectionLabel = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      letterSpacing: 1,
      color: colors.muted,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        TextField(
          controller: _title,
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
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: l10n.artistLabel),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _openFile,
              icon: const Icon(Icons.file_open_outlined),
              label: Text(l10n.openFile),
            ),
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(l10n.cameraLater),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _content,
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
            hintText: l10n.contentLabel,
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Text(l10n.resultLabel.toUpperCase(), style: sectionLabel),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: false, label: Text(l10n.previewTab)),
                ButtonSegment(value: true, label: Text(l10n.chordProTab)),
              ],
              selected: {_showSource},
              onSelectionChanged: (s) => setState(() => _showSource = s.single),
            ),
          ],
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
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.line),
            borderRadius: BorderRadius.circular(14),
          ),
          child: !hasContent
              ? Text(l10n.previewEmpty, style: TextStyle(color: colors.muted))
              : _showSource
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
    );
  }
}
