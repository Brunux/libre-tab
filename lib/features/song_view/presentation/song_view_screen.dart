import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:libre_tab/app/router.dart';
import 'package:libre_tab/app/theme/libre_colors.dart';
import 'package:libre_tab/app/theme/theme_controller.dart';
import 'package:libre_tab/core/chordpro/chordpro_parser.dart';
import 'package:libre_tab/core/database/app_database.dart';
import 'package:libre_tab/core/files/song_files.dart';
import 'package:libre_tab/core/widgets/placeholder_body.dart';
import 'package:libre_tab/features/library/application/library_providers.dart';
import 'package:libre_tab/features/library/data/song_repository.dart';
import 'package:libre_tab/features/song_view/presentation/widgets/song_sheet.dart';
import 'package:libre_tab/l10n/l10n.dart';

class SongViewScreen extends ConsumerWidget {
  const SongViewScreen({required this.songId, super.key});

  /// Null when the route's id wasn't a number.
  final int? songId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = songId;
    if (id == null) return const _NotFound();
    return ref
        .watch(songProvider(id))
        .when(
          skipLoadingOnReload: true,
          loading: () => Scaffold(appBar: AppBar()),
          error: (_, _) => const _NotFound(),
          data: (entry) => entry == null ? const _NotFound() : _SongView(entry),
        );
  }
}

enum _Action { edit, share, delete }

class _SongView extends ConsumerWidget {
  const _SongView(this.entry);

  final SongEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final song = ChordProParser.parse(entry.body);
    final subtitle = [
      if (entry.artist.isNotEmpty) entry.artist,
      if (song.key != null) l10n.keyLabel(song.key!.name),
      if ((song.capo ?? 0) > 0) l10n.capoLabel(song.capo!),
    ].join(' · ');

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, color: context.colors.muted),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: entry.favorite ? l10n.removeFavorite : l10n.addFavorite,
            icon: Icon(
              entry.favorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: entry.favorite ? context.colors.accent : null,
            ),
            onPressed: () => ref
                .read(songRepositoryProvider)
                .setFavorite(entry.id, favorite: !entry.favorite),
          ),
          IconButton(
            tooltip: l10n.switchTheme,
            icon: const Icon(Icons.dark_mode_outlined),
            onPressed: () => ref.read(themeVariantProvider.notifier).cycle(),
          ),
          PopupMenuButton<_Action>(
            tooltip: l10n.moreActions,
            onSelected: (action) => switch (action) {
              _Action.edit => context.push(Routes.editSong(entry.id)),
              _Action.share =>
                ref
                    .read(songFilesProvider)
                    .share(title: entry.title, body: entry.body),
              _Action.delete => _confirmDelete(context, ref),
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: _Action.edit, child: Text(l10n.editSong)),
              PopupMenuItem(value: _Action.share, child: Text(l10n.share)),
              PopupMenuItem(value: _Action.delete, child: Text(l10n.delete)),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
        child: SongSheet(song: song),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.deleteTitle(entry.title)),
        content: Text(l10n.deleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final repository = ref.read(songRepositoryProvider);
    context.pop();
    await repository.deleteSong(entry.id);
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: PlaceholderBody(message: context.l10n.songNotFound),
  );
}
