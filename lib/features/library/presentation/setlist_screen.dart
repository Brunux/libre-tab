import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:libre_tab/app/router.dart';
import 'package:libre_tab/app/theme/libre_colors.dart';
import 'package:libre_tab/core/database/app_database.dart';
import 'package:libre_tab/core/widgets/placeholder_body.dart';
import 'package:libre_tab/core/widgets/readable_width.dart';
import 'package:libre_tab/features/library/application/library_providers.dart';
import 'package:libre_tab/features/library/data/setlist_repository.dart';
import 'package:libre_tab/features/library/presentation/widgets/setlist_name_dialog.dart';
import 'package:libre_tab/l10n/l10n.dart';

/// One setlist: play it, reorder, add and remove songs (docs/DESIGN.md
/// § Setlists).
class SetlistScreen extends ConsumerWidget {
  const SetlistScreen({required this.setlistId, super.key});

  /// Null when the route's id wasn't a number.
  final int? setlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = setlistId;
    if (id == null) return const _NotFound();
    return ref
        .watch(setlistProvider(id))
        .when(
          skipLoadingOnReload: true,
          loading: () => Scaffold(appBar: AppBar()),
          error: (_, _) => const _NotFound(),
          data: (entry) =>
              entry == null ? const _NotFound() : _SetlistView(entry),
        );
  }
}

enum _Action { rename, delete }

class _SetlistView extends ConsumerStatefulWidget {
  const _SetlistView(this.setlist);

  final SetlistEntry setlist;

  @override
  ConsumerState<_SetlistView> createState() => _SetlistViewState();
}

class _SetlistViewState extends ConsumerState<_SetlistView> {
  /// The order just dragged into place, shown until the database catches up
  /// so the row doesn't jump back for a frame.
  List<SongEntry>? _dragged;

  int get _id => widget.setlist.id;
  SetlistRepository get _repository => ref.read(setlistRepositoryProvider);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ref.listen(setlistSongsProvider(_id), (_, _) {
      if (_dragged != null) setState(() => _dragged = null);
    });
    final songs = ref.watch(setlistSongsProvider(_id));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.setlist.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          PopupMenuButton<_Action>(
            tooltip: l10n.moreActions,
            onSelected: (action) => switch (action) {
              _Action.rename => _rename(),
              _Action.delete => _confirmDelete(),
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _Action.rename,
                child: Text(l10n.renameSetlist),
              ),
              PopupMenuItem(value: _Action.delete, child: Text(l10n.delete)),
            ],
          ),
        ],
      ),
      body: ReadableWidth(
        child: songs.when(
          skipLoadingOnReload: true,
          loading: () => const SizedBox.shrink(),
          error: (_, _) => PlaceholderBody(
            icon: Icons.error_outline,
            message: l10n.loadError,
          ),
          data: (fromDb) {
            final list = _dragged ?? fromDb;
            final buttons = _Buttons(
              onPlay: list.isEmpty
                  ? null
                  : () => context.push(Routes.playSetlist(_id, 0)),
              onAdd: () => _addSongs(list),
            );
            if (list.isEmpty) {
              return Column(
                children: [
                  buttons,
                  Expanded(
                    child: PlaceholderBody(
                      icon: Icons.playlist_add,
                      message: l10n.emptySetlist,
                    ),
                  ),
                ],
              );
            }
            return ReorderableListView.builder(
              header: buttons,
              padding: const EdgeInsets.only(bottom: 48),
              buildDefaultDragHandles: false,
              itemCount: list.length,
              onReorderItem: (from, to) => _move(list, from, to),
              itemBuilder: (context, i) => _SongRow(
                key: ValueKey(list[i].id),
                index: i,
                song: list[i],
                onTap: () => context.push(Routes.playSetlist(_id, i)),
                onRemove: () =>
                    unawaited(_repository.removeSong(_id, list[i].id)),
              ),
            );
          },
        ),
      ),
    );
  }

  void _move(List<SongEntry> list, int from, int to) {
    if (to == from) return;
    final reordered = [...list];
    reordered.insert(to, reordered.removeAt(from));
    setState(() => _dragged = reordered);
    unawaited(_repository.moveSong(_id, from, to));
  }

  Future<void> _addSongs(List<SongEntry> current) async {
    final ids = await showModalBottomSheet<List<int>>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _AddSongsSheet(current: [for (final s in current) s.id]),
    );
    if (ids != null) await _repository.setSongs(_id, ids);
  }

  Future<void> _rename() async {
    final name = await showSetlistNameDialog(
      context,
      initial: widget.setlist.name,
    );
    if (name != null) await _repository.rename(_id, name);
  }

  Future<void> _confirmDelete() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.deleteSetlistTitle(widget.setlist.name)),
        content: Text(l10n.deleteSetlistBody),
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
    if (confirmed != true || !mounted) return;
    final repository = _repository;
    context.pop();
    await repository.delete(_id);
  }
}

class _Buttons extends StatelessWidget {
  const _Buttons({required this.onPlay, required this.onAdd});

  final VoidCallback? onPlay;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: onPlay,
              icon: const Icon(Icons.play_arrow),
              label: Text(l10n.playSetlist),
            ),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(l10n.addSongs),
            ),
          ],
        ),
      ),
    );
  }
}

class _SongRow extends StatelessWidget {
  const _SongRow({
    required this.index,
    required this.song,
    required this.onTap,
    required this.onRemove,
    super.key,
  });

  final int index;
  final SongEntry song;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final subtitle = [
      if (song.artist.isNotEmpty) song.artist,
      if (song.songKey != null) l10n.keyLabel(song.songKey!),
    ].join(' · ');
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.only(left: 20, right: 4),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.line)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.muted,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
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
              ),
              IconButton(
                tooltip: l10n.removeFromSetlist(song.title),
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: onRemove,
              ),
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(Icons.drag_handle, color: colors.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Every song with a checkbox. Pops with the setlist's new song ids: songs
/// already in it keep their order, new ones go at the end.
class _AddSongsSheet extends ConsumerStatefulWidget {
  const _AddSongsSheet({required this.current});

  final List<int> current;

  @override
  ConsumerState<_AddSongsSheet> createState() => _AddSongsSheetState();
}

class _AddSongsSheetState extends ConsumerState<_AddSongsSheet> {
  late final Set<int> _ticked = {...widget.current};
  final _added = <int>[];
  String _query = '';

  void _toggle(int id, {required bool on}) => setState(() {
    if (on) {
      _ticked.add(id);
      if (!widget.current.contains(id)) _added.add(id);
    } else {
      _ticked.remove(id);
      _added.remove(id);
    }
  });

  List<int> get _result => [
    ...widget.current.where(_ticked.contains),
    ..._added,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final wanted = SetlistRepository.fold(_query.trim());
    final songs = ref.watch(allSongsProvider).value ?? const [];
    final shown = [
      for (final song in songs)
        if (SetlistRepository.fold(
          '${song.title} ${song.artist}',
        ).contains(wanted))
          song,
    ];

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.addSongs,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(_result),
                  child: Text(l10n.done),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: songs.isEmpty
                ? PlaceholderBody(message: l10n.emptySongbook)
                : ListView.builder(
                    itemCount: shown.length,
                    itemBuilder: (context, i) {
                      final song = shown[i];
                      return CheckboxListTile(
                        value: _ticked.contains(song.id),
                        onChanged: (on) => _toggle(song.id, on: on ?? false),
                        title: Text(song.title),
                        subtitle: song.artist.isEmpty
                            ? null
                            : Text(song.artist),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: PlaceholderBody(
      icon: Icons.search_off,
      message: context.l10n.setlistNotFound,
    ),
  );
}
