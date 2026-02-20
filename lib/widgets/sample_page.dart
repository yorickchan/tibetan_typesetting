import 'package:flutter/material.dart';

import '../models/project.dart';
import '../utils/colors.dart';
import '../utils/sample_layout.dart';

const double kMmToPx = 3.78;

class SamplePageWidget extends StatelessWidget {
  final Project project;
  final List<List<TextBlock?>>? rows;
  final int? colCount;
  final bool showMark;
  final String? pageNumber;
  final String? highlightBlockId;

  const SamplePageWidget({
    super.key,
    required this.project,
    this.rows,
    this.colCount,
    this.showMark = false,
    this.pageNumber,
    this.highlightBlockId,
  });

  @override
  Widget build(BuildContext context) {
    final setup = project.pageSetup;
    final blocks = project.blocks;
    final fallbackColCount = (setup.columnCount > 0)
        ? setup.columnCount.clamp(1, 8)
        : 5;
    final effectiveRows = rows ?? blocksToRows(blocks, fallbackColCount);
    final effectiveColCount = colCount ?? fallbackColCount;

    final pageW = setup.pageWidthMm * kMmToPx;
    final pageH = setup.pageHeightMm * kMmToPx;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: pageW,
        height: pageH,
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.only(
            top: setup.marginMm.top * kMmToPx,
            right: setup.marginMm.right * kMmToPx,
            bottom: setup.marginMm.bottom * kMmToPx,
            left: setup.marginMm.left * kMmToPx,
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: setup.showFrame
                    ? AppColors.rose600
                    : Colors.grey.shade300,
                width: setup.showFrame ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                _SidePanel(
                  text: setup.leftVerticalTitle,
                  showFrame: setup.showFrame,
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.rose600, width: 1),
                    ),
                    child: _ContentGrid(
                      rows: effectiveRows,
                      colCount: effectiveColCount,
                      showMark: showMark,
                      highlightBlockId: highlightBlockId,
                    ),
                  ),
                ),
                _SidePanel(
                  text: pageNumber ?? setup.pageNumber,
                  showFrame: setup.showFrame,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidePanel extends StatelessWidget {
  final String text;
  final bool showFrame;

  const _SidePanel({required this.text, required this.showFrame});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.rose600,
          width: showFrame ? 1 : 0.5,
        ),
      ),
      child: Center(
        child: RotatedBox(
          quarterTurns: 1,
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'STHeiti',
              fontSize: 11,
              color: AppColors.rose600,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class _ContentGrid extends StatelessWidget {
  final List<List<TextBlock?>> rows;
  final int colCount;
  final bool showMark;
  final String? highlightBlockId;

  const _ContentGrid({
    required this.rows,
    required this.colCount,
    required this.showMark,
    this.highlightBlockId,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.expand();

    return Column(
      children: List.generate(rows.length, (ri) {
        final row = rows[ri];
        return Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(colCount, (ci) {
              final block = (ci < row.length) ? row[ci] : null;
              if (block == null) return const Expanded(child: SizedBox());

              final isHL = highlightBlockId == block.id;
              final tibLines = splitLines(block.tibetan);
              final heading = tibLines.isNotEmpty ? tibLines[0] : '';
              final body = tibLines.length > 1
                  ? tibLines.sublist(1).join(' ')
                  : '';
              final pron = splitLines(block.chinesePronunciation).join(' ');
              final trans = splitLines(block.chineseTranslation).join(' ');
              final doShowMark = showMark && ri == 0 && ci == 0;

              final headingSize = block.smallText ? 8.0 : 11.0;
              final bodySize = block.smallText ? 9.0 : 12.0;
              final chineseSize = block.smallText ? 8.0 : 10.0;

              return Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: isHL
                      ? BoxDecoration(
                          color: Colors.amber.shade100.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(4),
                        )
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (heading.isNotEmpty || doShowMark)
                        Text.rich(
                          TextSpan(
                            children: [
                              if (doShowMark)
                                const TextSpan(
                                  text: '༄༅།།   ',
                                  style: TextStyle(
                                    fontFamily: 'BabelStoneTibetan',
                                    color: Colors.black87,
                                  ),
                                ),
                              TextSpan(text: heading),
                            ],
                          ),
                          style: TextStyle(
                            fontFamily: 'BabelStoneTibetan',
                            fontSize: headingSize,
                            color: AppColors.rose600,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (body.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(
                            body,
                            style: TextStyle(
                              fontFamily: 'BabelStoneTibetan',
                              fontSize: bodySize,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (pron.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            pron,
                            style: TextStyle(
                              fontFamily: 'STHeiti',
                              fontSize: chineseSize,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (trans.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(
                            trans,
                            style: TextStyle(
                              fontFamily: 'STHeiti',
                              fontSize: chineseSize,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}
