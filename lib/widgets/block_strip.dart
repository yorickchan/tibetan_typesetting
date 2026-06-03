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
  final void Function(int oldIndex, int newIndex)? onBlockReorder;
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
    this.onBlockReorder,
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
            height: 78,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Row(
                    children: [
                      _AddButton(label: 'Block', onTap: onAdd),
                      const SizedBox(width: 4),
                      _AddButton(
                        label: 'Page',
                        onTap: onAddPage,
                        outlined: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: ReorderableListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    buildDefaultDragHandles: false,
                    itemCount: blocks.length,
                    onReorderItem: _onReorder,
                    itemBuilder: (context, index) {
                      final b = blocks[index];
                      final globalIdx = globalIndexOf(b.id);
                      final selected = b.id == selectedId;
                      final ok = b.tibetan.trim().isNotEmpty;
                      final tibetanLines = splitLines(b.tibetan);
                      final tibetanLine = tibetanLines.isNotEmpty
                          ? tibetanLines[0]
                          : '';
                      final translationLines = b.isFreeText
                          ? const <String>[]
                          : splitLines(b.chineseTranslation);
                      final chineseLine = translationLines.isNotEmpty
                          ? translationLines[0]
                          : '';

                      return _BlockTile(
                        key: ValueKey(b.id),
                        index: index,
                        block: b,
                        globalIdx: globalIdx,
                        selected: selected,
                        ok: ok,
                        tibetanLine: tibetanLine,
                        chineseLine: chineseLine,
                        tibetanFontFamily: tibetanFontFamily,
                        translationFontFamily: translationFontFamily,
                        onSelect: () => onSelect(b.id),
                      );
                    },
                  ),
                ),
              ],
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

  void _onReorder(int oldIndex, int newIndex) {
    if (onBlockReorder != null) {
      // Adjust: newIndex may need global offset
      onBlockReorder!(oldIndex, newIndex);
    }
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

class _BlockTile extends StatelessWidget {
  final int index;
  final TextBlock block;
  final int globalIdx;
  final bool selected;
  final bool ok;
  final String tibetanLine;
  final String chineseLine;
  final String tibetanFontFamily;
  final String translationFontFamily;
  final VoidCallback onSelect;

  const _BlockTile({
    super.key,
    required this.index,
    required this.block,
    required this.globalIdx,
    required this.selected,
    required this.ok,
    required this.tibetanLine,
    required this.chineseLine,
    required this.tibetanFontFamily,
    required this.translationFontFamily,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReorderableDragStartListener(
            index: index,
            child: Icon(Icons.drag_handle, size: 14, color: AppColors.textFaint),
          ),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: onSelect,
            child: Container(
              width: 100,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                          color: selected ? AppColors.sky400 : AppColors.textMuted,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (block.smallText)
                            const Text(
                              'S',
                              style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: AppColors.amber400),
                            ),
                          if (block.isFreeText)
                            const Text(
                              'F',
                              style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: AppColors.sky400),
                            ),
                          if (block.columnBreakBefore)
                            Container(
                              margin: const EdgeInsets.only(left: 2),
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.sky400.withValues(alpha: 0.6),
                              ),
                            ),
                          Container(
                            margin: const EdgeInsets.only(left: 2),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ok
                                  ? AppColors.emerald400.withValues(alpha: 0.7)
                                  : AppColors.amber400.withValues(alpha: 0.5),
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
                        fontFamily: block.isFreeText ? translationFontFamily : tibetanFontFamily,
                        fontSize: 10,
                        height: 1.2,
                        color: tibetanLine.isEmpty
                            ? AppColors.textFaint
                            : (selected ? AppColors.sky400 : AppColors.textBody),
                        fontStyle: tibetanLine.isEmpty ? FontStyle.italic : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (chineseLine.isNotEmpty)
                    Text(
                      chineseLine,
                      style: TextStyle(fontFamily: translationFontFamily, fontSize: 9, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
