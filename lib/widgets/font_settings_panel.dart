import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/app_settings.dart';
import '../models/font_config.dart';
import '../models/project.dart';
import '../services/font_service.dart';
import '../utils/colors.dart';
import 'settings_controls.dart';

class FontSettingsPanel extends StatelessWidget {
  final PageSetup pageSetup;
  final AppSettings appSettings;
  final bool isOpen;
  final VoidCallback onToggle;
  final void Function(PageSetup Function(PageSetup)) onUpdateSetup;
  final AppLocalizations l10n;

  const FontSettingsPanel({
    super.key,
    required this.pageSetup,
    required this.appSettings,
    required this.isOpen,
    required this.onToggle,
    required this.onUpdateSetup,
    required this.l10n,
  });

  bool get _hasOverrides =>
      pageSetup.tibetanFont != null ||
      pageSetup.pronunciationFont != null ||
      pageSetup.translationFont != null;

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
                    Icons.font_download_outlined,
                    size: 14,
                    color: AppColors.textCaption,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.projectFonts,
                    style: TextStyle(
                      color: AppColors.textBody,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (_hasOverrides)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: AppColors.sky500.withValues(alpha: 0.15),
                      ),
                      child: const Text(
                        'CUSTOM',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: AppColors.sky400,
                        ),
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
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 1280;
                      final colWidth = wide
                          ? (constraints.maxWidth - 24) / 3
                          : constraints.maxWidth;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          SizedBox(
                            width: colWidth,
                            child:
                              CompactFontRow(
                                label: 'TIBETAN',
                                current: pageSetup.tibetanFont,
                                defaultName:
                                    appSettings.tibetanFont?.fontFamily ?? '(not set)',
                                defaultSize: appSettings.tibetanFont?.fontSize ?? 10,
                                l10n: l10n,
                                onSelected: (info) {
                                  final existing = pageSetup.tibetanFont;
                                  onUpdateSetup(
                                    (s) => s.copyWith(
                                      tibetanFont: FontConfig(
                                        fontFamily: info.familyName,
                                        fontPath: info.filePath,
                                        fontSize:
                                            existing?.fontSize ??
                                            appSettings.tibetanFont?.fontSize ??
                                            10,
                                      ),
                                    ),
                                  );
                                  FontService().loadFontForPreview(
                                    FontConfig(
                                      fontFamily: info.familyName,
                                      fontPath: info.filePath,
                                      fontSize: 10,
                                    ),
                                  );
                                },
                                onSizeChanged: (v) {
                                  final n = double.tryParse(v);
                                  if (n == null || n <= 0) return;
                                  final base =
                                      pageSetup.tibetanFont ?? appSettings.tibetanFont;
                                  if (base == null) return;
                                  onUpdateSetup(
                                    (s) => s.copyWith(
                                      tibetanFont: base.copyWith(fontSize: n),
                                    ),
                                  );
                                },
                                onReset: () => onUpdateSetup(
                                  (s) => s.copyWith(clearTibetanFont: true),
                                ),
                              ),
                          ),
                          SizedBox(
                            width: colWidth,
                            child:
                              CompactFontRow(
                                label: 'PRONUNCIATION',
                                current: pageSetup.pronunciationFont,
                                defaultName:
                                    appSettings.pronunciationFont?.fontFamily ??
                                    '(not set)',
                                defaultSize: appSettings.pronunciationFont?.fontSize ?? 8,
                                l10n: l10n,
                                onSelected: (info) {
                                  final existing = pageSetup.pronunciationFont;
                                  onUpdateSetup(
                                    (s) => s.copyWith(
                                      pronunciationFont: FontConfig(
                                        fontFamily: info.familyName,
                                        fontPath: info.filePath,
                                        fontSize:
                                            existing?.fontSize ??
                                            appSettings.pronunciationFont?.fontSize ??
                                            8,
                                      ),
                                    ),
                                  );
                                  FontService().loadFontForPreview(
                                    FontConfig(
                                      fontFamily: info.familyName,
                                      fontPath: info.filePath,
                                      fontSize: 8,
                                    ),
                                  );
                                },
                                onSizeChanged: (v) {
                                  final n = double.tryParse(v);
                                  if (n == null || n <= 0) return;
                                  final base =
                                      pageSetup.pronunciationFont ??
                                      appSettings.pronunciationFont;
                                  if (base == null) return;
                                  onUpdateSetup(
                                    (s) => s.copyWith(
                                      pronunciationFont: base.copyWith(fontSize: n),
                                    ),
                                  );
                                },
                                onReset: () => onUpdateSetup(
                                  (s) => s.copyWith(clearPronunciationFont: true),
                                ),
                              ),
                          ),
                          SizedBox(
                            width: colWidth,
                            child:
                              CompactFontRow(
                                label: 'TRANSLATION',
                                current: pageSetup.translationFont,
                                defaultName:
                                    appSettings.translationFont?.fontFamily ?? '(not set)',
                                defaultSize: appSettings.translationFont?.fontSize ?? 8,
                                l10n: l10n,
                                onSelected: (info) {
                                  final existing = pageSetup.translationFont;
                                  onUpdateSetup(
                                    (s) => s.copyWith(
                                      translationFont: FontConfig(
                                        fontFamily: info.familyName,
                                        fontPath: info.filePath,
                                        fontSize:
                                            existing?.fontSize ??
                                            appSettings.translationFont?.fontSize ??
                                            8,
                                      ),
                                    ),
                                  );
                                  FontService().loadFontForPreview(
                                    FontConfig(
                                      fontFamily: info.familyName,
                                      fontPath: info.filePath,
                                      fontSize: 8,
                                    ),
                                  );
                                },
                                onSizeChanged: (v) {
                                  final n = double.tryParse(v);
                                  if (n == null || n <= 0) return;
                                  final base =
                                      pageSetup.translationFont ??
                                      appSettings.translationFont;
                                  if (base == null) return;
                                  onUpdateSetup(
                                    (s) => s.copyWith(
                                      translationFont: base.copyWith(fontSize: n),
                                    ),
                                  );
                                },
                                onReset: () => onUpdateSetup(
                                  (s) => s.copyWith(clearTranslationFont: true),
                                ),
                              ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(height: 1, color: AppColors.divider),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final smallBlock = Row(
                        children: [
                          SizedBox(
                            width: 190,
                            child: SettingsSectionLabel(
                              l10n.smallBlockFontSize,
                            ),
                          ),
                          SizedBox(
                            width: 150,
                            child: TextFormField(
                              initialValue: pageSetup.smallBlockFontSize
                                  ?.toStringAsFixed(1) ??
                                  '',
                              keyboardType: TextInputType.number,
                              onChanged: (v) {
                                if (v.isEmpty) {
                                  onUpdateSetup(
                                    (s) => s.copyWith(
                                      clearSmallBlockFontSize: true,
                                    ),
                                  );
                                  return;
                                }
                                final n = double.tryParse(v);
                                if (n == null || n <= 0) return;
                                onUpdateSetup(
                                  (s) => s.copyWith(smallBlockFontSize: n),
                                );
                              },
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                              ),
                              decoration: compactNumberDecor(null).copyWith(
                                hintText: l10n.smallBlockFontSizeHint,
                                hintStyle: TextStyle(
                                  color: AppColors.textFaint,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 28,
                            child: pageSetup.smallBlockFontSize != null
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.restart_alt,
                                      size: 16,
                                    ),
                                    tooltip: l10n.resetToDefault,
                                    onPressed: () => onUpdateSetup(
                                      (s) => s.copyWith(
                                        clearSmallBlockFontSize: true,
                                      ),
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 28,
                                      minHeight: 28,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      );
                      final gap = Row(
                        children: [
                          SizedBox(
                            width: 190,
                            child: SettingsSectionLabel(l10n.contentTextGap),
                          ),
                          CompactNumberField(
                            initialValue: pageSetup.contentTextGapPx,
                            width: 90,
                            signed: true,
                            onChanged: (n) => onUpdateSetup(
                              (s) => s.copyWith(contentTextGapPx: n),
                            ),
                          ),
                        ],
                      );
                      if (constraints.maxWidth >= 700) {
                        return Row(
                          children: [
                            Expanded(child: smallBlock),
                            const SizedBox(width: 20),
                            Expanded(child: gap),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          smallBlock,
                          const SizedBox(height: 10),
                          gap,
                        ],
                      );
                    },
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
