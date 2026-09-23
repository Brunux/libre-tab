import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libre_tab/core/database/app_database.dart';
import 'package:libre_tab/features/library/application/library_providers.dart';
import 'package:libre_tab/features/library/data/setlist_repository.dart';
import 'package:libre_tab/features/library/data/song_repository.dart';
import 'package:libre_tab/features/library/presentation/widgets/setlist_name_dialog.dart';
import 'package:libre_tab/l10n/l10n.dart';

/// Actions on one song shared by the songbook's swipe actions and the song
/// view's menu (docs/DESIGN.md § Songbook).

/// Opens the "Add to setlist" sheet for [songId].
Future<void> showAddToSetlistSheet(
  BuildContext context, {
  required int songId,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => _AddToSetlistSheet(songId: songId),
);

/// Deletes [song] right away and offers Undo in a snackbar: quicker than
/// asking first, and just as safe.
Future<void> deleteSongWithUndo(
  BuildContext context,
  WidgetRef ref,
  SongEntry song,
) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final repository = ref.read(songRepositoryProvider);
  final deleted = await repository.deleteSong(song.id);
  showUndoSnackBar(
    messenger,
    l10n,
    message: l10n.songDeleted(song.title),
    onUndo: () => repository.restore(deleted),
  );
}

/// A snackbar with an Undo button, shown long enough to find the button.
void showUndoSnackBar(
  ScaffoldMessengerState messenger,
  AppLocalizations l10n, {
  required String message,
  required Future<void> Function() onUndo,
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 8),
        persist: false,
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () => unawaited(onUndo()),
        ),
      ),
    );
}

/// Every setlist with a checkbox that adds or removes this song right away,
/// plus "New setlist".
class _AddToSetlistSheet extends ConsumerWidget {
  const _AddToSetlistSheet({required this.songId});

  final int songId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final setlists = ref.watch(allSetlistsProvider).value ?? const [];
    final having = ref.watch(setlistsWithSongProvider(songId)).value ?? {};
    final repository = ref.read(setlistRepositoryProvider);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              l10n.addToSetlist,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          for (final setlist in setlists)
            CheckboxListTile(
              value: having.contains(setlist.id),
              title: Text(setlist.name),
              subtitle: Text(l10n.songCount(setlist.songCount)),
              onChanged: (on) => on ?? false
                  ? repository.addSong(setlist.id, songId)
                  : repository.removeSong(setlist.id, songId),
            ),
          ListTile(
            leading: const Icon(Icons.playlist_add),
            title: Text(l10n.newSetlist),
            onTap: () async {
              final name = await showSetlistNameDialog(context);
              if (name == null) return;
              final id = await repository.create(name);
              await repository.addSong(id, songId);
            },
          ),
        ],
      ),
    );
  }
}
