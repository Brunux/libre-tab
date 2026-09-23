import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:libre_tab/core/database/app_database.dart';
import 'package:libre_tab/features/library/data/setlist_repository.dart';
import 'package:libre_tab/features/library/data/song_repository.dart';

/// The songbook's chips: every song, favorites, or setlists.
enum LibraryView { all, favorites, setlists }

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

/// The songs matching the current filter, kept up to date.
final StreamProvider<List<SongEntry>> songListProvider =
    StreamProvider.autoDispose<List<SongEntry>>((ref) {
      final filter = ref.watch(libraryFilterProvider);
      return ref
          .watch(songRepositoryProvider)
          .watchSongs(
            query: filter.query,
            favoritesOnly: filter.view == LibraryView.favorites,
          );
    });

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

/// The setlists matching the songbook's search.
final StreamProvider<List<SetlistSummary>> setlistListProvider =
    StreamProvider.autoDispose<List<SetlistSummary>>((ref) {
      final query = ref.watch(libraryFilterProvider.select((f) => f.query));
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
