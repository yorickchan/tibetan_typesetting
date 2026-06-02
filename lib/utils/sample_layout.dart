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

  PageLayout({required this.colCount, required this.flowRows})
    : rows = _legacyRows(flowRows, colCount);
}

List<_Row> _buildRows(List<TextBlock> blocks, double gapFraction) {
  final rows = <_Row>[];
  final gap = gapFraction.clamp(0.0, 0.08);
  var current = <LayoutCell>[];
  var cursor = 0.0;
  var pendingPageBreak = false;

  void pushRow() {
    if (current.isEmpty) return;
    rows.add(_Row(cells: current, pageBreakBefore: pendingPageBreak));
    current = [];
    cursor = 0;
    pendingPageBreak = false;
  }

  for (final block in blocks) {
    if (block.pageBreakBefore && current.isNotEmpty) {
      pushRow();
    }
    if (block.pageBreakBefore && current.isEmpty) {
      pendingPageBreak = true;
    }
    if (block.columnBreakBefore && current.isNotEmpty) {
      pushRow();
    }

    final width = estimateBlockWidthFraction(block);
    if (current.isNotEmpty && cursor + width > 1.0) {
      pushRow();
    }

    current.add(
      LayoutCell(
        block: block,
        leftFraction: cursor,
        widthFraction: width.clamp(0.08, 1.0 - cursor),
      ),
    );
    cursor += width + gap;
  }

  pushRow();
  return rows;
}

List<PageLayout> paginateBlocks(
  List<TextBlock> blocks,
  int colCount, [
  int maxRows = 4,
  double gapFraction = 0.01,
]) {
  final rowsPerPage = maxRows < 1 ? 1 : maxRows;
  final effectiveColCount = colCount < 1 ? 8 : colCount;

  if (blocks.isEmpty) {
    return [PageLayout(colCount: effectiveColCount, flowRows: [])];
  }

  final rows = _buildRows(blocks, gapFraction);
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
  if (pages.isEmpty) {
    pages.add(PageLayout(colCount: effectiveColCount, flowRows: []));
  }
  return pages;
}

double estimateBlockWidthFraction(TextBlock block) {
  final manual = block.columnSpan;
  if (manual != null) {
    return manual.clamp(1, maxColumnSpan) / maxColumnSpan;
  }

  final tibetanLen = splitLines(block.tibetan).join('').runes.length;
  final pronLen = block.isFreeText
      ? 0
      : splitLines(block.chinesePronunciation).join('').runes.length;
  final transLen = block.isFreeText
      ? 0
      : splitLines(block.chineseTranslation).join('').runes.length;
  final score = [
    tibetanLen * 1.15,
    pronLen * 0.62,
    transLen * 0.62,
  ].reduce((a, b) => a > b ? a : b);

  return (0.07 + score / 260).clamp(0.09, 0.52);
}

double contentTibetanLineHeight({required bool smallText}) {
  return smallText ? 1.2 : 0.75;
}

double contentTibetanFontSize(double fontSize, {required bool smallText}) {
  return fontSize * (smallText ? 0.75 : 1.0);
}

double contentOpeningMarkIndent(double fontSize) {
  return fontSize * 2.5;
}

double contentTibetanRasterBleed(double fontSize) {
  return fontSize * 0.5;
}

double contentTibetanBottomBleed(double fontSize) {
  return fontSize * 0.2;
}

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

    if (splitLines(block.chineseTranslation).join('').isNotEmpty) {
      return false;
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
  double chineseLineHeight = 1.0,
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
