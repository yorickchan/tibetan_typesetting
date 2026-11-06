import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/project.dart';
import '../models/title_page_template.dart';
import '../utils/colors.dart';
import 'settings_controls.dart';

class ContentPageTemplatePanel extends StatelessWidget {
  final PageSetup pageSetup;
  final bool isOpen;
  final VoidCallback onToggle;
  final void Function(PageSetup Function(PageSetup)) onUpdateSetup;
  final AppLocalizations l10n;
  final List<TitlePageTemplate> templates;

  const ContentPageTemplatePanel({
    super.key,
    required this.pageSetup,
    required this.isOpen,
    required this.onToggle,
    required this.onUpdateSetup,
    required this.l10n,
    this.templates = const [],
  });

  @override
  Widget build(BuildContext context) {
    final first = _ContentSection(
      title: l10n.contentFirstPage,
      templateLabel: l10n.contentFirstPageTemplate,
      marginLabel: l10n.contentFirstPageMargin,
      templateId: pageSetup.contentFirstPageTemplateId,
      templateInset: pageSetup.contentFirstPageTemplateInset,
      margin: pageSetup.contentFirstPageMargin,
      templates: templates,
      l10n: l10n,
      onTemplateChanged: (v) {
        onUpdateSetup(
          (s) => s.copyWith(
            contentFirstPageTemplateId: v,
            clearContentFirstPageTemplateId: v == null,
          ),
        );
      },
      onInsetChanged: (key, value) {
        onUpdateSetup((s) {
          final inset = s.contentFirstPageTemplateInset;
          final updated = switch (key) {
            'top' => inset.copyWith(top: value),
            'bottom' => inset.copyWith(bottom: value),
            'left' => inset.copyWith(left: value),
            'right' => inset.copyWith(right: value),
            _ => inset,
          };
          return s.copyWith(contentFirstPageTemplateInset: updated);
        });
      },
      onMarginChanged: (key, value) {
        onUpdateSetup((s) {
          final m = s.contentFirstPageMargin;
          final updated = switch (key) {
            'top' => m.copyWith(top: value),
            'bottom' => m.copyWith(bottom: value),
            'left' => m.copyWith(left: value),
            'right' => m.copyWith(right: value),
            _ => m,
          };
          return s.copyWith(contentFirstPageMargin: updated);
        });
      },
    );

    final subsequent = _ContentSection(
      title: l10n.contentSubsequentPages,
      templateLabel: l10n.contentSubsequentPageTemplate,
      marginLabel: l10n.contentSubsequentPageMargin,
      templateId: pageSetup.contentSubsequentPageTemplateId,
      templateInset: pageSetup.contentSubsequentPageTemplateInset,
      margin: pageSetup.contentSubsequentPageMargin,
      templates: templates,
      l10n: l10n,
      onTemplateChanged: (v) {
        onUpdateSetup(
          (s) => s.copyWith(
            contentSubsequentPageTemplateId: v,
            clearContentSubsequentPageTemplateId: v == null,
          ),
        );
      },
      onInsetChanged: (key, value) {
        onUpdateSetup((s) {
          final inset = s.contentSubsequentPageTemplateInset;
          final updated = switch (key) {
            'top' => inset.copyWith(top: value),
            'bottom' => inset.copyWith(bottom: value),
            'left' => inset.copyWith(left: value),
            'right' => inset.copyWith(right: value),
            _ => inset,
          };
          return s.copyWith(contentSubsequentPageTemplateInset: updated);
        });
      },
      onMarginChanged: (key, value) {
        onUpdateSetup((s) {
          final m = s.contentSubsequentPageMargin;
          final updated = switch (key) {
            'top' => m.copyWith(top: value),
            'bottom' => m.copyWith(bottom: value),
            'left' => m.copyWith(left: value),
            'right' => m.copyWith(right: value),
            _ => m,
          };
          return s.copyWith(contentSubsequentPageMargin: updated);
        });
      },
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
                    Icons.article_outlined,
                    size: 14,
                    color: AppColors.textCaption,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.contentPages,
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
                  if (constraints.maxWidth >= 900) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: first),
                        const SizedBox(width: 20),
                        Expanded(child: subsequent),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      first,
                      const SizedBox(height: 16),
                      Container(height: 1, color: AppColors.divider),
                      const SizedBox(height: 16),
                      subsequent,
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

class _ContentSection extends StatelessWidget {
  final String title;
  final String templateLabel;
  final String marginLabel;
  final String? templateId;
  final TemplateInset templateInset;
  final MarginMm margin;
  final List<TitlePageTemplate> templates;
  final AppLocalizations l10n;
  final ValueChanged<String?> onTemplateChanged;
  final void Function(String key, double value) onInsetChanged;
  final void Function(String key, double value) onMarginChanged;

  const _ContentSection({
    required this.title,
    required this.templateLabel,
    required this.marginLabel,
    required this.templateId,
    required this.templateInset,
    required this.margin,
    required this.templates,
    required this.l10n,
    required this.onTemplateChanged,
    required this.onInsetChanged,
    required this.onMarginChanged,
  });

  TitlePageTemplate? get _template {
    if (templateId == null) return null;
    for (final template in templates) {
      if (template.id == templateId) return template;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final template = _template;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.textBody,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (templates.isNotEmpty)
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue:
                      templateId != null &&
                          templates.any((t) => t.id == templateId)
                      ? templateId
                      : null,
                  decoration: compactNumberDecor(templateLabel),
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
                  onChanged: onTemplateChanged,
                ),
              ),
            if (templates.isNotEmpty) const SizedBox(width: 12),
            TemplateThumb(svgContent: template?.svgContent),
          ],
        ),
        const SizedBox(height: 10),
        MarginRow(
          label: l10n.templateInset,
          top: templateInset.top,
          bottom: templateInset.bottom,
          left: templateInset.left,
          right: templateInset.right,
          l10n: l10n,
          onTop: (v) => onInsetChanged('top', v),
          onBottom: (v) => onInsetChanged('bottom', v),
          onLeft: (v) => onInsetChanged('left', v),
          onRight: (v) => onInsetChanged('right', v),
        ),
        const SizedBox(height: 10),
        MarginRow(
          label: marginLabel,
          top: margin.top,
          bottom: margin.bottom,
          left: margin.left,
          right: margin.right,
          l10n: l10n,
          onTop: (v) => onMarginChanged('top', v),
          onBottom: (v) => onMarginChanged('bottom', v),
          onLeft: (v) => onMarginChanged('left', v),
          onRight: (v) => onMarginChanged('right', v),
        ),
      ],
    );
  }
}
