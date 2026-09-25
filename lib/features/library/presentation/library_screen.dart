import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:libre_tab/app/router.dart';
import 'package:libre_tab/app/settings/settings_store.dart';
import 'package:libre_tab/app/theme/app_theme.dart';
import 'package:libre_tab/app/theme/libre_colors.dart';
import 'package:libre_tab/app/widgets/app_logo.dart';
import 'package:libre_tab/core/database/app_database.dart';
import 'package:libre_tab/core/files/song_files.dart';
import 'package:libre_tab/core/widgets/motion.dart';
import 'package:libre_tab/core/widgets/placeholder_body.dart';
import 'package:libre_tab/core/widgets/readable_width.dart';
import 'package:libre_tab/features/library/application/library_providers.dart';
import 'package:libre_tab/features/library/application/song_order.dart';
import 'package:libre_tab/features/library/presentation/widgets/song_actions.dart';
import 'package:libre_tab/features/settings/presentation/settings_screen.dart';
import 'package:libre_tab/features/settings/presentation/support_options.dart';
import 'package:libre_tab/features/song_view/presentation/widgets/song_title_hero.dart';
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

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 20,
        // The logo, not the tab's name: the tab bar says where you are.
        title: const AppLogo(),
        actions: [
          IconButton(
            tooltip: l10n.settingsTitle,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(Routes.settings),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ReadableWidth(
        child: Column(
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
                          onPressed: _clearSearch,
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
              // All songs ↔ Favorites cross-fade.
              child: AnimatedSwitcher(
                duration: context.motion(const Duration(milliseconds: 180)),
                child: _SongList(
                  filter,
                  key: ValueKey(filter.view),
                  onClearSearch: _clearSearch,
                  onBrowse: () => _filter.view = LibraryView.all,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        // Each tab keeps its page alive, so each button needs its own tag.
        heroTag: 'addSong',
        onPressed: () => context.push(Routes.addSong),
        icon: const Icon(Icons.add),
        label: Text(l10n.addSong),
      ),
    );
  }

  void _clearSearch() {
    _search.clear();
    _filter.query = '';
  }
}

class _SongList extends ConsumerStatefulWidget {
  const _SongList(
    this.filter, {
    required this.onClearSearch,
    required this.onBrowse,
    super.key,
  });

  final LibraryFilter filter;
  final VoidCallback onClearSearch;

  /// From an empty Favorites to all songs.
  final VoidCallback onBrowse;

  @override
  ConsumerState<_SongList> createState() => _SongListState();
}

class _SongListState extends ConsumerState<_SongList> {
  /// From this many songs, sorted by title or artist, an A–Z index runs
  /// down the right edge.
  static const _indexFrom = 30;

  final _scroll = ScrollController();

  /// The rows' keys, so the A–Z index can bring one to the top.
  final _rowKeys = <int, GlobalKey>{};

  /// The songs shown last time, and for which search, chip and sort: a
  /// song that wasn't there (Undo, a song just added) grows in; a new
  /// search or sort just shows its list.
  Set<int>? _shown;
  String? _shownFor;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filter = widget.filter;
    final sort = ref.watch(songSortProvider);
    return ref
        .watch(songListProvider)
        .when(
          skipLoadingOnReload: true,
          loading: () => const SizedBox.shrink(),
          error: (_, _) => PlaceholderBody(
            icon: Icons.error_outline,
            message: l10n.loadError,
          ),
          data: (list) {
            final ids = {for (final song in list) song.id};
            final showing = '${filter.query}|${filter.view.name}|${sort.name}';
            final arrived = _shown != null && _shownFor == showing
                ? ids.difference(_shown!)
                : const <int>{};
            _shown = ids;
            _shownFor = showing;
            if (list.isEmpty) {
              return widget.filter.query.trim().isNotEmpty
                  ? PlaceholderBody(
                      icon: Icons.search_off,
                      message: l10n.noMatches,
                      action: TextButton(
                        onPressed: widget.onClearSearch,
                        child: Text(l10n.clearSearch),
                      ),
                    )
                  : widget.filter.view == LibraryView.favorites
                  ? PlaceholderBody(
                      icon: Icons.star_outline_rounded,
                      message: l10n.noFavorites,
                      action: OutlinedButton(
                        onPressed: widget.onBrowse,
                        child: Text(l10n.browseSongs),
                      ),
                    )
                  : PlaceholderBody(
                      mark: true,
                      message: l10n.emptySongbook,
                      action: OutlinedButton.icon(
                        onPressed: () => addStarterSongs(context, ref),
                        icon: const Icon(Icons.library_music_outlined),
                        label: Text(l10n.addStarterSongs),
                      ),
                    );
            }
            final browsing = filter.query.trim().isEmpty;
            // Recently played heads the full list (not when it's already
            // sorted that way, searching, or showing favorites).
            final recent =
                browsing &&
                    filter.view == LibraryView.all &&
                    sort != SongSort.recent
                ? ref.watch(recentSongsProvider).value ?? const <SongEntry>[]
                : const <SongEntry>[];
            final withIndex =
                browsing &&
                list.length >= _indexFrom &&
                (sort == SongSort.title || sort == SongSort.artist);
            final leading = <Widget>[
              if (browsing && filter.view == LibraryView.all)
                const _SupportNudge(),
              if (recent.isNotEmpty) _RecentStrip(recent),
              _ListHeader(count: list.length, sort: browsing ? sort : null),
            ];
            final songs = SlidableAutoCloseBehavior(
              // Opening one row's swipe actions closes the others.
              child: ListView.builder(
                controller: _scroll,
                padding: EdgeInsets.only(bottom: 96, right: withIndex ? 20 : 0),
                itemCount: leading.length + list.length,
                itemBuilder: (context, i) {
                  if (i < leading.length) return leading[i];
                  final song = list[i - leading.length];
                  final index = i - leading.length;
                  return Appearing(
                    key: ValueKey(song.id),
                    enabled: arrived.contains(song.id),
                    // Many at once (the starter songs on first launch):
                    // they cascade in, one after another.
                    delay: arrived.length > 1
                        ? Duration(milliseconds: 45 * index.clamp(0, 12))
                        : Duration.zero,
                    child: _SongTile(
                      key: _rowKeys.putIfAbsent(song.id, GlobalKey.new),
                      song: song,
                      sort: browsing ? sort : null,
                    ),
                  );
                },
              ),
            );
            if (!withIndex) return songs;
            final firstOf = <String, int>{};
            for (final (i, song) in list.indexed) {
              firstOf.putIfAbsent(SongOrder.letter(song, sort), () => i);
            }
            return Stack(
              children: [
                songs,
                Positioned(
                  top: 0,
                  right: 0,
                  bottom: 88,
                  child: _LetterIndex(
                    letters: firstOf.keys.toList(),
                    onLetter: (letter) =>
                        _bringUp(list, firstOf[letter]!, leading.length),
                  ),
                ),
              ],
            );
          },
        );
  }

  /// Scrolls so song [index] is at the top: a jump to where it should be
  /// (rows are about the same height), then to the row itself once built.
  void _bringUp(List<SongEntry> list, int index, int leading) {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    final rows = leading + list.length;
    final perRow =
        (position.maxScrollExtent + position.viewportDimension) / rows;
    _scroll.jumpTo(
      (perRow * (leading + index)).clamp(0, position.maxScrollExtent),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final row = _rowKeys[list[index].id]?.currentContext;
      if (row != null && row.mounted) Scrollable.ensureVisible(row);
    });
  }
}

/// "7 SONGS", and the sort menu while not searching (a search lists the
/// best matches first).
class _ListHeader extends ConsumerWidget {
  const _ListHeader({required this.count, required this.sort});

  final int count;
  final SongSort? sort;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final names = {
      SongSort.title: l10n.sortTitle,
      SongSort.artist: l10n.sortArtist,
      SongSort.recent: l10n.sortRecent,
      SongSort.mostPlayed: l10n.sortMostPlayed,
    };
    final current = sort;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.songCount(count).toUpperCase(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: colors.muted,
              ),
            ),
          ),
          if (current == null)
            const SizedBox(height: 48)
          else
            MenuAnchor(
              menuChildren: [
                for (final MapEntry(key: option, value: name) in names.entries)
                  MenuItemButton(
                    leadingIcon: Icon(
                      Icons.check,
                      color: option == current ? null : Colors.transparent,
                    ),
                    onPressed: () =>
                        ref.read(songSortProvider.notifier).sort = option,
                    child: Text(name),
                  ),
              ],
              builder: (context, menu, _) => TextButton.icon(
                onPressed: () => menu.isOpen ? menu.close() : menu.open(),
                icon: const Icon(Icons.sort, size: 20),
                label: Text(names[current]!),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Once, after the 10th song opened: a thank-you with a way to support the
/// project. Either answer puts it away for good.
class _SupportNudge extends ConsumerStatefulWidget {
  const _SupportNudge();

  static const after = 10;

  @override
  ConsumerState<_SupportNudge> createState() => _SupportNudgeState();
}

class _SupportNudgeState extends ConsumerState<_SupportNudge> {
  SettingsStore get _store => ref.read(settingsStoreProvider);

  bool get _due =>
      _store.getInt(SettingsKeys.supportNudged) != 1 &&
      (_store.getInt(SettingsKeys.songsOpened) ?? 0) >= _SupportNudge.after;

  void _done() {
    _store.setInt(SettingsKeys.supportNudged, 1);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_due) return const SizedBox.shrink();
    final l10n = context.l10n;
    final colors = context.colors;
    return Appearing(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
        child: Material(
          color: colors.surface2,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const BrandMark(size: 32),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.nudgeTitle,
                        style: AppFonts.displayStyle(18, colors.text),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(l10n.nudgeBody, style: TextStyle(color: colors.muted)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: _done, child: Text(l10n.nudgeLater)),
                    FilledButton(
                      onPressed: () {
                        _done();
                        unawaited(
                          showModalBottomSheet<void>(
                            context: context,
                            showDragHandle: true,
                            isScrollControlled: true,
                            builder: (_) => const SafeArea(
                              child: SingleChildScrollView(
                                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: SupportOptions(),
                              ),
                            ),
                          ),
                        );
                      },
                      child: Text(l10n.nudgeYes),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Slides [child] in from the left and fades it in, the first time.
class _SlideIn extends StatelessWidget {
  const _SlideIn({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: context.flourish(const Duration(milliseconds: 320)),
    curve: Curves.easeOutCubic,
    builder: (context, t, child) => Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(-40 * (1 - t), 0),
        child: child,
      ),
    ),
    child: child,
  );
}

/// The last songs opened, as a row of cards to get back to them.
class _RecentStrip extends StatelessWidget {
  const _RecentStrip(this.songs);

  final List<SongEntry> songs;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final scale = MediaQuery.textScalerOf(context);
    // Tall enough for two lines of title and one of artist at any text size.
    final height = 24 + scale.scale(16) * 1.3 * 2 + scale.scale(14) * 1.35 + 4;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Text(
            l10n.recentlyPlayed.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: colors.muted,
            ),
          ),
        ),
        SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: songs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            // The newest card slides in from the left (keyed by song, so
            // only a card that just arrived at the front moves).
            itemBuilder: (context, i) => i == 0
                ? _SlideIn(
                    key: ValueKey(songs[0].id),
                    child: _RecentCard(songs[0]),
                  )
                : _RecentCard(songs[i]),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard(this.song);

  final SongEntry song;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: 168,
      child: Material(
        color: colors.surface2,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push(Routes.song(song.id)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const Spacer(),
                Text(
                  [
                    if (song.songKey != null) song.songKey!,
                    if (song.artist.isNotEmpty) song.artist,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: colors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A–Z down the right edge: touch or slide along it to jump to a letter.
/// Left out for screen readers, who have search; the letters are too small
/// to be good accessible buttons.
class _LetterIndex extends StatefulWidget {
  const _LetterIndex({required this.letters, required this.onLetter});

  final List<String> letters;
  final ValueChanged<String> onLetter;

  @override
  State<_LetterIndex> createState() => _LetterIndexState();
}

class _LetterIndexState extends State<_LetterIndex> {
  String? _last;

  void _at(double dy, double height) {
    final letters = widget.letters;
    final i = (dy / height * letters.length).floor().clamp(
      0,
      letters.length - 1,
    );
    final letter = letters[i];
    if (letter == _last) return;
    _last = letter;
    unawaited(HapticFeedback.selectionClick());
    widget.onLetter(letter);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) {
              _last = null;
              _at(d.localPosition.dy, height);
            },
            onVerticalDragStart: (d) {
              _last = null;
              _at(d.localPosition.dy, height);
            },
            onVerticalDragUpdate: (d) => _at(d.localPosition.dy, height),
            child: SizedBox(
              width: 24,
              child: Column(
                children: [
                  for (final letter in widget.letters)
                    Expanded(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            letter,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: colors.accent,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// "Played today", "Played 3 days ago", "Played Sep 2".
String _playedWhen(BuildContext context, DateTime when) {
  final l10n = context.l10n;
  final now = DateTime.now();
  final days = DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(when.year, when.month, when.day)).inDays;
  return switch (days) {
    <= 0 => l10n.playedToday,
    1 => l10n.playedYesterday,
    < 7 => l10n.playedDaysAgo(days),
    _ => l10n.playedOn(
      DateFormat.MMMd(Localizations.localeOf(context).toString()).format(when),
    ),
  };
}

/// A light tap under the finger, then [action].
void _click(VoidCallback action) {
  unawaited(HapticFeedback.selectionClick());
  action();
}

class _SongTile extends ConsumerWidget {
  const _SongTile({required this.song, this.sort, super.key});

  final SongEntry song;

  /// The list's order: sorted by recent or most played, the row also says
  /// when or how often the song was played.
  final SongSort? sort;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final scheme = Theme.of(context).colorScheme;
    final played = switch (sort) {
      SongSort.mostPlayed when song.playCount > 0 => l10n.playedTimes(
        song.playCount,
      ),
      SongSort.recent => switch (song.lastOpenedAt) {
        final opened? => _playedWhen(context, opened),
        null => null,
      },
      _ => null,
    };
    final subtitle = [
      if (song.artist.isNotEmpty) song.artist,
      if ((song.capo ?? 0) > 0) l10n.capoLabel(song.capo!),
      ?played,
    ].join(' · ');

    void addToSetlist() => showAddToSetlistSheet(context, songId: song.id);
    void share() =>
        ref.read(songFilesProvider).share(title: song.title, body: song.body);
    void delete() => deleteSongWithUndo(context, ref, song);

    // Swipe left for quick actions. Screen readers get the same three as
    // custom actions, since the swiped-away buttons can't be reached.
    return Vanishing(
      child: Slidable(
        key: ValueKey(song.id),
        groupTag: 'songs',
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.72,
          children: [
            SlidableAction(
              onPressed: (_) => _click(addToSetlist),
              backgroundColor: colors.surface2,
              foregroundColor: colors.text,
              icon: Icons.playlist_add,
              label: l10n.swipeSetlist,
            ),
            SlidableAction(
              onPressed: (_) => _click(share),
              backgroundColor: colors.surface,
              foregroundColor: colors.text,
              icon: Icons.ios_share,
              label: l10n.share,
            ),
            SlidableAction(
              onPressed: (row) {
                unawaited(HapticFeedback.mediumImpact());
                // The row folds away, then the song goes (Undo brings it
                // back, growing in).
                final vanishing = Vanishing.of(row);
                if (vanishing == null) {
                  delete();
                } else {
                  unawaited(vanishing.vanish(delete));
                }
              },
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
              icon: Icons.delete_outline,
              label: l10n.delete,
            ),
          ],
        ),
        child: _tile(
          context,
          subtitle,
          actions: {
            CustomSemanticsAction(label: l10n.addToSetlist): addToSetlist,
            CustomSemanticsAction(label: l10n.share): share,
            CustomSemanticsAction(label: l10n.delete): delete,
          },
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    String subtitle, {
    required Map<CustomSemanticsAction, VoidCallback> actions,
  }) {
    final l10n = context.l10n;
    final colors = context.colors;
    return MergeSemantics(
      child: Semantics(
        customSemanticsActions: actions,
        child: _row(context, subtitle, l10n, colors),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String subtitle,
    AppLocalizations l10n,
    LibreColors colors,
  ) {
    return Material(
      type: MaterialType.transparency,
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
                    SongTitleHero(
                      songId: song.id,
                      title: song.title,
                      maxLines: 2,
                      inSongView: false,
                      style: DefaultTextStyle.of(context).style.merge(
                        const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
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
