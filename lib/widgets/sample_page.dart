import 'dart:io';

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
  final List<TextBlock> floatingImages;
  final void Function(String id, double dxMm, double dyMm)? onFloatImageMove;
  final void Function(String id, double dwMm, double dhMm)? onFloatImageResize;
  final void Function(String id, double dwMm, double dhMm)? onInlineImageResize;
  final void Function(String id)? onSelectBlock;

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
    this.floatingImages = const [],
    this.onFloatImageMove,
    this.onFloatImageResize,
    this.onInlineImageResize,
    this.onSelectBlock,
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
                setup.pageWidthMm - setup.marginMm.left - setup.marginMm.right,
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
                      showRowLines: setup.showRowLines,
                      highlightBlockId: highlightBlockId,
                      tibetanFont: tibFont,
                      pronunciationFont: pronFont,
                      translationFont: transFont,
                      floatingImages: floatingImages,
                      onFloatImageMove: onFloatImageMove,
                      onFloatImageResize: onFloatImageResize,
                      onInlineImageResize: onInlineImageResize,
                      onSelectBlock: onSelectBlock,
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
  static int _dragMode = 0;

  final List<List<LayoutCell>> rows;
  final int colCount;
  final bool showMark;
  final bool showRowLines;
  final String? highlightBlockId;
  final FontConfig tibetanFont;
  final FontConfig pronunciationFont;
  final FontConfig translationFont;

  final List<TextBlock> floatingImages;
  final void Function(String id, double dxMm, double dyMm)? onFloatImageMove;
  final void Function(String id, double dwMm, double dhMm)? onFloatImageResize;
  final void Function(String id, double dwMm, double dhMm)? onInlineImageResize;
  final void Function(String id)? onSelectBlock;

  const _ContentGrid({
    required this.rows,
    required this.colCount,
    required this.showMark,
    required this.showRowLines,
    this.highlightBlockId,
    required this.tibetanFont,
    required this.pronunciationFont,
    required this.translationFont,
    this.floatingImages = const [],
    this.onFloatImageMove,
    this.onFloatImageResize,
    this.onInlineImageResize,
    this.onSelectBlock,
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
        final smallTibetanSize = contentTibetanFontSize(
          font_utils.previewFontSize(tibSize),
          smallText: true,
        );
        final smallChineseSize = font_utils.previewFontSize(chiSize) * 0.75;
        for (var ri = 0; ri < rowCount; ri++) {
          rowYs.add(yAccum);
          final minShortRowH = estimateCompactSmallRowHeight(
            rows[ri],
            tibetanFontSize: smallTibetanSize,
            chineseFontSize: smallChineseSize,
            topPadding: 16,
          );
          final h =
              shouldUseShortRow(
                rows[ri],
                availableHeight: shortRowH,
                minimumHeight: minShortRowH,
              )
              ? shortRowH
              : normalRowH;
          rowHs.add(h);
          yAccum += h;
        }

        final children = <Widget>[];

        if (showRowLines) {
          const rowLineColor = Color(0xFFFFD700);
          const rowLineHeight = 1.0;
          const rowLineOffset = 18.0;
          for (var ri = 0; ri < rowCount; ri++) {
            final hasNormalBlock = rows[ri].any(
              (cell) =>
                  !cell.block.smallText &&
                  !cell.block.isFreeText &&
                  !cell.block.isImageBlock,
            );
            if (!hasNormalBlock) continue;
            children.add(
              Positioned(
                left: 0,
                top: rowYs[ri] + rowLineOffset,
                width: totalW,
                child: Container(height: rowLineHeight, color: rowLineColor),
              ),
            );
          }
        }

        for (var ri = 0; ri < rows.length; ri++) {
          final row = rows[ri];
          for (var cellIndex = 0; cellIndex < row.length; cellIndex++) {
            final cell = row[cellIndex];
            final block = cell.block;

            final isHL = highlightBlockId == block.id;
            final isSmall = block.smallText;
            final isFreeText = block.isFreeText;
            final isCompact = isSmall || isFreeText;

            if (block.isImageBlock) {
              final left = cell.leftFraction * totalW;
              final spannedW = cell.widthFraction * totalW;
              final cellW = spannedW.clamp(0, totalW - left).toDouble();
              final cellH = rowHs[ri];
              final imgH = block.imageHeightMm != null
                  ? (block.imageHeightMm! * kMmToPx)
                        .clamp(10.0, cellH)
                        .toDouble()
                  : cellH;
              const edgeZone = 12.0;
              children.add(
                Positioned(
                  left: left,
                  top: rowYs[ri],
                  width: cellW,
                  height: cellH,
                  child: MouseRegion(
                    onHover: (event) {
                      if (!isHL) return;
                    },
                    cursor: isHL
                        ? SystemMouseCursors.resizeDownRight
                        : SystemMouseCursors.click,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelectBlock?.call(block.id),
                      onPanStart: (details) {
                        if (!isHL) {
                          _ContentGrid._dragMode = 0;
                          return;
                        }
                        final pos = details.localPosition;
                        final nearRight = pos.dx >= cellW - edgeZone;
                        final nearBottom = pos.dy >= cellH - edgeZone;
                        if (nearRight && nearBottom) {
                          _ContentGrid._dragMode = 3;
                        } else if (nearRight) {
                          _ContentGrid._dragMode = 1;
                        } else if (nearBottom) {
                          _ContentGrid._dragMode = 2;
                        } else {
                          _ContentGrid._dragMode = 0;
                        }
                      },
                      onPanUpdate: (details) {
                        if (_ContentGrid._dragMode == 0) return;
                        final dw = details.delta.dx / kMmToPx;
                        final dh = details.delta.dy / kMmToPx;
                        switch (_ContentGrid._dragMode) {
                          case 1:
                            onInlineImageResize?.call(block.id, dw, 0);
                          case 2:
                            onInlineImageResize?.call(block.id, 0, dh);
                          case 3:
                            onInlineImageResize?.call(block.id, dw, dh);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.only(
                          top: 16,
                          left: 6,
                          right: 6,
                        ),
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
                        child: SizedBox(
                          height: imgH,
                          child: ColoredBox(
                            color: AppColors.emerald400.withValues(alpha: 0.15),
                            child: block.imagePath != null
                                ? Stack(
                                    children: [
                                      Positioned.fill(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          child: Image.file(
                                            File(block.imagePath!),
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) =>
                                                const Center(
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    size: 24,
                                                    color: AppColors.rose600,
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ),
                                      if (isHL) ...[
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          bottom: 0,
                                          width: edgeZone,
                                          child: Container(
                                            color: AppColors.sky500.withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          height: edgeZone,
                                          child: Container(
                                            color: AppColors.sky500.withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.image,
                                      size: 24,
                                      color: AppColors.amber400,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              continue;
            }

            final tibLines = splitLines(block.tibetan);
            final heading = tibLines.isNotEmpty ? tibLines[0] : '';
            final body = tibLines.length > 1
                ? tibLines.sublist(1).join(' ')
                : '';
            final pron = splitLines(block.chinesePronunciation).join(' ');
            final trans = isCompact
                ? ''
                : splitLines(block.chineseTranslation).join(' ');
            final doShowMark =
                !isFreeText && showMark && ri == 0 && cellIndex == 0;

            final headingSize = contentTibetanFontSize(
              font_utils.previewFontSize(tibSize),
              smallText: isSmall,
            );
            final bodySize = headingSize;
            final chineseSize = isFreeText
                ? font_utils.previewFontSize(translationFont.fontSize) * 0.75
                : font_utils.previewFontSize(chiSize) * (isSmall ? 0.75 : 1.0);

            final left = cell.leftFraction * totalW;
            final spannedW = cell.widthFraction * totalW;
            final blockW = isCompact && block.columnSpan == null
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
                      if (isFreeText)
                        Text(
                          tibLines.join('\n'),
                          style: TextStyle(
                            fontFamily: transFamily,
                            fontSize: chineseSize,
                            color: Colors.black87,
                            height: 1.2,
                          ),
                          maxLines: null,
                        ),
                      if (!isFreeText && (heading.isNotEmpty || doShowMark))
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
                            height: contentTibetanLineHeight(
                              smallText: isSmall,
                            ),
                          ),
                          maxLines: isSmall ? null : 2,
                          overflow: isSmall ? null : TextOverflow.ellipsis,
                        ),
                      if (!isFreeText && body.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(
                            body,
                            style: TextStyle(
                              fontFamily: tibFamily,
                              fontSize: bodySize,
                              color: Colors.black87,
                              height: contentTibetanLineHeight(
                                smallText: isSmall,
                              ),
                            ),
                            maxLines: isSmall ? null : 3,
                            overflow: isSmall ? null : TextOverflow.ellipsis,
                          ),
                        ),
                      if (!isFreeText && pron.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(
                            top: 2,
                            left: doShowMark
                                ? contentOpeningMarkIndent(headingSize)
                                : 0,
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
                      if (!isFreeText && trans.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(
                            top: 1,
                            left: doShowMark
                                ? contentOpeningMarkIndent(headingSize)
                                : 0,
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

        // ---- Floating image overlay ----
        for (final fi in floatingImages) {
          final imgX = (fi.imageXMm ?? 10) * kMmToPx;
          final imgY = (fi.imageYMm ?? 10) * kMmToPx;
          final imgW = (fi.imageWidthMm ?? 30) * kMmToPx;
          final imgH = (fi.imageHeightMm ?? 30) * kMmToPx;
          final isSelected = fi.id == highlightBlockId;
          const edgeZone = 12.0;

          children.add(
            Positioned(
              left: imgX,
              top: imgY,
              width: imgW,
              height: imgH,
              child: MouseRegion(
                cursor: isSelected
                    ? SystemMouseCursors.resizeDownRight
                    : SystemMouseCursors.move,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (details) {
                    if (!isSelected) {
                      _ContentGrid._dragMode = 0;
                      return;
                    }
                    final pos = details.localPosition;
                    final nearRight = pos.dx >= imgW - edgeZone;
                    final nearBottom = pos.dy >= imgH - edgeZone;
                    if (nearRight && nearBottom) {
                      _ContentGrid._dragMode = 3;
                    } else if (nearRight) {
                      _ContentGrid._dragMode = 1;
                    } else if (nearBottom) {
                      _ContentGrid._dragMode = 2;
                    } else {
                      _ContentGrid._dragMode = 0;
                    }
                  },
                  onPanUpdate: (details) {
                    if (_ContentGrid._dragMode == 0) {
                      onFloatImageMove?.call(
                        fi.id,
                        details.delta.dx / kMmToPx,
                        details.delta.dy / kMmToPx,
                      );
                    } else {
                      final dw = details.delta.dx / kMmToPx;
                      final dh = details.delta.dy / kMmToPx;
                      switch (_ContentGrid._dragMode) {
                        case 1:
                          onFloatImageResize?.call(fi.id, dw, 0);
                        case 2:
                          onFloatImageResize?.call(fi.id, 0, dh);
                        case 3:
                          onFloatImageResize?.call(fi.id, dw, dh);
                      }
                    }
                  },
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: fi.imagePath != null
                              ? Image.file(
                                  File(fi.imagePath!),
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.broken_image,
                                    size: 16,
                                    color: AppColors.textFaint,
                                  ),
                                )
                              : Icon(
                                  Icons.image,
                                  size: 16,
                                  color: AppColors.textFaint,
                                ),
                        ),
                      ),
                      if (isSelected) ...[
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.sky500,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          width: edgeZone,
                          child: Container(
                            color: AppColors.sky500.withValues(alpha: 0.3),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: edgeZone,
                          child: Container(
                            color: AppColors.sky500.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
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
