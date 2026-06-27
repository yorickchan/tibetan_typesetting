import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/chinese_script.dart';
import '../utils/colors.dart';

class ChineseScriptSwitch extends StatelessWidget {
  final ChineseScript selectedScript;
  final bool busy;
  final ValueChanged<ChineseScript> onSelected;

  const ChineseScriptSwitch({
    super.key,
    required this.selectedScript,
    this.busy = false,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        Text(
          l10n.chineseScript,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        _ScriptButton(
          label: l10n.simplifiedChinese,
          selected: selectedScript == ChineseScript.simplified,
          onPressed: busy ? null : () => onSelected(ChineseScript.simplified),
        ),
        _ScriptButton(
          label: l10n.traditionalChinese,
          selected: selectedScript == ChineseScript.traditional,
          onPressed: busy ? null : () => onSelected(ChineseScript.traditional),
        ),
        if (busy)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }
}

class _ScriptButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  const _ScriptButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? AppColors.sky500 : Colors.transparent,
        foregroundColor: selected ? Colors.white : AppColors.textBody,
        side: BorderSide(color: selected ? AppColors.sky500 : AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      child: Text(label),
    );
  }
}

String chineseScriptLabel(AppLocalizations l10n, ChineseScript script) {
  return switch (script) {
    ChineseScript.simplified => l10n.simplifiedChinese,
    ChineseScript.traditional => l10n.traditionalChinese,
    ChineseScript.unknown => l10n.chineseScript,
  };
}

Future<bool> showChineseScriptConversionDialog(
  BuildContext context,
  ChineseScript target,
) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        l10n.convertChineseScriptTitle(chineseScriptLabel(l10n, target)),
      ),
      content: Text(l10n.convertChineseScriptWarning),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.convertChineseScriptAction),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
