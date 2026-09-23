import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libre_tab/app/theme/app_theme.dart';
import 'package:libre_tab/app/theme/libre_colors.dart';
import 'package:libre_tab/app/theme/theme_controller.dart';
import 'package:libre_tab/l10n/l10n.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final variant = ref.watch(themeVariantProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            l10n.themeLabel.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: context.colors.muted,
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<AppThemeVariant>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: AppThemeVariant.dark,
                label: Text(l10n.themeDark),
              ),
              ButtonSegment(
                value: AppThemeVariant.redNight,
                label: Text(l10n.themeRedNight),
              ),
              ButtonSegment(
                value: AppThemeVariant.light,
                label: Text(l10n.themeLight),
              ),
            ],
            selected: {variant},
            onSelectionChanged: (selection) =>
                ref.read(themeVariantProvider.notifier).variant =
                    selection.single,
          ),
        ],
      ),
    );
  }
}
