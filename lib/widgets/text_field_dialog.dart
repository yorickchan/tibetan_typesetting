import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../utils/colors.dart';

/// Small single-field dialog shared by template create/rename flows.
class TextFieldDialog extends StatefulWidget {
  final String title;
  final String label;
  final String confirmLabel;
  final String initialValue;

  const TextFieldDialog({
    super.key,
    required this.title,
    required this.label,
    required this.confirmLabel,
    this.initialValue = '',
  });

  @override
  State<TextFieldDialog> createState() => _TextFieldDialogState();
}

class _TextFieldDialogState extends State<TextFieldDialog> {
  late final _ctrl = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(widget.title, style: TextStyle(color: AppColors.textPrimary)),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: TextStyle(color: AppColors.textCaption),
          filled: true,
          fillColor: AppColors.surfaceContainer,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.border),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            l10n.cancel,
            style: TextStyle(color: AppColors.textCaption),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _ctrl.text.trim()),
          child: Text(
            widget.confirmLabel,
            style: const TextStyle(
              color: AppColors.sky500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
