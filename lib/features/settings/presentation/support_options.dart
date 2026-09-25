import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libre_tab/app/theme/app_theme.dart';
import 'package:libre_tab/app/theme/libre_colors.dart';
import 'package:libre_tab/app/widgets/app_logo.dart';
import 'package:libre_tab/core/device/support_channel.dart';
import 'package:libre_tab/l10n/l10n.dart';

/// Whether the Buy Me a Coffee link may be shown. App Store guideline
/// 3.1.1(a) allows links to outside payment only in the United States
/// storefront, and Google Play only through programs Libre Tab isn't in, so
/// it's shown on iPhone and iPad from the US App Store and nowhere else.
final coffeeAllowedProvider = FutureProvider<bool>((ref) async {
  if (defaultTargetPlatform != TargetPlatform.iOS) return false;
  return await ref.watch(supportChannelProvider).storefront() == 'USA';
});

/// "Support Libre Tab": a thank-you, then the ways to help — a coffee
/// (where allowed), a rating, a share, a GitHub star. In Settings, and in
/// the sheet the one-time nudge opens (docs/DESIGN.md § Settings).
class SupportOptions extends ConsumerWidget {
  const SupportOptions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final support = ref.read(supportChannelProvider);
    final coffee = ref.watch(coffeeAllowedProvider).value ?? false;

    Widget option(
      IconData icon,
      String title,
      String hint,
      VoidCallback onTap, {
      bool highlight = false,
    }) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: highlight ? colors.accent : null),
      title: Text(
        title,
        style: highlight
            ? TextStyle(fontWeight: FontWeight.w700, color: colors.accent)
            : null,
      ),
      subtitle: Text(hint),
      onTap: onTap,
    );

    // Material, not a coloured box: the rows' ripples show on it.
    return Material(
      color: colors.surface2,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const BrandMark(size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.supportHeadline,
                    style: AppFonts.displayStyle(20, colors.text),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(l10n.supportBody, style: TextStyle(color: colors.muted)),
            const SizedBox(height: 4),
            if (coffee)
              option(
                Icons.coffee_outlined,
                l10n.supportCoffee,
                l10n.supportCoffeeHint,
                () => support.open(SupportLink.coffee),
                highlight: true,
              ),
            option(
              Icons.star_outline_rounded,
              l10n.supportRate,
              l10n.supportRateHint,
              support.rate,
            ),
            option(
              Icons.ios_share,
              l10n.supportShare,
              l10n.supportShareHint,
              () => support.share(l10n.shareAppText),
            ),
            option(
              Icons.code,
              l10n.supportGithub,
              l10n.supportGithubHint,
              () => support.open(SupportLink.github),
            ),
          ],
        ),
      ),
    );
  }
}
