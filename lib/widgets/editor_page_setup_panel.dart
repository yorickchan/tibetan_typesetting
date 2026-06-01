import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/project.dart';
import '../utils/colors.dart';
import '../utils/decorations.dart';

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

  void _updateMargin(String key, double value) {
    onUpdateSetup((setup) {
      final margin = setup.marginMm;
      final updated = switch (key) {
        'top' => margin.copyWith(top: value),
        'bottom' => margin.copyWith(bottom: value),
        'left' => margin.copyWith(left: value),
        'right' => margin.copyWith(right: value),
        _ => margin,
      };
      return setup.copyWith(marginMm: updated);
    });
  }

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
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _NumberField(
                          initialValue: pageSetup.pageWidthMm,
                          label: l10n.pageWidth,
                          onChanged: (value) {
                            if (value >= 50) {
                              onUpdateSetup(
                                (setup) => setup.copyWith(pageWidthMm: value),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _NumberField(
                          initialValue: pageSetup.pageHeightMm,
                          label: l10n.pageHeight,
                          onChanged: (value) {
                            if (value >= 50) {
                              onUpdateSetup(
                                (setup) => setup.copyWith(pageHeightMm: value),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ...[
                        ('top', l10n.top, pageSetup.marginMm.top),
                        ('bottom', l10n.bottom, pageSetup.marginMm.bottom),
                        ('left', l10n.left, pageSetup.marginMm.left),
                        ('right', l10n.right, pageSetup.marginMm.right),
                      ].map(
                        (margin) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _NumberField(
                              initialValue: margin.$3,
                              label: '${margin.$2} (mm)',
                              onChanged: (value) =>
                                  _updateMargin(margin.$1, value),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: pageSetup.showFrame,
                          onChanged: (value) => onUpdateSetup(
                            (setup) => setup.copyWith(showFrame: value),
                          ),
                          activeColor: AppColors.sky500,
                          side: BorderSide(color: AppColors.textMuted),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.showFrame,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final double initialValue;
  final String label;
  final ValueChanged<double> onChanged;

  const _NumberField({
    required this.initialValue,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue.toStringAsFixed(0),
      keyboardType: TextInputType.number,
      style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
      decoration: numberDecor(label),
      onChanged: (value) {
        final number = double.tryParse(value);
        if (number != null) onChanged(number);
      },
    );
  }
}
