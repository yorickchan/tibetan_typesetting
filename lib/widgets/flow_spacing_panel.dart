import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/project.dart';
import '../utils/colors.dart';

class FlowSpacingPanel extends StatelessWidget {
  final PageSetup pageSetup;
  final AppLocalizations l10n;
  final void Function(PageSetup Function(PageSetup)) onUpdateSetup;

  const FlowSpacingPanel({
    super.key,
    required this.pageSetup,
    required this.l10n,
    required this.onUpdateSetup,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.format_line_spacing, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(
            l10n.sentenceSpacing,
            style: TextStyle(
              color: AppColors.textBody,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Slider(
              value: pageSetup.flowGap.clamp(0.0, 0.08),
              min: 0,
              max: 0.08,
              divisions: 8,
              activeColor: AppColors.sky500,
              inactiveColor: AppColors.border,
              onChanged: (v) => onUpdateSetup((s) => s.copyWith(flowGap: v)),
            ),
          ),
          SizedBox(
            width: 42,
            child: Text(
              '${(pageSetup.flowGap * 100).round()}%',
              textAlign: TextAlign.right,
              style: TextStyle(color: AppColors.textCaption, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
