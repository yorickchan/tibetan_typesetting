import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/project.dart';
import '../utils/colors.dart';
import '../utils/decorations.dart';

class ExportPdfSettingsPanel extends StatelessWidget {
  final PageSetup pageSetup;
  final AppLocalizations l10n;
  final void Function(PageSetup Function(PageSetup)) onUpdateSetup;

  const ExportPdfSettingsPanel({
    super.key,
    required this.pageSetup,
    required this.l10n,
    required this.onUpdateSetup,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.pageSetup,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: pageSetup.leftVerticalTitle,
            style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
            decoration: numberDecor(l10n.leftVerticalTitle),
            onChanged: (value) => onUpdateSetup(
              (setup) => setup.copyWith(leftVerticalTitle: value),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: pageSetup.pageNumber,
            style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
            decoration: numberDecor(l10n.pageNumberLabel),
            onChanged: (value) =>
                onUpdateSetup((setup) => setup.copyWith(pageNumber: value)),
          ),
        ],
      ),
    );
  }
}
