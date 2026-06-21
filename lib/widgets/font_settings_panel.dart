import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/app_settings.dart';
import '../models/font_config.dart';
import '../models/project.dart';
import '../services/font_service.dart';
import '../utils/colors.dart';
import 'font_picker.dart';

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
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _FontOverrideRow(
                    label: 'TIBETAN',
                    current: pageSetup.tibetanFont,
                    appDefault: appSettings.tibetanFont,
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
                      final cur = pageSetup.tibetanFont;
                      if (cur == null) return;
                      onUpdateSetup(
                        (s) =>
                            s.copyWith(tibetanFont: cur.copyWith(fontSize: n)),
                      );
                    },
                    onReset: () => onUpdateSetup(
                      (s) => s.copyWith(clearTibetanFont: true),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _FontOverrideRow(
                    label: 'PRONUNCIATION',
                    current: pageSetup.pronunciationFont,
                    appDefault: appSettings.pronunciationFont,
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
                      final cur = pageSetup.pronunciationFont;
                      if (cur == null) return;
                      onUpdateSetup(
                        (s) => s.copyWith(
                          pronunciationFont: cur.copyWith(fontSize: n),
                        ),
                      );
                    },
                    onReset: () => onUpdateSetup(
                      (s) => s.copyWith(clearPronunciationFont: true),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _FontOverrideRow(
                    label: 'TRANSLATION',
                    current: pageSetup.translationFont,
                    appDefault: appSettings.translationFont,
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
                      final cur = pageSetup.translationFont;
                      if (cur == null) return;
                      onUpdateSetup(
                        (s) => s.copyWith(
                          translationFont: cur.copyWith(fontSize: n),
                        ),
                      );
                    },
                    onReset: () => onUpdateSetup(
                      (s) => s.copyWith(clearTranslationFont: true),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        l10n.smallBlockFontSize,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const Spacer(),
                      if (pageSetup.smallBlockFontSize != null)
                        GestureDetector(
                          onTap: () => onUpdateSetup(
                            (s) => s.copyWith(clearSmallBlockFontSize: true),
                          ),
                          child: Text(
                            l10n.resetToDefault,
                            style: TextStyle(
                              color: AppColors.sky500,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          width: 70,
                          child: TextFormField(
                            initialValue: pageSetup.smallBlockFontSize
                                ?.toStringAsFixed(1) ?? '',
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
                            decoration: InputDecoration(
                              hintText: l10n.smallBlockFontSizeHint,
                              hintStyle: TextStyle(
                                color: AppColors.textFaint,
                                fontSize: 10,
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              filled: true,
                              fillColor: AppColors.inputFill,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppColors.sky500,
                                ),
                              ),
                            ),
                          ),
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

class _FontOverrideRow extends StatelessWidget {
  final String label;
  final FontConfig? current;
  final FontConfig? appDefault;
  final AppLocalizations l10n;
  final ValueChanged<SystemFontInfo> onSelected;
  final ValueChanged<String> onSizeChanged;
  final VoidCallback onReset;

  const _FontOverrideRow({
    required this.label,
    required this.current,
    required this.appDefault,
    required this.l10n,
    required this.onSelected,
    required this.onSizeChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final hasOverride = current != null;
    final effectiveName =
        current?.fontFamily ?? appDefault?.fontFamily ?? '(not set)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
            const Spacer(),
            if (!hasOverride)
              Text(
                'Default: $effectiveName',
                style: TextStyle(color: AppColors.textFaint, fontSize: 10),
              ),
            if (hasOverride)
              GestureDetector(
                onTap: onReset,
                child: Text(
                  l10n.resetToDefault,
                  style: TextStyle(
                    color: AppColors.sky500,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: FontPicker(
                label: '',
                selectedPath: current?.fontPath,
                onSelected: onSelected,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 70,
              child: TextFormField(
                initialValue: (current?.fontSize ?? appDefault?.fontSize ?? 10)
                    .toStringAsFixed(1),
                keyboardType: TextInputType.number,
                onChanged: onSizeChanged,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  labelText: l10n.size,
                  labelStyle: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  filled: true,
                  fillColor: AppColors.inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.sky500),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
