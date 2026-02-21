import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/app_settings.dart';
import '../models/font_config.dart';
import '../models/project.dart';
import '../services/font_service.dart';
import '../utils/colors.dart';
import '../utils/font_constants.dart';
import '../utils/font_utils.dart' as font_utils;
import 'font_picker.dart';

class TitlePageSettingsPanel extends StatelessWidget {
  final PageSetup pageSetup;
  final AppSettings appSettings;
  final bool isOpen;
  final VoidCallback onToggle;
  final void Function(PageSetup Function(PageSetup)) onUpdateSetup;
  final AppLocalizations l10n;

  const TitlePageSettingsPanel({
    super.key,
    required this.pageSetup,
    required this.appSettings,
    required this.isOpen,
    required this.onToggle,
    required this.onUpdateSetup,
    required this.l10n,
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
                    Icons.description_outlined,
                    size: 14,
                    color: AppColors.textCaption,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.titlePage,
                    style: TextStyle(
                      color: AppColors.textBody,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: pageSetup.showTitlePage
                          ? AppColors.emerald400.withValues(alpha: 0.15)
                          : AppColors.border.withValues(alpha: 0.4),
                    ),
                    child: Text(
                      pageSetup.showTitlePage ? 'ON' : 'OFF',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: pageSetup.showTitlePage
                            ? AppColors.emerald400
                            : AppColors.textMuted,
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
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: pageSetup.showTitlePage,
                          onChanged: (v) => onUpdateSetup(
                            (s) => s.copyWith(showTitlePage: v),
                          ),
                          activeColor: AppColors.sky500,
                          side: BorderSide(color: AppColors.textMuted),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.showTitlePage,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _SettingsField(
                    label: l10n.tibetanLabel,
                    value: pageSetup.titleTibetan,
                    placeholder: l10n.titleTibetanLabel,
                    fontFamily:
                        (pageSetup.titleTibetanFont ??
                                font_utils.effectiveFont(
                                  pageSetup.tibetanFont,
                                  appSettings.tibetanFont,
                                  fallbackTibetanFont,
                                ))
                            .fontFamily,
                    onChanged: (v) =>
                        onUpdateSetup((s) => s.copyWith(titleTibetan: v)),
                  ),
                  const SizedBox(height: 8),
                  _SettingsField(
                    label: l10n.chineseLabel,
                    value: pageSetup.titleChinese,
                    placeholder: l10n.titleChineseLabel,
                    fontFamily:
                        (pageSetup.titleChineseFont ??
                                font_utils.effectiveFont(
                                  pageSetup.translationFont,
                                  appSettings.translationFont,
                                  fallbackChineseFont,
                                ))
                            .fontFamily,
                    onChanged: (v) =>
                        onUpdateSetup((s) => s.copyWith(titleChinese: v)),
                  ),
                  const SizedBox(height: 12),
                  Container(height: 1, color: AppColors.divider),
                  const SizedBox(height: 12),
                  _TitleFontRow(
                    label: 'TITLE TIBETAN FONT',
                    current: pageSetup.titleTibetanFont,
                    fallback: font_utils.effectiveFont(
                      pageSetup.tibetanFont,
                      appSettings.tibetanFont,
                      fallbackTibetanFont,
                    ),
                    defaultSize: 10,
                    l10n: l10n,
                    onSelected: (info) {
                      FontService().loadFontForPreview(
                        FontConfig(
                          fontFamily: info.familyName,
                          fontPath: info.filePath,
                          fontSize: 10,
                        ),
                      );
                      onUpdateSetup(
                        (s) => s.copyWith(
                          titleTibetanFont: FontConfig(
                            fontFamily: info.familyName,
                            fontPath: info.filePath,
                            fontSize:
                                pageSetup.titleTibetanFont?.fontSize ?? 10,
                          ),
                        ),
                      );
                    },
                    onSizeChanged: (v) {
                      final n = double.tryParse(v);
                      if (n == null || n <= 0) return;
                      final cur = pageSetup.titleTibetanFont;
                      if (cur == null) return;
                      onUpdateSetup(
                        (s) => s.copyWith(
                          titleTibetanFont: cur.copyWith(fontSize: n),
                        ),
                      );
                    },
                    onReset: () => onUpdateSetup(
                      (s) => s.copyWith(clearTitleTibetanFont: true),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _TitleFontRow(
                    label: 'TITLE CHINESE FONT',
                    current: pageSetup.titleChineseFont,
                    fallback: font_utils.effectiveFont(
                      pageSetup.translationFont,
                      appSettings.translationFont,
                      fallbackChineseFont,
                    ),
                    defaultSize: 8,
                    l10n: l10n,
                    onSelected: (info) {
                      FontService().loadFontForPreview(
                        FontConfig(
                          fontFamily: info.familyName,
                          fontPath: info.filePath,
                          fontSize: 8,
                        ),
                      );
                      onUpdateSetup(
                        (s) => s.copyWith(
                          titleChineseFont: FontConfig(
                            fontFamily: info.familyName,
                            fontPath: info.filePath,
                            fontSize: pageSetup.titleChineseFont?.fontSize ?? 8,
                          ),
                        ),
                      );
                    },
                    onSizeChanged: (v) {
                      final n = double.tryParse(v);
                      if (n == null || n <= 0) return;
                      final cur = pageSetup.titleChineseFont;
                      if (cur == null) return;
                      onUpdateSetup(
                        (s) => s.copyWith(
                          titleChineseFont: cur.copyWith(fontSize: n),
                        ),
                      );
                    },
                    onReset: () => onUpdateSetup(
                      (s) => s.copyWith(clearTitleChineseFont: true),
                    ),
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

class _TitleFontRow extends StatelessWidget {
  final String label;
  final FontConfig? current;
  final FontConfig fallback;
  final double defaultSize;
  final AppLocalizations l10n;
  final ValueChanged<SystemFontInfo> onSelected;
  final ValueChanged<String> onSizeChanged;
  final VoidCallback onReset;

  const _TitleFontRow({
    required this.label,
    required this.current,
    required this.fallback,
    required this.defaultSize,
    required this.l10n,
    required this.onSelected,
    required this.onSizeChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final hasOverride = current != null;
    final effectiveName = current?.fontFamily ?? fallback.fontFamily;

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
                initialValue: (current?.fontSize ?? defaultSize)
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

class _SettingsField extends StatelessWidget {
  final String label;
  final String value;
  final String placeholder;
  final String? fontFamily;
  final ValueChanged<String> onChanged;

  const _SettingsField({
    required this.label,
    required this.value,
    required this.placeholder,
    this.fontFamily,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(color: AppColors.textCaption, fontSize: 10),
          ),
        ),
        Expanded(
          child: TextFormField(
            initialValue: value,
            onChanged: onChanged,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.5),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              filled: true,
              fillColor: AppColors.inputFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.sky500),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
