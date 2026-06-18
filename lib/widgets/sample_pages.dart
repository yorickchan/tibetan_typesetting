import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/project.dart';
import '../utils/sample_layout.dart';
import 'sample_page.dart';
import 'title_page_widget.dart';

/// Renders page previews at a fixed pixel size based on mm dimensions.
class SamplePagesWidget extends StatelessWidget {
  final Project project;
  final AppSettings? appSettings;
  final String? highlightBlockId;
  final bool skipTitlePage;
  final String? svgContent;

  const SamplePagesWidget({
    super.key,
    required this.project,
    this.appSettings,
    this.highlightBlockId,
    this.skipTitlePage = false,
    this.svgContent,
  });

  @override
  Widget build(BuildContext context) {
    final setup = project.pageSetup;
    final pages = paginateBlocks(
      project.blocks,
      0,
      4,
      setup.flowGap,
      setup.pageWidthMm - setup.marginMm.left - setup.marginMm.right,
    );
    final showTitlePage = setup.showTitlePage && !skipTitlePage;

    final pageWidgets = <Widget>[];

    if (showTitlePage) {
      pageWidgets.add(
        TitlePageWidget(
          project: project,
          appSettings: appSettings,
          pageNumber: '',
          svgContent: svgContent,
        ),
      );
    }

    for (var index = 0; index < pages.length; index++) {
      pageWidgets.add(
        SamplePageWidget(
          project: project,
          appSettings: appSettings,
          rows: pages[index].rows,
          flowRows: pages[index].flowRows,
          colCount: pages[index].colCount,
          highlightBlockId: highlightBlockId,
          pageNumber: resolvePageNumber(setup.pageNumber, index),
          floatingImages: pages[index].floatingImages,
        ),
      );
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
