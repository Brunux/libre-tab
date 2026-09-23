import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:libre_tab/core/database/app_database.dart';
import 'package:libre_tab/features/library/data/song_repository.dart';

/// What the songbook list is showing.
final class LibraryFilter {
  const LibraryFilter({this.query = '', this.favoritesOnly = false});

  final String query;
  final bool favoritesOnly;
}

final libraryFilterProvider =
    NotifierProvider<LibraryFilterController, LibraryFilter>(
      LibraryFilterController.new,
    );

class LibraryFilterController extends Notifier<LibraryFilter> {
  @override
  LibraryFilter build() => const LibraryFilter();

  String get query => state.query;
  set query(String value) => state = LibraryFilter(
    query: value,
    favoritesOnly: state.favoritesOnly,
  );

  bool get favoritesOnly => state.favoritesOnly;
  set favoritesOnly(bool value) =>
      state = LibraryFilter(query: state.query, favoritesOnly: value);
}

/// The songs matching the current filter, kept up to date.
final StreamProvider<List<SongEntry>> songListProvider =
    StreamProvider.autoDispose<List<SongEntry>>((ref) {
      final filter = ref.watch(libraryFilterProvider);
      return ref
          .watch(songRepositoryProvider)
          .watchSongs(query: filter.query, favoritesOnly: filter.favoritesOnly);
    });

/// One song, kept up to date; null once deleted.
final StreamProviderFamily<SongEntry?, int> songProvider = StreamProvider
    .autoDispose
    .family<SongEntry?, int>(
      (ref, id) => ref.watch(songRepositoryProvider).watchSong(id),
    );
