import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libre_tab/app/settings/settings_store.dart';
import 'package:libre_tab/core/chordpro/song_header.dart';
import 'package:libre_tab/features/library/data/song_repository.dart';

final starterSongsProvider = Provider<StarterSongs>(
  (ref) => StarterSongs(ref.watch(songRepositoryProvider), rootBundle),
);

/// Public-domain campfire songs that ship with the app (assets/songs/), so
/// a new songbook isn't empty (docs/DESIGN.md § Settings).
class StarterSongs {
  StarterSongs(SongRepository songs, AssetBundle bundle)
    : _songs = songs,
      _bundle = bundle;

  final SongRepository _songs;
  final AssetBundle _bundle;

  static const files = [
    'amazing-grace.cho',
    'clementine.cho',
    'coming-round-the-mountain.cho',
    'de-colores.cho',
    'la-cucaracha.cho',
    'oh-susanna.cho',
    'red-river-valley.cho',
  ];

  /// The starter songs' ChordPro text. Not cached: they're read rarely.
  Future<List<String>> load() => Future.wait([
    for (final file in files)
      _bundle.loadString('assets/songs/$file', cache: false),
  ]);

  /// Adds the starter songs whose title isn't in the songbook yet. Returns
  /// how many were added.
  Future<int> addMissing() async {
    final titles = {
      for (final song in await _songs.allSongs()) song.title.toLowerCase(),
    };
    var added = 0;
    for (final body in await load()) {
      final title = SongHeader.split(body).title.toLowerCase();
      if (titles.contains(title)) continue;
      await _songs.addSong(body);
      added++;
    }
    return added;
  }

  /// On the very first launch, fills the empty songbook. Never again after
  /// that: deleted starter songs stay deleted unless the user asks.
  Future<void> addOnFirstLaunch(SettingsStore settings) async {
    if (settings.getInt(SettingsKeys.starterSongs) != null) return;
    settings.setInt(SettingsKeys.starterSongs, 1);
    if ((await _songs.allSongs()).isEmpty) await addMissing();
  }
}
