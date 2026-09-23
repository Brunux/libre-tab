import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:libre_tab/l10n/l10n.dart';

/// Asks for a setlist name. Returns the trimmed name, or null if cancelled.
/// [initial] is the current name when renaming.
Future<String?> showSetlistNameDialog(
  BuildContext context, {
  String? initial,
}) => showDialog<String>(
  context: context,
  builder: (_) => _SetlistNameDialog(initial: initial),
);

class _SetlistNameDialog extends StatefulWidget {
  const _SetlistNameDialog({this.initial});

  final String? initial;

  @override
  State<_SetlistNameDialog> createState() => _SetlistNameDialogState();
}

class _SetlistNameDialogState extends State<_SetlistNameDialog> {
  late final _name = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isNotEmpty) Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final renaming = widget.initial != null;
    // iOS can report a negative keyboard inset for a frame while the
    // keyboard animates, which Dialog asserts against.
    final media = MediaQuery.of(context);
    final insets = media.viewInsets;
    return MediaQuery(
      data: media.copyWith(
        viewInsets: EdgeInsets.fromLTRB(
          math.max(0, insets.left),
          math.max(0, insets.top),
          math.max(0, insets.right),
          math.max(0, insets.bottom),
        ),
      ),
      child: _dialog(context, renaming: renaming),
    );
  }

  Widget _dialog(BuildContext context, {required bool renaming}) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(renaming ? l10n.renameSetlist : l10n.newSetlist),
      content: TextField(
        controller: _name,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: l10n.setlistNameLabel,
          hintText: l10n.setlistNameHint,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ListenableBuilder(
          listenable: _name,
          builder: (context, _) => TextButton(
            onPressed: _name.text.trim().isEmpty ? null : _submit,
            child: Text(renaming ? l10n.save : l10n.create),
          ),
        ),
      ],
    );
  }
}
