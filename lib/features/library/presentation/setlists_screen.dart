import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:libre_tab/app/router.dart';
import 'package:libre_tab/app/theme/libre_colors.dart';
import 'package:libre_tab/app/widgets/app_logo.dart';
import 'package:libre_tab/core/widgets/placeholder_body.dart';
import 'package:libre_tab/core/widgets/readable_width.dart';
import 'package:libre_tab/features/library/application/library_providers.dart';
import 'package:libre_tab/features/library/data/setlist_repository.dart';
import 'package:libre_tab/features/library/presentation/widgets/setlist_name_dialog.dart';
import 'package:libre_tab/l10n/l10n.dart';

/// The Setlists tab: every setlist, a search, and "New setlist"
/// (docs/DESIGN.md § Setlists).
class SetlistsScreen extends ConsumerStatefulWidget {
  const SetlistsScreen({super.key});

  @override
  ConsumerState<SetlistsScreen> createState() => _SetlistsScreenState();
}

class _SetlistsScreenState extends ConsumerState<SetlistsScreen> {
  late final _search = TextEditingController(
    text: ref.read(setlistQueryProvider),
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  SetlistQueryController get _query => ref.read(setlistQueryProvider.notifier);

  void _clearSearch() {
    _search.clear();
    _query.query = '';
  }

  Future<void> _newSetlist() async {
    final name = await showSetlistNameDialog(context);
    if (name == null) return;
    final id = await ref.read(setlistRepositoryProvider).create(name);
    if (mounted) await context.push(Routes.setlist(id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final query = ref.watch(setlistQueryProvider);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 20,
        // The logo, not the tab's name: the tab bar says where you are.
        title: const AppLogo(),
      ),
      body: ReadableWidth(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: TextField(
                controller: _search,
                onChanged: (value) => _query.query = value,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.searchSetlistsHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: l10n.clearSearch,
                          icon: const Icon(Icons.close),
                          onPressed: _clearSearch,
                        ),
                ),
              ),
            ),
            Expanded(
              child: _SetlistList(
                query: query,
                onClearSearch: _clearSearch,
                onNew: _newSetlist,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'newSetlist',
        onPressed: _newSetlist,
        icon: const Icon(Icons.playlist_add),
        label: Text(l10n.newSetlist),
      ),
    );
  }
}

class _SetlistList extends ConsumerWidget {
  const _SetlistList({
    required this.query,
    required this.onClearSearch,
    required this.onNew,
  });

  final String query;
  final VoidCallback onClearSearch;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return ref
        .watch(setlistListProvider)
        .when(
          skipLoadingOnReload: true,
          loading: () => const SizedBox.shrink(),
          error: (_, _) => PlaceholderBody(
            icon: Icons.error_outline,
            message: l10n.loadError,
          ),
          data: (list) => list.isEmpty
              ? query.trim().isNotEmpty
                    ? PlaceholderBody(
                        icon: Icons.search_off,
                        message: l10n.noSetlistMatches,
                        action: TextButton(
                          onPressed: onClearSearch,
                          child: Text(l10n.clearSearch),
                        ),
                      )
                    : PlaceholderBody(
                        icon: Icons.queue_music,
                        message: l10n.noSetlists,
                        action: OutlinedButton.icon(
                          onPressed: onNew,
                          icon: const Icon(Icons.playlist_add),
                          label: Text(l10n.newSetlist),
                        ),
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
