import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libre_tab/core/widgets/placeholder_body.dart';
import 'package:libre_tab/features/library/application/library_providers.dart';
import 'package:libre_tab/features/song_view/presentation/song_view_screen.dart';
import 'package:libre_tab/l10n/l10n.dart';

/// Plays a setlist: the song view for each song, and swiping left/right
/// moves to the next/previous one (docs/DESIGN.md § Setlists).
class SetlistPlayerScreen extends ConsumerStatefulWidget {
  const SetlistPlayerScreen({
    required this.setlistId,
    this.start = 0,
    super.key,
  });

  /// Null when the route's id wasn't a number.
  final int? setlistId;

  /// Position of the first song shown.
  final int start;

  @override
  ConsumerState<SetlistPlayerScreen> createState() =>
      _SetlistPlayerScreenState();
}

class _SetlistPlayerScreenState extends ConsumerState<SetlistPlayerScreen> {
  late final _pages = PageController(initialPage: widget.start);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final id = widget.setlistId;
    final songs = id == null ? null : ref.watch(setlistSongsProvider(id));
    final list = songs?.value;
    if (list == null || list.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: songs == null || songs.hasError || list != null
            ? PlaceholderBody(message: l10n.setlistNotFound)
            : null,
      );
    }
    return PageView.builder(
      controller: _pages,
      itemCount: list.length,
      itemBuilder: (context, i) => SongViewScreen(
        key: ValueKey(list[i].id),
        songId: list[i].id,
        position: (i + 1, list.length),
      ),
    );
  }
}
