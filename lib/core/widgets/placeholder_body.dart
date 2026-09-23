import 'package:flutter/material.dart';
import 'package:libre_tab/app/theme/libre_colors.dart';

/// Centered muted message for screens whose feature isn't built yet.
class PlaceholderBody extends StatelessWidget {
  const PlaceholderBody({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, color: context.colors.muted),
        ),
      ),
    );
  }
}
