import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:libre_tab/core/widgets/placeholder_body.dart';
import 'package:libre_tab/l10n/l10n.dart';

class AddSongScreen extends StatelessWidget {
  const AddSongScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l10n.cancel,
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.addSong),
        actions: [
          // Enabled once the importer exists (milestone 3).
          FilledButton(onPressed: null, child: Text(l10n.save)),
          const SizedBox(width: 16),
        ],
      ),
      body: PlaceholderBody(message: l10n.comingSoon),
    );
  }
}
