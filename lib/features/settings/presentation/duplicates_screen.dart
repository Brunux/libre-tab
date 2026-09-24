import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:libre_tab/app/router.dart';
import 'package:libre_tab/app/theme/libre_colors.dart';
import 'package:libre_tab/core/database/app_database.dart';
import 'package:libre_tab/core/widgets/placeholder_body.dart';
import 'package:libre_tab/core/widgets/readable_width.dart';
import 'package:libre_tab/features/library/data/duplicates.dart';
import 'package:libre_tab/features/library/data/song_repository.dart';
import 'package:libre_tab/features/library/presentation/widgets/song_actions.dart';
import 'package:libre_tab/l10n/l10n.dart';

/// Songs with the same title and artist (docs/DESIGN.md § Settings).
/// Exact copies can be removed together; different versions are only
/// listed, to open and compare.
class DuplicatesScreen extends ConsumerStatefulWidget {
  const DuplicatesScreen({super.key});

  @override
  ConsumerState<DuplicatesScreen> createState() => _DuplicatesScreenState();
}

class _DuplicatesScreenState extends ConsumerState<DuplicatesScreen> {
  late Future<List<DuplicateGroup>> _groups = _find();

  Future<List<DuplicateGroup>> _find() =>
      ref.read(songRepositoryProvider).findDuplicates();

  void _reload() {
    final groups = _find();
    setState(() {
      _groups = groups;
    });
  }

  Future<void> _removeCopies(List<DuplicateGroup> copies) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final repository = ref.read(songRepositoryProvider);
    final count = copies.fold(0, (n, g) => n + g.copies.length);
    final before = await repository.removeCopies(copies);
    if (!mounted) return;
    _reload();
    showUndoSnackBar(
      messenger,
      l10n,
      message: l10n.copiesRemoved(count),
      onUndo: () async {
        await repository.undoRemoveCopies(before);
        if (mounted) _reload();
      },
    );
  }

  Future<void> _open(SongEntry song) async {
    await context.push(Routes.song(song.id));
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.findDuplicates)),
      body: ReadableWidth(
        child: FutureBuilder(
          future: _groups,
          builder: (context, snapshot) {
            final groups = snapshot.data;
            if (snapshot.hasError) {
              return PlaceholderBody(message: l10n.loadError);
            }
            if (groups == null) return const SizedBox.shrink();
            if (groups.isEmpty) {
              return PlaceholderBody(message: l10n.noDuplicates);
            }
            final copies = [
              for (final g in groups)
                if (g.identical) g,
            ];
            final versions = [
              for (final g in groups)
                if (!g.identical) g,
            ];
            final copyCount = copies.fold(0, (n, g) => n + g.copies.length);
            return ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                if (copies.isNotEmpty) ...[
                  _Heading(l10n.exactCopies, hint: l10n.exactCopiesHint),
                  for (final group in copies)
                    ListTile(
                      leading: const Icon(Icons.copy_all_outlined),
                      title: Text(group.keeper.title),
                      subtitle: Text(
                        [
                          if (group.keeper.artist.isNotEmpty)
                            group.keeper.artist,
                          l10n.copiesCount(group.copies.length),
                        ].join(' · '),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: FilledButton.icon(
                      onPressed: () => _removeCopies(copies),
                      icon: const Icon(Icons.cleaning_services_outlined),
                      label: Text(l10n.removeCopies(copyCount)),
                    ),
                  ),
                ],
                if (versions.isNotEmpty) ...[
                  _Heading(
                    l10n.differentVersions,
                    hint: l10n.differentVersionsHint,
                  ),
                  for (final group in versions)
                    _VersionGroup(group: group, onOpen: _open),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.title, {required this.hint});

  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: colors.muted,
            ),
          ),
          const SizedBox(height: 6),
          Text(hint, style: TextStyle(fontSize: 15, color: colors.muted)),
        ],
      ),
    );
  }
}

/// One title with its different versions; each opens in the song view.
class _VersionGroup extends StatelessWidget {
  const _VersionGroup({required this.group, required this.onOpen});

  final DuplicateGroup group;
  final void Function(SongEntry song) onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    final first = group.keeper;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              [
                first.title,
                if (first.artist.isNotEmpty) first.artist,
              ].join(' · '),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          for (final song in group.songs)
            ListTile(
              leading: const Icon(Icons.music_note_outlined),
              title: Text(_firstLyric(song.body)),
              subtitle: Text(
                [
                  if (song.songKey != null) l10n.keyLabel(song.songKey!),
                  l10n.addedOn(date.format(song.createdAt)),
                ].join(' · '),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onOpen(song),
            ),
        ],
      ),
    );
  }

  /// The first line of lyrics, without chords, to tell versions apart.
  static String _firstLyric(String body) {
    for (final line in body.split('\n')) {
      final text = line.replaceAll(RegExp(r'\[[^\[\]]*\]'), '').trim();
      if (text.isNotEmpty && !text.startsWith('{') && !text.startsWith('#')) {
        return text;
      }
    }
    return '…';
  }
}
