import 'package:flutter/material.dart';

import '../models/project.dart';
import '../utils/colors.dart';
import '../utils/font_constants.dart';
import '../utils/sample_layout.dart';

class BlockStripWidget extends StatelessWidget {
  final List<TextBlock> blocks;
  final int Function(String id) globalIndexOf;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final VoidCallback onAdd;
  final VoidCallback onAddPage;
  final int pageIndex;
  final String tibetanFontFamily;
  final String translationFontFamily;

  const BlockStripWidget({
    super.key,
    required this.blocks,
    required this.globalIndexOf,
    required this.selectedId,
    required this.onSelect,
    required this.onAdd,
    required this.onAddPage,
    required this.pageIndex,
    this.tibetanFontFamily = fallbackTibetanFontFamily,
    this.translationFontFamily = fallbackChineseFontFamily,
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
          SizedBox(
            height: 74,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8),
              itemCount: blocks.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                if (index == blocks.length) {
                  return Row(
                    children: [
                      _AddButton(label: 'Block', onTap: onAdd),
                      const SizedBox(width: 4),
                      _AddButton(
                        label: 'Page',
                        onTap: onAddPage,
                        outlined: true,
                      ),
                    ],
                  );
                }
                final b = blocks[index];
                final globalIdx = globalIndexOf(b.id);
                final selected = b.id == selectedId;
                final ok = b.tibetan.trim().isNotEmpty;
                final tibetanLine = splitLines(b.tibetan).isNotEmpty
                    ? splitLines(b.tibetan)[0]
                    : '';
                final chineseLine =
                    !b.isFreeText && splitLines(b.chineseTranslation).isNotEmpty
                    ? splitLines(b.chineseTranslation)[0]
                    : '';

                return GestureDetector(
                  onTap: () => onSelect(b.id),
                  child: Container(
                    width: 100,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                            ? AppColors.sky500.withValues(alpha: 0.6)
                            : AppColors.border.withValues(alpha: 0.6),
                      ),
                      color: selected
                          ? AppColors.sky500.withValues(alpha: 0.1)
                          : AppColors.borderSubtle.withValues(alpha: 0.4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${globalIdx + 1}',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: selected
                                    ? AppColors.sky400
                                    : AppColors.textMuted,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (b.smallText)
                                  const Text(
                                    'S',
                                    style: TextStyle(
                                      fontSize: 7,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.amber400,
                                    ),
                                  ),
                                if (b.isFreeText)
                                  const Text(
                                    'F',
                                    style: TextStyle(
                                      fontSize: 7,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.sky400,
                                    ),
                                  ),
                                if (b.columnBreakBefore)
                                  Container(
                                    margin: const EdgeInsets.only(left: 2),
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.sky400.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  ),
                                Container(
                                  margin: const EdgeInsets.only(left: 2),
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: ok
                                        ? AppColors.emerald400.withValues(
                                            alpha: 0.7,
                                          )
                                        : AppColors.amber400.withValues(
                                            alpha: 0.5,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Expanded(
                          child: Text(
                            tibetanLine.isEmpty ? 'empty' : tibetanLine,
                            style: TextStyle(
                              fontFamily: b.isFreeText
                                  ? translationFontFamily
                                  : tibetanFontFamily,
                              fontSize: 10,
                              height: 1.2,
                              color: tibetanLine.isEmpty
                                  ? AppColors.textFaint
                                  : (selected
                                        ? AppColors.sky400
                                        : AppColors.textBody),
                              fontStyle: tibetanLine.isEmpty
                                  ? FontStyle.italic
                                  : null,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (chineseLine.isNotEmpty)
                          Text(
                            chineseLine,
                            style: TextStyle(
                              fontFamily: translationFontFamily,
                              fontSize: 9,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${blocks.length} block${blocks.length != 1 ? 's' : ''}',
                  style: TextStyle(color: AppColors.textFaint, fontSize: 10),
                ),
                const SizedBox(width: 4),
                Text(
                  '·',
                  style: TextStyle(color: AppColors.border, fontSize: 10),
                ),
                const SizedBox(width: 4),
                Text(
                  'page ${pageIndex + 1}',
                  style: TextStyle(color: AppColors.textFaint, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool outlined;

  const _AddButton({
    required this.label,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: outlined ? null : AppColors.buttonMutedBg,
          borderRadius: BorderRadius.circular(8),
          border: outlined ? Border.all(color: AppColors.border) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add,
              size: 12,
              color: outlined ? AppColors.textBody : AppColors.buttonMutedFg,
            ),
            const SizedBox(width: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: outlined ? AppColors.textBody : AppColors.buttonMutedFg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
