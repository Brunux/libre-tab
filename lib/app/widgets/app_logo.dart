import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libre_tab/app/theme/app_theme.dart';
import 'package:libre_tab/app/theme/libre_colors.dart';
import 'package:libre_tab/app/theme/theme_controller.dart';

/// The horizontal logo at the top of each tab: the campfire mark and
/// "Libre Tab" in Fraunces (branding/README.md). Built here rather than
/// from the lockup PNG so the name takes the theme's text colour; in Red
/// night the mark is the red one, keeping the screen to red light only.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  /// The app's name is a brand: the same in every language.
  static const name = 'Libre Tab';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: name,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BrandMark(size: 44),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: AppFonts.displayStyle(30, context.colors.text),
            ),
          ),
        ],
      ),
    );
  }
}

/// The campfire mark, in the Red night palette under Red night.
class BrandMark extends ConsumerWidget {
  const BrandMark({required this.size, super.key});

  final double size;

  static const _day = 'assets/images/mark.png';
  static const _night = 'assets/images/mark-red-night.png';

  /// Both marks, to load ahead of the first frame.
  static const List<String> assets = [_day, _night];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final night = ref.watch(themeVariantProvider) == AppThemeVariant.redNight;
    return Image.asset(
      night ? _night : _day,
      width: size,
      height: size,
      excludeFromSemantics: true,
    );
  }
}
