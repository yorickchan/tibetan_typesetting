import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/app_settings.dart';
import '../models/font_config.dart';
import '../models/project.dart';
import '../utils/colors.dart';
import '../utils/font_utils.dart' as font_utils;
import 'sample_page.dart' show kMmToPx;

const _fallbackTibetan =
    FontConfig(fontFamily: 'BabelStoneTibetan', fontPath: '', fontSize: 10);
const _fallbackChinese =
    FontConfig(fontFamily: 'STHeiti', fontPath: '', fontSize: 8);

class TitlePageWidget extends StatelessWidget {
  final Project project;
  final AppSettings? appSettings;
  final String? pageNumber;

  const TitlePageWidget({
    super.key,
    required this.project,
    this.appSettings,
    this.pageNumber,
  });

  @override
  Widget build(BuildContext context) {
    final setup = project.pageSetup;
    final titleTibetan = setup.titleTibetan.trim();
    final titleChinese =
        (setup.titleChinese.isNotEmpty ? setup.titleChinese : project.name)
            .trim();

    final pageW = setup.pageWidthMm * kMmToPx;
    final pageH = setup.pageHeightMm * kMmToPx;

    final tibFont = font_utils.effectiveFont(
        setup.tibetanFont, appSettings?.tibetanFont, _fallbackTibetan);
    final transFont = font_utils.effectiveFont(
        setup.translationFont, appSettings?.translationFont, _fallbackChinese);

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
            child: Stack(
              children: [
                if (setup.showFrame)
                  Positioned.fill(
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: setup.showFrame
                              ? AppColors.rose600
                              : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _CrestPanel(),
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            child: _TitleBox(
                              titleTibetan: titleTibetan,
                              titleChinese: titleChinese,
                              tibetanFontFamily: tibFont.fontFamily,
                              chineseFontFamily: transFont.fontFamily,
                            ),
                          ),
                        ),
                        _CrestPanel(),
                      ],
                    ),
                  ),
                ),
                if ((pageNumber ?? setup.pageNumber).isNotEmpty)
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: RotatedBox(
                        quarterTurns: 1,
                        child: Text(
                          pageNumber ?? setup.pageNumber,
                          style: TextStyle(
                            fontFamily: transFont.fontFamily,
                            fontSize: 11,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CrestPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: AppColors.rose600, width: 1),
          right: BorderSide(color: AppColors.rose600, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Center(
        child: SvgPicture.asset(
          'assets/images/dharma_wheel.svg',
          width: 80,
          height: 80,
          colorFilter:
              const ColorFilter.mode(AppColors.rose600, BlendMode.srcIn),
        ),
      ),
    );
  }
}

class _TitleBox extends StatelessWidget {
  final String titleTibetan;
  final String titleChinese;
  final String tibetanFontFamily;
  final String chineseFontFamily;

  const _TitleBox({
    required this.titleTibetan,
    required this.titleChinese,
    required this.tibetanFontFamily,
    required this.chineseFontFamily,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.rose600, width: 4),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.rose600, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              titleTibetan.isEmpty ? ' ' : titleTibetan,
              style: TextStyle(
                fontFamily: tibetanFontFamily,
                fontSize: 18,
                color: Colors.black87,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              titleChinese.isEmpty ? ' ' : titleChinese,
              style: TextStyle(
                fontFamily: chineseFontFamily,
                fontSize: 13,
                color: Colors.black87,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
