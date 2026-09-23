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
    final l10n = context.l10n;
    final renaming = widget.initial != null;
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
