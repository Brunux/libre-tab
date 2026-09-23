import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libre_tab/app/theme/theme_controller.dart';
import 'package:libre_tab/core/widgets/placeholder_body.dart';
import 'package:libre_tab/l10n/l10n.dart';

class SongViewScreen extends ConsumerWidget {
  const SongViewScreen({required this.songId, super.key});

  final String songId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.songTitlePlaceholder),
        actions: [
          IconButton(
            tooltip: l10n.switchTheme,
            icon: const Icon(Icons.dark_mode_outlined),
            onPressed: () => ref.read(themeVariantProvider.notifier).cycle(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: PlaceholderBody(message: l10n.comingSoon),
    );
  }
}
