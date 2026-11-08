import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/app_settings.dart';
import '../models/font_config.dart';
import '../models/project.dart';
import '../models/title_page_template.dart';
import '../services/font_service.dart';
import '../utils/colors.dart';
import '../utils/font_constants.dart';
import '../utils/font_utils.dart' as font_utils;
import 'settings_controls.dart';

class TitlePageSettingsPanel extends StatelessWidget {
  final PageSetup pageSetup;
  final AppSettings appSettings;
  final bool isOpen;
  final VoidCallback onToggle;
  final void Function(PageSetup Function(PageSetup)) onUpdateSetup;
  final AppLocalizations l10n;
  final List<TitlePageTemplate> templates;

  const TitlePageSettingsPanel({
    super.key,
    required this.pageSetup,
    required this.appSettings,
    required this.isOpen,
    required this.onToggle,
    required this.onUpdateSetup,
    required this.l10n,
    this.templates = const [],
  });

  void _updateInset(String key, double value) {
    onUpdateSetup((setup) {
      final inset = setup.templateInset;
      final updated = switch (key) {
        'top' => inset.copyWith(top: value),
        'bottom' => inset.copyWith(bottom: value),
        'left' => inset.copyWith(left: value),
        'right' => inset.copyWith(right: value),
        _ => inset,
      };
      return setup.copyWith(templateInset: updated);
    });
  }

  void _updateTitleTextInset(String key, double value) {
    onUpdateSetup((setup) {
      final inset = setup.titleTextInset;
      final updated = switch (key) {
        'top' => inset.copyWith(top: value),
        'bottom' => inset.copyWith(bottom: value),
        'left' => inset.copyWith(left: value),
        'right' => inset.copyWith(right: value),
        _ => inset,
      };
      return setup.copyWith(titleTextInset: updated);
    });
  }

  TitlePageTemplate? _templateFor(String? id) {
    if (id == null) return null;
    for (final template in templates) {
      if (template.id == id) return template;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final template = _templateFor(pageSetup.titlePageTemplateId);
    final tibFont = font_utils.effectiveFont(
      pageSetup.tibetanFont,
      appSettings.tibetanFont,
      fallbackTibetanFont,
    );
    final transFont = font_utils.effectiveFont(
      pageSetup.translationFont,
      appSettings.translationFont,
      fallbackChineseFont,
    );

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      PanelCheckbox(
                        value: pageSetup.showTitlePage,
                        label: l10n.showTitlePage,
                        onChanged: (value) => onUpdateSetup(
                          (s) => s.copyWith(showTitlePage: value),
                        ),
                      ),
                      if (templates.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            initialValue:
                                pageSetup.titlePageTemplateId != null &&
                                    templates.any(
                                      (t) =>
                                          t.id ==
                                          pageSetup.titlePageTemplateId,
                                    )
                                ? pageSetup.titlePageTemplateId
                                : null,
                            decoration: compactNumberDecor(
                              l10n.titlePageTemplate,
                            ),
                            dropdownColor: AppColors.surfaceContainer,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                            ),
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text(l10n.defaultLayout),
                              ),
                              ...templates.map(
                                (t) => DropdownMenuItem<String?>(
                                  value: t.id,
                                  child: Text(t.name),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              onUpdateSetup(
                                (s) => s.copyWith(
                                  titlePageTemplateId: value,
                                  clearTitlePageTemplateId: value == null,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        TemplateThumb(svgContent: template?.svgContent),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  _SettingsField(
                    label: l10n.tibetanLabel,
                    value: pageSetup.titleTibetan,
                    placeholder: l10n.titleTibetanLabel,
                    fontFamily:
                        (pageSetup.titleTibetanFont ?? tibFont).fontFamily,
                    onChanged: (v) =>
                        onUpdateSetup((s) => s.copyWith(titleTibetan: v)),
                  ),
                  const SizedBox(height: 8),
                  _SettingsField(
                    label: l10n.chineseLabel,
                    value: pageSetup.titleChinese,
                    placeholder: l10n.titleChineseLabel,
                    fontFamily:
                        (pageSetup.titleChineseFont ?? transFont).fontFamily,
                    onChanged: (v) =>
                        onUpdateSetup((s) => s.copyWith(titleChinese: v)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SizedBox(
                        width: 190,
                        child: SettingsSectionLabel(l10n.titleTextGap),
                      ),
                      CompactNumberField(
                        initialValue: pageSetup.titleTextGapPx,
                        width: 90,
                        signed: true,
                        onChanged: (n) => onUpdateSetup(
                          (s) => s.copyWith(titleTextGapPx: n),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 1180;
                      final groups = [
                        MarginRow(
                          label: l10n.templateInset,
                          top: pageSetup.templateInset.top,
                          bottom: pageSetup.templateInset.bottom,
                          left: pageSetup.templateInset.left,
                          right: pageSetup.templateInset.right,
                          l10n: l10n,
                          onTop: (v) => _updateInset('top', v),
                          onBottom: (v) => _updateInset('bottom', v),
                          onLeft: (v) => _updateInset('left', v),
                          onRight: (v) => _updateInset('right', v),
                        ),
                        MarginRow(
                          label: l10n.titleTextInset,
                          top: pageSetup.titleTextInset.top,
                          bottom: pageSetup.titleTextInset.bottom,
                          left: pageSetup.titleTextInset.left,
                          right: pageSetup.titleTextInset.right,
                          max: 150,
                          l10n: l10n,
                          onTop: (v) => _updateTitleTextInset('top', v),
                          onBottom: (v) => _updateTitleTextInset('bottom', v),
                          onLeft: (v) => _updateTitleTextInset('left', v),
                          onRight: (v) => _updateTitleTextInset('right', v),
                        ),
                      ];
                      if (wide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: groups[0]),
                            const SizedBox(width: 20),
                            Expanded(child: groups[1]),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          groups[0],
                          const SizedBox(height: 10),
                          groups[1],
                        ],
                      );
                    },
                  ),
                  Container(height: 1, color: AppColors.divider),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 1180;
                      final tibetanRow = CompactFontRow(
                          label: 'TITLE TIBETAN FONT',
                          current: pageSetup.titleTibetanFont,
                          defaultName: tibFont.fontFamily,
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
                            final base = pageSetup.titleTibetanFont ?? tibFont;
                            onUpdateSetup(
                              (s) => s.copyWith(
                                titleTibetanFont: base.copyWith(fontSize: n),
                              ),
                            );
                          },
                          onReset: () => onUpdateSetup(
                            (s) => s.copyWith(clearTitleTibetanFont: true),
                          ),
                        );
                      final chineseRow = CompactFontRow(
                          label: 'TITLE CHINESE FONT',
                          current: pageSetup.titleChineseFont,
                          defaultName: transFont.fontFamily,
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
                                  fontSize:
                                      pageSetup.titleChineseFont?.fontSize ?? 8,
                                ),
                              ),
                            );
                          },
                          onSizeChanged: (v) {
                            final n = double.tryParse(v);
                            if (n == null || n <= 0) return;
                            final base = pageSetup.titleChineseFont ?? transFont;
                            onUpdateSetup(
                              (s) => s.copyWith(
                                titleChineseFont: base.copyWith(fontSize: n),
                              ),
                            );
                          },
                          onReset: () => onUpdateSetup(
                            (s) => s.copyWith(clearTitleChineseFont: true),
                          ),
                        );
                      if (wide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: tibetanRow),
                            const SizedBox(width: 16),
                            Expanded(child: chineseRow),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          tibetanRow,
                          const SizedBox(height: 8),
                          chineseRow,
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
