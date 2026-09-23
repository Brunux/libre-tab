import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:libre_tab/app/router.dart';
import 'package:libre_tab/app/theme/libre_colors.dart';
import 'package:libre_tab/core/database/app_database.dart';
import 'package:libre_tab/core/widgets/placeholder_body.dart';
import 'package:libre_tab/features/library/application/library_providers.dart';
import 'package:libre_tab/features/library/data/setlist_repository.dart';
import 'package:libre_tab/features/library/presentation/widgets/setlist_name_dialog.dart';
import 'package:libre_tab/l10n/l10n.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  late final _search = TextEditingController(
    text: ref.read(libraryFilterProvider).query,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  LibraryFilterController get _filter =>
      ref.read(libraryFilterProvider.notifier);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filter = ref.watch(libraryFilterProvider);
    final setlists = filter.view == LibraryView.setlists;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 20,
        title: Text(
          l10n.tabSongbook,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        actions: [
          IconButton(
            tooltip: l10n.settingsTitle,
            icon: const Icon(Icons.tune),
            onPressed: () => context.push(Routes.settings),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: TextField(
              controller: _search,
              onChanged: (value) => _filter.query = value,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: filter.query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: l10n.clearSearch,
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _search.clear();
                          _filter.query = '';
                        },
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (view, label) in [
                    (LibraryView.all, l10n.filterAll),
                    (LibraryView.favorites, l10n.filterFavorites),
                    (LibraryView.setlists, l10n.filterSetlists),
                  ])
                    ChoiceChip(
                      label: Text(label),
                      selected: filter.view == view,
                      onSelected: (_) => _filter.view = view,
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: setlists ? _SetlistList(filter) : _SongList(filter),
          ),
        ],
      ),
      floatingActionButton: setlists
          ? FloatingActionButton.extended(
              onPressed: _newSetlist,
              icon: const Icon(Icons.playlist_add),
              label: Text(l10n.newSetlist),
            )
          : FloatingActionButton.extended(
              onPressed: () => context.push(Routes.addSong),
              icon: const Icon(Icons.add),
              label: Text(l10n.addSong),
            ),
    );
  }

  Future<void> _newSetlist() async {
    final name = await showSetlistNameDialog(context);
    if (name == null) return;
    final id = await ref.read(setlistRepositoryProvider).create(name);
    if (mounted) await context.push(Routes.setlist(id));
  }
}

class _SongList extends ConsumerWidget {
  const _SongList(this.filter);

  final LibraryFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return ref
        .watch(songListProvider)
        .when(
          skipLoadingOnReload: true,
          loading: () => const SizedBox.shrink(),
          error: (_, _) => PlaceholderBody(message: l10n.loadError),
          data: (list) => list.isEmpty
              ? PlaceholderBody(
                  message: filter.query.trim().isNotEmpty
                      ? l10n.noMatches
                      : filter.view == LibraryView.favorites
                      ? l10n.noFavorites
                      : l10n.emptySongbook,
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: list.length + 1,
                  itemBuilder: (context, i) => i == 0
                      ? _CountHeader(text: l10n.songCount(list.length))
                      : _SongTile(song: list[i - 1]),
                ),
        );
  }
}

class _SetlistList extends ConsumerWidget {
  const _SetlistList(this.filter);

  final LibraryFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return ref
        .watch(setlistListProvider)
        .when(
          skipLoadingOnReload: true,
          loading: () => const SizedBox.shrink(),
          error: (_, _) => PlaceholderBody(message: l10n.loadError),
          data: (list) => list.isEmpty
              ? PlaceholderBody(
                  message: filter.query.trim().isNotEmpty
                      ? l10n.noSetlistMatches
                      : l10n.noSetlists,
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: list.length,
                  itemBuilder: (context, i) => _SetlistTile(list[i]),
                ),
        );
  }
}

class _SetlistTile extends StatelessWidget {
  const _SetlistTile(this.setlist);

  final SetlistSummary setlist;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MergeSemantics(
      child: InkWell(
        onTap: () => context.push(Routes.setlist(setlist.id)),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.line)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colors.surface2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.queue_music, color: colors.chord),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      setlist.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      context.l10n.songCount(setlist.songCount),
                      style: TextStyle(fontSize: 15, color: colors.muted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountHeader extends StatelessWidget {
  const _CountHeader({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
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

class _SongTile extends StatelessWidget {
  const _SongTile({required this.song});

  final SongEntry song;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final subtitle = [
      if (song.artist.isNotEmpty) song.artist,
      if ((song.capo ?? 0) > 0) l10n.capoLabel(song.capo!),
    ].join(' · ');

    return MergeSemantics(
      child: InkWell(
        onTap: () => context.push(Routes.song(song.id)),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.line)),
          ),
          child: Row(
            children: [
              _KeyBadge(songKey: song.songKey),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      song.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 15, color: colors.muted),
                      ),
                  ],
                ),
              ),
              if (song.favorite)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.star_rounded,
                    color: colors.accent,
                    semanticLabel: l10n.filterFavorites,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeyBadge extends StatelessWidget {
  const _KeyBadge({required this.songKey});

  final String? songKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: songKey == null
          ? Icon(Icons.music_note, size: 20, color: colors.muted)
          : Text(
              songKey!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.chord,
              ),
            ),
    );
  }
}
