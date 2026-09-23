import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libre_tab/app/theme/app_theme.dart';
import 'package:libre_tab/app/theme/libre_colors.dart';
import 'package:libre_tab/app/theme/theme_controller.dart';
import 'package:libre_tab/core/files/song_files.dart';
import 'package:libre_tab/features/library/data/song_repository.dart';
import 'package:libre_tab/features/library/data/songbook_archive.dart';
import 'package:libre_tab/features/library/data/starter_songs.dart';
import 'package:libre_tab/l10n/l10n.dart';

/// Theme, songbook export/import/starter songs, and About
/// (docs/DESIGN.md § Settings).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final variant = ref.watch(themeVariantProvider);
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
