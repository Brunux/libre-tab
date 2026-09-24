import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:libre_tab/l10n/l10n.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  /// Material's "expanded" width: tablets, and phones in landscape.
  static const railFrom = 840.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    void go(int index) =>
        shell.goBranch(index, initialLocation: index == shell.currentIndex);

    // Big screens: a side rail, so the tabs don't stretch across the width.
    if (MediaQuery.sizeOf(context).width >= railFrom) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              right: false,
              child: NavigationRail(
                selectedIndex: shell.currentIndex,
                onDestinationSelected: go,
                labelType: NavigationRailLabelType.all,
                groupAlignment: -0.9,
                destinations: [
                  NavigationRailDestination(
                    icon: const Icon(Icons.menu_book_outlined),
                    selectedIcon: const Icon(Icons.menu_book),
                    label: Text(l10n.tabSongbook),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.queue_music_outlined),
                    selectedIcon: const Icon(Icons.queue_music),
                    label: Text(l10n.tabSetlists),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.speed_outlined),
                    selectedIcon: const Icon(Icons.speed),
                    label: Text(l10n.tabTuner),
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: shell),
          ],
        ),
      );
    }

    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: go,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book),
            label: l10n.tabSongbook,
          ),
          NavigationDestination(
            icon: const Icon(Icons.queue_music_outlined),
            selectedIcon: const Icon(Icons.queue_music),
            label: l10n.tabSetlists,
          ),
          NavigationDestination(
            icon: const Icon(Icons.speed_outlined),
            selectedIcon: const Icon(Icons.speed),
            label: l10n.tabTuner,
          ),
        ],
      ),
    );
  }
}
