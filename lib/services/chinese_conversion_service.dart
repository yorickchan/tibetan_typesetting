import 'package:pinyin/pinyin.dart';

import '../models/chinese_script.dart';
import '../models/project.dart';

typedef SaveConvertedProject = Future<Project?> Function(Project project);

class ChineseConversionService {
  const ChineseConversionService();

  ChineseScript effectiveScript(Project project) {
    if (project.chineseScript != ChineseScript.unknown) {
      return project.chineseScript;
    }

    var simplifiedEvidence = 0;
    var traditionalEvidence = 0;
    for (final text in _documentChineseText(project)) {
      for (final rune in text.runes) {
        final character = String.fromCharCode(rune);
        if (ChineseHelper.convertCharToSimplifiedChinese(character) !=
            character) {
          traditionalEvidence += 1;
        }
        if (ChineseHelper.convertCharToTraditionalChinese(character) !=
            character) {
          simplifiedEvidence += 1;
        }
      }
    }

    return traditionalEvidence > simplifiedEvidence
        ? ChineseScript.traditional
        : ChineseScript.simplified;
  }

  String convertText(String text, ChineseScript target) {
    return switch (target) {
      ChineseScript.simplified => ChineseHelper.convertToSimplifiedChinese(
        text,
      ),
      ChineseScript.traditional => ChineseHelper.convertToTraditionalChinese(
        text,
      ),
      ChineseScript.unknown => throw ArgumentError.value(
        target,
        'target',
        'A concrete Chinese script is required',
      ),
    };
  }

  Project convertProject(Project project, ChineseScript target) {
    if (target == ChineseScript.unknown) {
      throw ArgumentError.value(
        target,
        'target',
        'A concrete Chinese script is required',
      );
    }

    final convertedBlocks = project.blocks.map((block) {
      return block.copyWith(
        tibetan: block.isFreeText
            ? convertText(block.tibetan, target)
            : block.tibetan,
        chinesePronunciation: convertText(block.chinesePronunciation, target),
        chineseTranslation: convertText(block.chineseTranslation, target),
      );
    }).toList();
    final setup = project.pageSetup;
    final convertedSetup = setup.copyWith(
      titleChinese: convertText(setup.titleChinese, target),
      leftVerticalTitle: convertText(setup.leftVerticalTitle, target),
      headerCustomText: convertText(setup.headerCustomText, target),
      footerCustomText: convertText(setup.footerCustomText, target),
    );

    return project.copyWith(
      chineseScript: target,
      blocks: convertedBlocks,
      pageSetup: convertedSetup,
    );
  }

  Future<Project> convertAndSave(
    Project project,
    ChineseScript target,
    SaveConvertedProject save,
  ) async {
    final converted = convertProject(project, target);
    final saved = await save(converted);
    if (saved == null) {
      throw StateError('The converted project could not be saved');
    }
    return saved;
  }

  Iterable<String> _documentChineseText(Project project) sync* {
    for (final block in project.blocks) {
      if (block.isFreeText) yield block.tibetan;
      yield block.chinesePronunciation;
      yield block.chineseTranslation;
    }
    yield project.pageSetup.titleChinese;
    yield project.pageSetup.leftVerticalTitle;
    yield project.pageSetup.headerCustomText;
    yield project.pageSetup.footerCustomText;
  }
}
