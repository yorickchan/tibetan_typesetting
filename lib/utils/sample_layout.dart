import '../models/project.dart';

const int maxColumnSpan = 24;

String resolvePageNumber(String base, int index) {
  final trimmed = base.trim();
  if (trimmed.isEmpty) return '${index + 1}';
  final num = int.tryParse(trimmed);
  if (num != null) return '${num + index}';
  return trimmed;
}

final RegExp _lineBreak = RegExp(r'\r?\n');

List<String> splitLines(String s) {
  return s
      .split(_lineBreak)
      .map((x) => x.trim())
      .where((x) => x.isNotEmpty)
      .toList();
}

String contentTextForRaster(String text) => splitLines(text).join(' ');

class LayoutCell {
  final TextBlock block;
  final double leftFraction;
  final double widthFraction;

  const LayoutCell({
    required this.block,
    required this.leftFraction,
    required this.widthFraction,
  });

  int get start => (leftFraction * 1000).round();
  int get span => (widthFraction * 1000).round();
}

class _Row {
  final List<LayoutCell> cells;
  final bool pageBreakBefore;

  _Row({required this.cells, required this.pageBreakBefore});
}

class PageLayout {
  final int colCount;
  final List<List<LayoutCell>> flowRows;
  final List<List<TextBlock?>> rows;
  final List<TextBlock> floatingImages;

  PageLayout({
    required this.colCount,
    required this.flowRows,
    this.floatingImages = const [],
  }) : rows = _legacyRows(flowRows, colCount);
}

List<_Row> _buildRows(
  List<TextBlock> blocks,
  double gapFraction, [
  double? contentWidthMm,
]) {
  final gap = gapFraction.clamp(0.0, 0.08);

  ({List<LayoutCell> current, double cursor, bool pendingBreak, List<_Row> rows})
  flush({
    required List<LayoutCell> current,
    required double cursor,
    required bool pendingBreak,
    required List<_Row> rows,
  }) {
    if (current.isEmpty) {
      return (
        current: current,
        cursor: cursor,
        pendingBreak: pendingBreak,
        rows: rows,
      );
    }
    return (
      current: const [],
      cursor: 0.0,
      pendingBreak: false,
      rows: [...rows, _Row(cells: current, pageBreakBefore: pendingBreak)],
    );
  }

  final flowBlocks = blocks.where((b) => !b.floatingImage);

  final result = flowBlocks
      .fold<
        ({
          List<LayoutCell> current,
          double cursor,
          bool pendingBreak,
          List<_Row> rows,
        })
      >(
        (current: const [], cursor: 0.0, pendingBreak: false, rows: const []),
        (acc, block) {
          var s = acc;
          if (block.pageBreakBefore && s.current.isNotEmpty) {
            s = flush(
              current: s.current,
              cursor: s.cursor,
              pendingBreak: s.pendingBreak,
              rows: s.rows,
            );
          }
          if (block.pageBreakBefore && s.current.isEmpty) {
            s = (
              current: s.current,
              cursor: s.cursor,
              pendingBreak: true,
              rows: s.rows,
            );
          }
          if (block.columnBreakBefore && s.current.isNotEmpty) {
            s = flush(
              current: s.current,
              cursor: s.cursor,
              pendingBreak: s.pendingBreak,
              rows: s.rows,
            );
          }
          final width = estimateBlockWidthFraction(block, contentWidthMm);
          if (s.current.isNotEmpty && s.cursor + width > 1.0) {
            s = flush(
              current: s.current,
              cursor: s.cursor,
              pendingBreak: s.pendingBreak,
              rows: s.rows,
            );
          }
          final clampedWidth =
              width.clamp(0.08, (1.0 - s.cursor).clamp(0.08, 1.0));
          return (
            current: [
              ...s.current,
              LayoutCell(
                block: block,
                leftFraction: s.cursor,
                widthFraction: clampedWidth,
              ),
            ],
            cursor: s.cursor + width + gap,
            pendingBreak: s.pendingBreak,
            rows: s.rows,
          );
        },
      );

  final finalFlushed = flush(
    current: result.current,
    cursor: result.cursor,
    pendingBreak: result.pendingBreak,
    rows: result.rows,
  );
  return finalFlushed.rows;
}

List<PageLayout> paginateBlocks(
  List<TextBlock> blocks,
  int colCount, [
  int maxRows = 4,
  double gapFraction = 0.01,
  double? contentWidthMm,
]) {
  final rowsPerPage = maxRows < 1 ? 1 : maxRows;
  final effectiveColCount = colCount < 1 ? 8 : colCount;

  if (blocks.isEmpty) {
    return [PageLayout(colCount: effectiveColCount, flowRows: [])];
  }

  final rows = _buildRows(blocks, gapFraction, contentWidthMm);
  final pages = <PageLayout>[];
  var current = <_Row>[];

  void pushPage() {
    if (current.isEmpty) return;
    pages.add(
      PageLayout(
        colCount: effectiveColCount,
        flowRows: current.map((row) => row.cells).toList(),
      ),
    );
    current = [];
  }

  for (final row in rows) {
    if (row.pageBreakBefore && current.isNotEmpty) {
      pushPage();
    }
    current.add(row);
    if (current.length >= rowsPerPage) {
      pushPage();
    }
  }

  if (current.isNotEmpty) pushPage();

  // Assign floating images to pages
  final floatImages = blocks.where((b) => b.floatingImage).toList();
  if (floatImages.isNotEmpty && pages.isNotEmpty) {
    for (final fi in floatImages) {
      final fiIdx = blocks.indexOf(fi);
      var nonFloatingSeen = 0;
      var assignedPage = 0;
      for (var pi = 0; pi < pages.length; pi++) {
        final pageBlockCount = pages[pi].flowRows.expand((r) => r).length;
        if (fiIdx <= nonFloatingSeen + pageBlockCount) {
          assignedPage = pi;
          break;
        }
        nonFloatingSeen += pageBlockCount;
        assignedPage = pi;
      }
      final clamped = assignedPage.clamp(0, pages.length - 1);
      final p = pages[clamped];
      pages[clamped] = PageLayout(
        colCount: p.colCount,
        flowRows: p.flowRows,
        floatingImages: [...p.floatingImages, fi],
      );
    }
  }

  if (pages.isEmpty) {
    pages.add(PageLayout(colCount: effectiveColCount, flowRows: []));
  }
  return pages;
}

sealed class BlockWidthEstimate {
  const BlockWidthEstimate();
  factory BlockWidthEstimate.from(TextBlock block) {
    if (block.isImageBlock) return ImageWidth(block.imageWidthMm);
    final manual = block.columnSpan;
    if (manual != null) return ManualWidth(manual);
    if (block.isOpeningMark) return const OpeningMarkWidth();
    return TextWidth(
      tibetanLen: splitLines(block.tibetan).join('').runes.length,
      pronLen: block.isFreeText
          ? 0
          : splitLines(block.chinesePronunciation).join('').runes.length,
      transLen: block.isFreeText
          ? 0
          : splitLines(block.chineseTranslation).join('').runes.length,
    );
  }
  double fraction([double? contentWidthMm]);
}

final class ImageWidth extends BlockWidthEstimate {
  final double? widthMm;
  const ImageWidth(this.widthMm);
  @override
  double fraction([double? contentWidthMm]) {
    if (widthMm != null && contentWidthMm != null && contentWidthMm > 0) {
      return (widthMm! / contentWidthMm).clamp(0.05, 1.0);
    }
    return 0.45;
  }
}

final class ManualWidth extends BlockWidthEstimate {
  final int span;
  const ManualWidth(this.span);
  @override
  double fraction([double? contentWidthMm]) =>
      span.clamp(1, maxColumnSpan) / maxColumnSpan;
}

final class OpeningMarkWidth extends BlockWidthEstimate {
  const OpeningMarkWidth();
  @override
  double fraction([double? contentWidthMm]) => 2.0 / maxColumnSpan;
}

final class TextWidth extends BlockWidthEstimate {
  final int tibetanLen;
  final int pronLen;
  final int transLen;
  const TextWidth({
    required this.tibetanLen,
    required this.pronLen,
    required this.transLen,
  });
  @override
  double fraction([double? contentWidthMm]) {
    final score = [
      tibetanLen * 1.15,
      pronLen * 0.62,
      transLen * 0.62,
    ].reduce((a, b) => a > b ? a : b);
    return (0.07 + score / 260).clamp(0.09, 0.52);
  }
}

double estimateBlockWidthFraction(TextBlock block, [double? contentWidthMm]) =>
    BlockWidthEstimate.from(block).fraction(contentWidthMm);

double contentTibetanLineHeight({required bool smallText}) {
  return 1.0;
}

double contentTibetanFontSize(
  double fontSize, {
  required bool smallText,
  double? smallBlockFontSize,
}) {
  if (!smallText) return fontSize;
  return smallBlockFontSize ?? fontSize * 0.75;
}

double contentTibetanRasterBleed(double fontSize) {
  return fontSize * 0.5;
}

double contentTibetanBottomBleed(double fontSize) {
  return fontSize * 0.2;
}

const double contentTibetanPngTopPadding = 5 * 72 / 96;
const double contentChineseLineHeight = 1.4;

bool shouldUseShortRow(
  List<LayoutCell> row, {
  double? availableHeight,
  double? minimumHeight,
}) {
  if (row.isEmpty) return false;

  var hasSmallBlock = false;
  for (final cell in row) {
    final block = cell.block;
    if (!block.smallText && !block.isFreeText) return false;
    hasSmallBlock = true;

    if (block.isFreeText) {
      if (splitLines(block.tibetan).length > 1) return false;
      continue;
    }

    if (splitLines(block.tibetan).length > 1) return false;
    if (splitLines(block.chinesePronunciation).length > 1) return false;
  }

  if (availableHeight != null &&
      minimumHeight != null &&
      availableHeight < minimumHeight) {
    return false;
  }

  return hasSmallBlock;
}

double estimateCompactSmallRowHeight(
  List<LayoutCell> row, {
  required double tibetanFontSize,
  required double chineseFontSize,
  double topPadding = 0,
  double tibetanLineHeight = 1.2,
  double chineseLineHeight = contentChineseLineHeight,
}) {
  var maxHeight = 0.0;

  for (final cell in row) {
    final block = cell.block;
    var height = topPadding;

    if (block.isFreeText) {
      if (splitLines(block.tibetan).isNotEmpty) {
        height += chineseFontSize * chineseLineHeight;
      }
      if (height > maxHeight) maxHeight = height;
      continue;
    }

    if (splitLines(block.tibetan).isNotEmpty) {
      height += tibetanFontSize * tibetanLineHeight;
    }
    if (splitLines(block.chinesePronunciation).isNotEmpty) {
      height += 2 + chineseFontSize * chineseLineHeight;
    }

    if (height > maxHeight) maxHeight = height;
  }

  return maxHeight;
}

List<double> resolveContentRowHeights(
  List<List<LayoutCell>> rows, {
  required double contentHeight,
  required List<double> compactMinimumHeights,
}) {
  if (rows.isEmpty) return const [];

  final baseHeight = contentHeight / rows.length;
  final rowHeights = List<double>.filled(rows.length, baseHeight);
  final compactRows = <int>[];

  for (var index = 0; index < rows.length; index++) {
    final minimumHeight = compactMinimumHeights[index];
    if (shouldUseShortRow(
      rows[index],
      availableHeight: baseHeight,
      minimumHeight: minimumHeight,
    )) {
      rowHeights[index] = minimumHeight;
      compactRows.add(index);
    }
  }

  if (compactRows.isEmpty || compactRows.length == rows.length) {
    return rowHeights;
  }

  final releasedHeight = compactRows.fold<double>(
    0,
    (sum, index) => sum + baseHeight - rowHeights[index],
  );
  final normalRowCount = rows.length - compactRows.length;
  final normalRowExtraHeight = releasedHeight / normalRowCount;

  for (var index = 0; index < rows.length; index++) {
    if (!compactRows.contains(index)) {
      rowHeights[index] += normalRowExtraHeight;
    }
  }

  return rowHeights;
}

List<List<TextBlock?>> _legacyRows(
  List<List<LayoutCell>> flowRows,
  int colCount,
) {
  final cols = colCount < 1 ? 1 : colCount;
  return flowRows.map((row) {
    final padded = List<TextBlock?>.filled(cols, null);
    for (var i = 0; i < row.length && i < padded.length; i++) {
      padded[i] = row[i].block;
    }
    return padded;
  }).toList();
}
