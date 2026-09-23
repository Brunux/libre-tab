import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libre_tab/app/theme/app_theme.dart';
import 'package:libre_tab/app/theme/libre_colors.dart';
import 'package:libre_tab/app/theme/theme_controller.dart';
import 'package:libre_tab/core/files/song_files.dart';
import 'package:libre_tab/features/library/application/library_providers.dart';
import 'package:libre_tab/features/library/data/song_repository.dart';
import 'package:libre_tab/features/library/data/songbook_archive.dart';
import 'package:libre_tab/features/library/data/starter_songs.dart';
import 'package:libre_tab/features/library/presentation/widgets/song_actions.dart';
import 'package:libre_tab/l10n/l10n.dart';

/// Theme, songbook export/import/starter songs, and About
/// (docs/DESIGN.md § Settings).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final variant = ref.watch(themeVariantProvider);
    final songCount = ref.watch(allSongsProvider).value?.length ?? 0;
    final danger = Theme.of(context).colorScheme.error;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          _SectionLabel(l10n.themeLabel),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SegmentedButton<AppThemeVariant>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: AppThemeVariant.dark,
                  label: Text(l10n.themeDark),
                ),
                ButtonSegment(
                  value: AppThemeVariant.redNight,
                  label: Text(l10n.themeRedNight),
                ),
                ButtonSegment(
                  value: AppThemeVariant.light,
                  label: Text(l10n.themeLight),
                ),
              ],
              selected: {variant},
              onSelectionChanged: (selection) =>
                  ref.read(themeVariantProvider.notifier).variant =
                      selection.single,
            ),
          ),
          const SizedBox(height: 28),
          _SectionLabel(l10n.songbookSection),
          ListTile(
            leading: const Icon(Icons.ios_share),
            title: Text(l10n.exportSongs),
            subtitle: Text(l10n.exportSongsHint),
            onTap: () => _export(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.file_open_outlined),
            title: Text(l10n.importSongs),
            subtitle: Text(l10n.importSongsHint),
            onTap: () => _import(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.library_music_outlined),
            title: Text(l10n.addStarterSongs),
            subtitle: Text(l10n.addStarterSongsHint),
            onTap: () => addStarterSongs(context, ref),
          ),
          const SizedBox(height: 28),
          _SectionLabel(l10n.aboutSection),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(l10n.aboutBody),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l10n.licenses),
            onTap: () => showLicensePage(
              context: context,
              applicationName: l10n.appTitle,
              applicationLegalese: 'GNU GPL 3.0 or later',
            ),
          ),
          // Last, apart from everything else, in the error color, and off
          // when there's nothing to delete (docs/DESIGN.md § Settings).
          const SizedBox(height: 28),
          _SectionLabel(l10n.dangerZone),
          ListTile(
            enabled: songCount > 0,
            iconColor: danger,
            textColor: danger,
            leading: const Icon(Icons.delete_forever_outlined),
            title: Text(l10n.deleteAllSongs),
            subtitle: Text(l10n.deleteAllSongsHint),
            onTap: () => _deleteAll(context, ref, songCount),
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final songs = await ref.read(songRepositoryProvider).allSongs();
    if (songs.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.nothingToExport)));
      return;
    }
    final zip = SongbookArchive.export([
      for (final song in songs) (title: song.title, body: song.body),
    ]);
    final date = DateTime.now().toIso8601String().substring(0, 10);
    await ref
        .read(songFilesProvider)
        .shareSongbook(zip, fileName: 'libre-tab-songs-$date.zip');
  }

  /// Says exactly what will be lost, offers to export first, keeps Cancel
  /// as the safe choice, and still offers Undo afterwards.
  Future<void> _deleteAll(
    BuildContext context,
    WidgetRef ref,
    int songCount,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final choice = await showDialog<_DeleteAllChoice>(
      context: context,
      builder: (dialog) {
        final scheme = Theme.of(dialog).colorScheme;
        return AlertDialog(
          icon: Icon(Icons.warning_amber_rounded, color: scheme.error),
          title: Text(l10n.deleteAllTitle(songCount)),
          content: Text(l10n.deleteAllBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialog).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialog).pop(_DeleteAllChoice.exportFirst),
              child: Text(l10n.exportFirst),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
              onPressed: () =>
                  Navigator.of(dialog).pop(_DeleteAllChoice.delete),
              child: Text(l10n.deleteAllConfirm),
            ),
          ],
        );
      },
    );
    if (!context.mounted) return;
    switch (choice) {
      case null:
        return;
      case _DeleteAllChoice.exportFirst:
        await _export(context, ref);
      case _DeleteAllChoice.delete:
        final repository = ref.read(songRepositoryProvider);
        final deleted = await repository.deleteAllSongs();
        showUndoSnackBar(
          messenger,
          l10n,
          message: l10n.songsDeleted(deleted.count),
          onUndo: () => repository.restore(deleted),
        );
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final file = await ref.read(songFilesProvider).pickFile();
    if (file == null) return;
    await importSongFile(
      ref.read(songRepositoryProvider),
      messenger,
      l10n,
      name: file.name,
      bytes: file.bytes,
    );
  }
}

/// Adds every song in a `.zip` or song file and says how many were added.
/// Shared with files opened from other apps (lib/app/app.dart).
Future<void> importSongFile(
  SongRepository songs,
  ScaffoldMessengerState messenger,
  AppLocalizations l10n, {
  required String name,
  required List<int> bytes,
}) async {
  final List<String> bodies;
  try {
    bodies = SongbookArchive.songsFrom(name, bytes);
  } on FormatException {
    final zipOrSong =
        SongFiles.isSongFile(name) || name.toLowerCase().endsWith('.zip');
    messenger.showSnackBar(
      SnackBar(content: Text(zipOrSong ? l10n.importError : l10n.notASongFile)),
    );
    return;
  }
  final message = l10n.songsImported(await songs.importSongs(bodies));
  messenger.showSnackBar(SnackBar(content: Text(message)));
}

/// Adds the starter songs that aren't in the songbook and says how many.
Future<void> addStarterSongs(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final added = await ref.read(starterSongsProvider).addMissing();
  messenger.showSnackBar(
    SnackBar(content: Text(l10n.starterSongsAdded(added))),
  );
}

enum _DeleteAllChoice { exportFirst, delete }

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
        color: context.colors.muted,
      ),
    ),
  );
}
