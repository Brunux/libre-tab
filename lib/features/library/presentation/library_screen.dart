import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:libre_tab/app/router.dart';
import 'package:libre_tab/core/widgets/placeholder_body.dart';
import 'package:libre_tab/l10n/l10n.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 20,
        title: Text(
          l10n.tabSongbook,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        actions: [
          IconButton(
            tooltip: l10n.settingsTitle,
            icon: const Icon(Icons.tune),
            onPressed: () => context.push(Routes.settings),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: PlaceholderBody(message: l10n.emptySongbook),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.addSong),
        icon: const Icon(Icons.add),
        label: Text(l10n.addSong),
      ),
    );
  }
}
