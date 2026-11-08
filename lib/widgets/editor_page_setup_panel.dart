import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/project.dart';
import '../utils/colors.dart';
import 'settings_controls.dart';

class EditorPageSetupPanel extends StatelessWidget {
  final PageSetup pageSetup;
  final bool isOpen;
  final VoidCallback onToggle;
  final AppLocalizations l10n;
  final void Function(PageSetup Function(PageSetup)) onUpdateSetup;

  const EditorPageSetupPanel({
    super.key,
    required this.pageSetup,
    required this.isOpen,
    required this.onToggle,
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
      child: Column(
        children: [
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.settings_outlined,
                    size: 14,
                    color: AppColors.textCaption,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.pageSetup,
                    style: TextStyle(
                      color: AppColors.textBody,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isOpen ? Icons.expand_less : Icons.expand_more,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          if (isOpen) ...[
            Container(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.all(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final sizes = Row(
                    children: [
                      CompactNumberField(
                        initialValue: pageSetup.pageWidthMm,
                        label: l10n.pageWidth,
                        width: 110,
                        onChanged: (value) {
                          if (value >= 50) {
                            onUpdateSetup(
                              (s) => s.copyWith(pageWidthMm: value),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      CompactNumberField(
                        initialValue: pageSetup.pageHeightMm,
                        label: l10n.pageHeight,
                        width: 110,
                        onChanged: (value) {
                          if (value >= 50) {
                            onUpdateSetup(
                              (s) => s.copyWith(pageHeightMm: value),
                            );
                          }
                        },
                      ),
                    ],
                  );
                  final checks = Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      PanelCheckbox(
                        value: pageSetup.showFrame,
                        label: l10n.showFrame,
                        onChanged: (value) => onUpdateSetup(
                          (s) => s.copyWith(showFrame: value),
                        ),
                      ),
                      PanelCheckbox(
                        value: pageSetup.showRowLines,
                        label: l10n.showRowLines,
                        onChanged: (value) => onUpdateSetup(
                          (s) => s.copyWith(showRowLines: value),
                        ),
                      ),
                      if (pageSetup.showRowLines)
                        SizedBox(
                          width: 150,
                          child: CompactNumberField(
                            initialValue: pageSetup.rowLineYOffset,
                            label: l10n.rowLineYOffset,
                            width: 150,
                            signed: true,
                            onChanged: (value) => onUpdateSetup(
                              (s) => s.copyWith(rowLineYOffset: value),
                            ),
                          ),
                        ),
                    ],
                  );
                  if (constraints.maxWidth >= 700) {
                    return Row(
                      children: [
                        sizes,
                        const Spacer(),
                        checks,
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      sizes,
                      const SizedBox(height: 12),
                      checks,
                    ],
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
