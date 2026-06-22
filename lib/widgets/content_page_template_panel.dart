import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/app_localizations.dart';
import '../models/project.dart';
import '../models/title_page_template.dart';
import '../utils/colors.dart';
import '../utils/decorations.dart';

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ContentSection(
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
                        return s.copyWith(
                          contentFirstPageTemplateInset: updated,
                        );
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
                  ),
                  if (templates.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(height: 1, color: AppColors.divider),
                    const SizedBox(height: 12),
                  ],
                  _ContentSection(
                    title: l10n.contentSubsequentPages,
                    templateLabel: l10n.contentSubsequentPageTemplate,
                    marginLabel: l10n.contentSubsequentPageMargin,
                    templateId: pageSetup.contentSubsequentPageTemplateId,
                    templateInset:
                        pageSetup.contentSubsequentPageTemplateInset,
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
                        return s.copyWith(
                          contentSubsequentPageTemplateInset: updated,
                        );
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
                        return s.copyWith(
                          contentSubsequentPageMargin: updated,
                        );
                      });
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

  @override
  Widget build(BuildContext context) {
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
        if (templates.isNotEmpty) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            initialValue: templateId != null &&
                    templates.any((t) => t.id == templateId)
                ? templateId
                : null,
            decoration: InputDecoration(
              labelText: templateLabel,
              labelStyle: TextStyle(
                color: AppColors.textCaption,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
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
          if (templateId != null) ...[
            const SizedBox(height: 8),
            Builder(
              builder: (_) {
                final t = templates.firstWhere(
                  (t) => t.id == templateId,
                  orElse: () => templates.first,
                );
                return ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SvgPicture.string(
                    t.svgContent,
                    width: 200,
                    fit: BoxFit.contain,
                    placeholderBuilder: (_) => const SizedBox(
                      height: 60,
                      child: Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              l10n.templateInset,
              style: TextStyle(
                color: AppColors.textCaption,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                    ('top', l10n.top, templateInset.top),
                    ('bottom', l10n.bottom, templateInset.bottom),
                    ('left', l10n.left, templateInset.left),
                    ('right', l10n.right, templateInset.right),
                  ]
                  .map(
                    (e) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: e.$1 != 'right' ? 8 : 0,
                        ),
                        child: TextFormField(
                          initialValue: e.$3.toStringAsFixed(0),
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                          decoration: numberDecor(e.$2),
                          onChanged: (v) {
                            final n = double.tryParse(v);
                            if (n != null && n >= 0 && n <= 100) {
                              onInsetChanged(e.$1, n);
                            }
                          },
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
        const SizedBox(height: 8),
        Text(
          marginLabel,
          style: TextStyle(
            color: AppColors.textCaption,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
                ('top', l10n.top, margin.top),
                ('bottom', l10n.bottom, margin.bottom),
                ('left', l10n.left, margin.left),
                ('right', l10n.right, margin.right),
              ]
              .map(
                (e) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: e.$1 != 'right' ? 8 : 0,
                    ),
                    child: TextFormField(
                      initialValue: e.$3.toStringAsFixed(0),
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                      decoration: numberDecor(e.$2),
                      onChanged: (v) {
                        final n = double.tryParse(v);
                        if (n != null && n >= 0 && n <= 100) {
                          onMarginChanged(e.$1, n);
                        }
                      },
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
