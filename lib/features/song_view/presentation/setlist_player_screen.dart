import 'dart:async';

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

  /// The page to start auto-scrolling on arrival (the previous song ran
  /// into it).
  int? _autoPlayPage;

  void _goTo(int page, {required bool autoPlay}) {
    setState(() => _autoPlayPage = autoPlay ? page : null);
    unawaited(
      _pages.animateToPage(
        page,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      ),
    );
  }

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
        autoPlay: i == _autoPlayPage,
        upNext: i + 1 < list.length
            ? UpNext(
                title: list[i + 1].title,
                go: ({required autoPlay}) => _goTo(i + 1, autoPlay: autoPlay),
              )
            : null,
      ),
    );
  }
}
