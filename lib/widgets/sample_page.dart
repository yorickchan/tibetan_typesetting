import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/font_config.dart';
import '../models/project.dart';
import '../utils/colors.dart';
import '../utils/font_constants.dart';
import '../utils/font_utils.dart' as font_utils;
import '../utils/sample_layout.dart';

const double kMmToPx = 3.78;

class SamplePageWidget extends StatelessWidget {
  final Project project;
  final AppSettings? appSettings;
  final List<List<TextBlock?>>? rows;
  final List<List<LayoutCell>>? flowRows;
  final int? colCount;
  final bool showMark;
  final String? pageNumber;
  final String? highlightBlockId;

  const SamplePageWidget({
    super.key,
    required this.project,
    this.appSettings,
    this.rows,
    this.flowRows,
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
    final effectiveFlowRows =
        flowRows ??
        (rows != null
            ? _flowRowsFromLegacyRows(rows!)
            : paginateBlocks(
                blocks,
                fallbackColCount,
                4,
                setup.flowGap,
              ).first.flowRows);
    final effectiveColCount = colCount ?? fallbackColCount;

    final pageW = setup.pageWidthMm * kMmToPx;
    final pageH = setup.pageHeightMm * kMmToPx;

    final tibFont = font_utils.effectiveFont(
      setup.tibetanFont,
      appSettings?.tibetanFont,
      fallbackTibetanFont,
    );
    final pronFont = font_utils.effectiveFont(
      setup.pronunciationFont,
      appSettings?.pronunciationFont,
      fallbackChineseFont,
    );
    final transFont = font_utils.effectiveFont(
      setup.translationFont,
      appSettings?.translationFont,
      fallbackChineseFont,
    );

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
                  fontFamily: transFont.fontFamily,
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.rose600, width: 1),
                    ),
                    child: _ContentGrid(
                      rows: effectiveFlowRows,
                      colCount: effectiveColCount,
                      showMark: showMark,
                      highlightBlockId: highlightBlockId,
                      tibetanFont: tibFont,
                      pronunciationFont: pronFont,
                      translationFont: transFont,
                    ),
                  ),
                ),
                _SidePanel(
                  text: pageNumber ?? setup.pageNumber,
                  showFrame: setup.showFrame,
                  fontFamily: transFont.fontFamily,
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
  final String fontFamily;

  const _SidePanel({
    required this.text,
    required this.showFrame,
    required this.fontFamily,
  });

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
            style: TextStyle(
              fontFamily: fontFamily,
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
  final List<List<LayoutCell>> rows;
  final int colCount;
  final bool showMark;
  final String? highlightBlockId;
  final FontConfig tibetanFont;
  final FontConfig pronunciationFont;
  final FontConfig translationFont;

  const _ContentGrid({
    required this.rows,
    required this.colCount,
    required this.showMark,
    this.highlightBlockId,
    required this.tibetanFont,
    required this.pronunciationFont,
    required this.translationFont,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.expand();

    final tibFamily = tibetanFont.fontFamily;
    final pronFamily = pronunciationFont.fontFamily;
    final transFamily = translationFont.fontFamily;
    final tibSize = tibetanFont.fontSize;
    final chiSize = pronunciationFont.fontSize;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalW = constraints.maxWidth;
        final totalH = constraints.maxHeight;
        final rowCount = rows.length;
        const smallRowShrink = 4 * kMmToPx;

        final baseRowH = totalH / rowCount;
        final shortRowH = baseRowH - smallRowShrink;
        final normalRowH = baseRowH;

        final rowYs = <double>[];
        final rowHs = <double>[];
        double yAccum = 0;
        for (var ri = 0; ri < rowCount; ri++) {
          rowYs.add(yAccum);
          final h = shouldUseShortRow(rows[ri]) ? shortRowH : normalRowH;
          rowHs.add(h);
          yAccum += h;
        }

        final children = <Widget>[];

        for (var ri = 0; ri < rows.length; ri++) {
          final row = rows[ri];
          for (var cellIndex = 0; cellIndex < row.length; cellIndex++) {
            final cell = row[cellIndex];
            final block = cell.block;

            final isHL = highlightBlockId == block.id;
            final isSmall = block.smallText;

            final tibLines = splitLines(block.tibetan);
            final heading = tibLines.isNotEmpty ? tibLines[0] : '';
            final body = tibLines.length > 1
                ? tibLines.sublist(1).join(' ')
                : '';
            final pron = splitLines(block.chinesePronunciation).join(' ');
            final trans = isSmall
                ? ''
                : splitLines(block.chineseTranslation).join(' ');
            final doShowMark = showMark && ri == 0 && cellIndex == 0;

            final smallFactor = isSmall ? 0.75 : 1.0;
            final headingSize =
                font_utils.previewFontSize(tibSize) * smallFactor;
            final bodySize = font_utils.previewFontSize(tibSize) * smallFactor;
            final chineseSize =
                font_utils.previewFontSize(chiSize) * smallFactor;

            final left = cell.leftFraction * totalW;
            final spannedW = cell.widthFraction * totalW;
            final blockW = isSmall && block.columnSpan == null
                ? (totalW - left)
                : spannedW.clamp(0, totalW - left).toDouble();

            children.add(
              Positioned(
                left: left,
                top: rowYs[ri],
                width: blockW,
                height: rowHs[ri],
                child: Container(
                  padding: const EdgeInsets.only(top: 16, left: 6, right: 6),
                  decoration: isHL
                      ? BoxDecoration(
                          color: const Color.fromARGB(
                            255,
                            183,
                            179,
                            255,
                          ).withValues(alpha: 0.6),
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
                                TextSpan(
                                  text: '༄༅།།   ',
                                  style: TextStyle(
                                    fontFamily: tibFamily,
                                    color: AppColors.rose600,
                                  ),
                                ),
                              TextSpan(text: heading),
                            ],
                          ),
                          style: TextStyle(
                            fontFamily: tibFamily,
                            fontSize: headingSize,
                            color: AppColors.rose600,
                            height: isSmall ? 1.2 : 0.75,
                          ),
                          maxLines: isSmall ? null : 2,
                          overflow: isSmall ? null : TextOverflow.ellipsis,
                        ),
                      if (body.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(
                            body,
                            style: TextStyle(
                              fontFamily: tibFamily,
                              fontSize: bodySize,
                              color: Colors.black87,
                              height: isSmall ? 1.2 : 0.75,
                            ),
                            maxLines: isSmall ? null : 3,
                            overflow: isSmall ? null : TextOverflow.ellipsis,
                          ),
                        ),
                      if (pron.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(
                            top: 2,
                            left: doShowMark ? headingSize * 3.5 : 0,
                          ),
                          child: Text(
                            pron,
                            style: TextStyle(
                              fontFamily: pronFamily,
                              fontSize: chineseSize,
                              color: Colors.black87,
                              height: 1,
                            ),
                            maxLines: isSmall ? null : 2,
                            overflow: isSmall ? null : TextOverflow.ellipsis,
                          ),
                        ),
                      if (trans.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(
                            top: 1,
                            left: doShowMark ? headingSize * 3.5 : 0,
                          ),
                          child: Text(
                            trans,
                            style: TextStyle(
                              fontFamily: transFamily,
                              fontSize: chineseSize,
                              color: Colors.black87,
                              height: 1,
                            ),
                            maxLines: isSmall ? null : 2,
                            overflow: isSmall ? null : TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }
        }

        return Stack(clipBehavior: Clip.none, children: children);
      },
    );
  }
}

List<List<LayoutCell>> _flowRowsFromLegacyRows(List<List<TextBlock?>> rows) {
  return rows.map((row) {
    final cells = <LayoutCell>[];
    for (var i = 0; i < row.length; i++) {
      final block = row[i];
      if (block != null) {
        cells.add(
          LayoutCell(
            block: block,
            leftFraction: row.isEmpty ? 0 : i / row.length,
            widthFraction: row.isEmpty ? 1 : 1 / row.length,
          ),
        );
      }
    }
    return cells;
  }).toList();
}
