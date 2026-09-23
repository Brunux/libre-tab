import 'package:flutter/material.dart';
import 'package:libre_tab/core/widgets/placeholder_body.dart';
import 'package:libre_tab/l10n/l10n.dart';

class TunerScreen extends StatelessWidget {
  const TunerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 20,
        title: Text(
          l10n.tabTuner,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
      ),
      body: PlaceholderBody(message: l10n.comingSoon),
    );
  }
}
