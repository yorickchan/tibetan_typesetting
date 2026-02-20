import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/project.dart';
import '../utils/sample_layout.dart';
import 'sample_page.dart';
import 'title_page_widget.dart';

String _resolvePageNumber(String base, int index) {
  final trimmed = base.trim();
  if (trimmed.isEmpty) return '${index + 1}';
  final num = int.tryParse(trimmed);
  if (num != null) return '${num + index}';
  return trimmed;
}

/// Renders page previews at a fixed pixel size based on mm dimensions.
class SamplePagesWidget extends StatelessWidget {
  final Project project;
  final AppSettings? appSettings;
  final String? highlightBlockId;
  final bool skipTitlePage;

  const SamplePagesWidget({
    super.key,
    required this.project,
    this.appSettings,
    this.highlightBlockId,
    this.skipTitlePage = false,
  });

  @override
  Widget build(BuildContext context) {
    final setup = project.pageSetup;
    final colCount =
        (setup.columnCount > 0) ? setup.columnCount.clamp(1, 8) : 0;
    final pages = paginateBlocks(project.blocks, colCount, 4);
    final showTitlePage = setup.showTitlePage && !skipTitlePage;

    final pageWidgets = <Widget>[];

    if (showTitlePage) {
      pageWidgets.add(TitlePageWidget(
        project: project,
        appSettings: appSettings,
        pageNumber: '',
      ));
    }

    for (var index = 0; index < pages.length; index++) {
      pageWidgets.add(SamplePageWidget(
        project: project,
        appSettings: appSettings,
        rows: pages[index].rows,
        colCount: pages[index].colCount,
        highlightBlockId: highlightBlockId,
        showMark: index % 2 == 0,
        pageNumber: _resolvePageNumber(setup.pageNumber, index),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < pageWidgets.length; i++) ...[
          pageWidgets[i],
          if (i < pageWidgets.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }
}
