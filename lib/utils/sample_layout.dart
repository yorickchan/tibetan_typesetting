import '../models/project.dart';

String resolvePageNumber(String base, int index) {
  final trimmed = base.trim();
  if (trimmed.isEmpty) return '${index + 1}';
  final num = int.tryParse(trimmed);
  if (num != null) return '${num + index}';
  return trimmed;
}

List<String> splitLines(String s) {
  return s
      .split(RegExp(r'\r?\n'))
      .map((x) => x.trim())
      .where((x) => x.isNotEmpty)
      .toList();
}

class _Row {
  final List<TextBlock> items;
  final bool pageBreakBefore;
  _Row({required this.items, required this.pageBreakBefore});
}

class PageLayout {
  final int colCount;
  final List<List<TextBlock?>> rows;
  PageLayout({required this.colCount, required this.rows});
}

List<_Row> _buildRows(List<TextBlock> blocks, int colCount) {
  final rows = <_Row>[];
  var current = <TextBlock>[];
  var pendingPageBreak = false;

  void pushRow() {
    if (current.isEmpty) return;
    rows.add(_Row(items: current, pageBreakBefore: pendingPageBreak));
    current = [];
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
    if (colCount > 0 && current.length >= colCount) {
      pushRow();
    }
    current.add(block);
  }

  pushRow();
  return rows;
}

List<List<TextBlock?>> blocksToRows(List<TextBlock> blocks, int colCount) {
  final cols = colCount < 1 ? 1 : colCount;
  return _buildRows(blocks, colCount).map((row) {
    final padded = List<TextBlock?>.from(row.items);
    while (padded.length < cols) {
      padded.add(null);
    }
    return padded;
  }).toList();
}

List<PageLayout> paginateBlocks(
  List<TextBlock> blocks,
  int colCount, [
  int maxRows = 4,
]) {
  final rowsPerPage = maxRows < 1 ? 1 : maxRows;

  if (blocks.isEmpty) {
    return [PageLayout(colCount: colCount < 1 ? 1 : colCount, rows: [])];
  }

  final rows = _buildRows(blocks, colCount);
  final pages = <PageLayout>[];
  var current = <_Row>[];

  void pushPage() {
    if (current.isEmpty) return;
    final pageColCount = colCount > 0
        ? (colCount < 1 ? 1 : colCount)
        : current.map((r) => r.items.length).reduce((a, b) => a > b ? a : b);
    final effectiveColCount = pageColCount < 1 ? 1 : pageColCount;

    final pageRows = current.map((row) {
      final padded = List<TextBlock?>.from(row.items);
      while (padded.length < effectiveColCount) {
        padded.add(null);
      }
      return padded;
    }).toList();

    pages.add(PageLayout(colCount: effectiveColCount, rows: pageRows));
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
    pages.add(PageLayout(colCount: colCount < 1 ? 1 : colCount, rows: []));
  }
  return pages;
}
