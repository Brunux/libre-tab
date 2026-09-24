import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:libre_tab/app/settings/settings_store.dart';
import 'package:libre_tab/core/database/app_database.dart';
import 'package:libre_tab/features/library/application/song_order.dart';
import 'package:libre_tab/features/library/data/setlist_repository.dart';
import 'package:libre_tab/features/library/data/song_repository.dart';

/// The songbook's chips: every song, or favorites.
enum LibraryView { all, favorites }

/// What the songbook list is showing.
final class LibraryFilter {
  const LibraryFilter({this.query = '', this.view = LibraryView.all});

  final String query;
  final LibraryView view;
}

final libraryFilterProvider =
    NotifierProvider<LibraryFilterController, LibraryFilter>(
      LibraryFilterController.new,
    );

class LibraryFilterController extends Notifier<LibraryFilter> {
  @override
  LibraryFilter build() => const LibraryFilter();

  String get query => state.query;
  set query(String value) => state = LibraryFilter(query: value, view: view);

  LibraryView get view => state.view;
  set view(LibraryView value) =>
      state = LibraryFilter(query: query, view: value);
}

/// How the songbook is sorted, remembered between launches.
final songSortProvider = NotifierProvider<SongSortController, SongSort>(
  SongSortController.new,
);

class SongSortController extends Notifier<SongSort> {
  SettingsStore get _store => ref.read(settingsStoreProvider);

  @override
  SongSort build() {
    final name = _store.getString(SettingsKeys.songSort);
    return SongSort.values.firstWhere(
      (s) => s.name == name,
      orElse: () => SongSort.title,
    );
  }

  SongSort get sort => state;
  set sort(SongSort sort) {
    state = sort;
    _store.setString(SettingsKeys.songSort, sort.name);
  }
}

/// The songs matching the current filter, kept up to date: in the chosen
/// order, or best matches first while searching.
final StreamProvider<List<SongEntry>> songListProvider =
    StreamProvider.autoDispose<List<SongEntry>>((ref) {
      final filter = ref.watch(libraryFilterProvider);
      final sort = ref.watch(songSortProvider);
      final songs = ref
          .watch(songRepositoryProvider)
          .watchSongs(
            query: filter.query,
            favoritesOnly: filter.view == LibraryView.favorites,
          );
      if (filter.query.trim().isNotEmpty) return songs;
      return songs.map((list) => SongOrder.sort(list, sort));
    });

/// The songs opened most recently, newest first, for "Recently played".
final StreamProvider<List<SongEntry>> recentSongsProvider =
    StreamProvider.autoDispose<List<SongEntry>>(
      (ref) =>
          ref.watch(songRepositoryProvider).watchSongs().map(SongOrder.recent),
    );

/// Every song by title, for pickers that ignore the songbook's filter.
final StreamProvider<List<SongEntry>> allSongsProvider =
    StreamProvider.autoDispose<List<SongEntry>>(
      (ref) => ref.watch(songRepositoryProvider).watchSongs(),
    );

/// One song, kept up to date; null once deleted.
final StreamProviderFamily<SongEntry?, int> songProvider = StreamProvider
    .autoDispose
    .family<SongEntry?, int>(
      (ref, id) => ref.watch(songRepositoryProvider).watchSong(id),
    );

/// The Setlists tab's search.
final setlistQueryProvider = NotifierProvider<SetlistQueryController, String>(
  SetlistQueryController.new,
);

class SetlistQueryController extends Notifier<String> {
  @override
  String build() => '';

  String get query => state;
  set query(String value) => state = value;
}

/// The setlists matching the Setlists tab's search.
final StreamProvider<List<SetlistSummary>> setlistListProvider =
    StreamProvider.autoDispose<List<SetlistSummary>>((ref) {
      final query = ref.watch(setlistQueryProvider);
      return ref.watch(setlistRepositoryProvider).watchSetlists(query: query);
    });

/// Every setlist, for the "Add to setlist" sheet.
final StreamProvider<List<SetlistSummary>> allSetlistsProvider =
    StreamProvider.autoDispose<List<SetlistSummary>>(
      (ref) => ref.watch(setlistRepositoryProvider).watchSetlists(),
    );

/// One setlist; null once deleted.
final StreamProviderFamily<SetlistEntry?, int> setlistProvider = StreamProvider
    .autoDispose
    .family<SetlistEntry?, int>(
      (ref, id) => ref.watch(setlistRepositoryProvider).watchSetlist(id),
    );

/// A setlist's songs in playing order.
final StreamProviderFamily<List<SongEntry>, int> setlistSongsProvider =
    StreamProvider.autoDispose.family<List<SongEntry>, int>(
      (ref, id) => ref.watch(setlistRepositoryProvider).watchSongs(id),
    );

/// Ids of the setlists that have a song.
final StreamProviderFamily<Set<int>, int> setlistsWithSongProvider =
    StreamProvider.autoDispose.family<Set<int>, int>(
      (ref, songId) =>
          ref.watch(setlistRepositoryProvider).watchSetlistsWith(songId),
    );
