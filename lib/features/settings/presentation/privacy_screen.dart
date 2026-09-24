import 'package:flutter/material.dart';
import 'package:libre_tab/app/theme/libre_colors.dart';
import 'package:libre_tab/core/widgets/readable_width.dart';
import 'package:libre_tab/l10n/l10n.dart';

/// Where the full privacy policy lives (PRIVACY.md in the repository).
const privacyPolicyUrl =
    'https://github.com/Brunux/libre-tab/blob/main/PRIVACY.md';

/// The privacy policy in short, inside the app (App Store guideline
/// 5.1.1(i)): readable offline, with where to find the full text.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final heading = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final body = TextStyle(fontSize: 16, height: 1.45, color: colors.text);

    Widget section(String title, String text) => Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: heading),
          const SizedBox(height: 6),
          Text(text, style: body),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyTitle)),
      body: ReadableWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              l10n.privacySummary,
              style: body.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            section(l10n.privacySongsTitle, l10n.privacySongsBody),
            section(l10n.privacyMicTitle, l10n.privacyMicBody),
            section(l10n.privacyPhotosTitle, l10n.privacyPhotosBody),
            const SizedBox(height: 28),
            Text(l10n.privacyMore, style: TextStyle(color: colors.muted)),
            const SizedBox(height: 4),
            SelectableText(
              privacyPolicyUrl,
              style: TextStyle(color: colors.accent),
            ),
          ],
        ),
      ),
    );
  }
}
