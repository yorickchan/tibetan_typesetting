import 'package:flutter_test/flutter_test.dart';
import 'package:tibetan_typesetting/models/chinese_script.dart';
import 'package:tibetan_typesetting/models/project.dart';
import 'package:tibetan_typesetting/services/chinese_conversion_service.dart';

void main() {
  const service = ChineseConversionService();

  Project project({
    ChineseScript chineseScript = ChineseScript.unknown,
    List<TextBlock>? blocks,
    PageSetup? pageSetup,
  }) {
    return Project(
      id: 'project-1',
      name: '漢字 project name',
      tags: const ['漢字 tag'],
      chineseScript: chineseScript,
      blocks: blocks,
      pageSetup: pageSetup,
      updatedAt: '2026-06-28T00:00:00Z',
      createdAt: '2026-06-28T00:00:00Z',
    );
  }

  test('converts Chinese text in both directions with phrase handling', () {
    expect(
      service.convertText('理发发展', ChineseScript.traditional),
      '理髮發展',
    );
    expect(
      service.convertText('理髮發展', ChineseScript.simplified),
      '理发发展',
    );
  });

  test(
    'detects dominant script and defaults ties or empty text to simplified',
    () {
      expect(
        service.effectiveScript(
          project(
            blocks: const [TextBlock(id: '1', chineseTranslation: '漢語學習')],
          ),
        ),
        ChineseScript.traditional,
      );
      expect(
        service.effectiveScript(
          project(
            blocks: const [TextBlock(id: '1', chineseTranslation: '汉语学习')],
          ),
        ),
        ChineseScript.simplified,
      );
      expect(
        service.effectiveScript(
          project(
            blocks: const [TextBlock(id: '1', chineseTranslation: '汉漢')],
          ),
        ),
        ChineseScript.simplified,
      );
      expect(service.effectiveScript(project()), ChineseScript.simplified);
    },
  );

  test('stored script takes precedence over detection', () {
    expect(
      service.effectiveScript(
        project(
          chineseScript: ChineseScript.traditional,
          blocks: const [TextBlock(id: '1', chineseTranslation: '汉语')],
        ),
      ),
      ChineseScript.traditional,
    );
  });

  test('converts only document Chinese fields without mutating the source', () {
    final original = project(
      blocks: const [
        TextBlock(
          id: 'normal',
          tibetan: '漢字藏文欄',
          chinesePronunciation: '漢字讀音',
          chineseTranslation: '漢字翻譯',
        ),
        TextBlock(
          id: 'free',
          tibetan: '漢字自由文字',
          format: TextBlockFormat.freeText,
        ),
      ],
      pageSetup: PageSetup(
        titleTibetan: '漢字藏文標題',
        titleChinese: '漢字標題',
        leftVerticalTitle: '漢字側題',
        headerCustomText: '漢字頁眉',
        footerCustomText: '漢字頁腳',
      ),
    );

    final converted = service.convertProject(
      original,
      ChineseScript.simplified,
    );

    expect(converted.chineseScript, ChineseScript.simplified);
    expect(converted.name, '漢字 project name');
    expect(converted.tags, const ['漢字 tag']);
    expect(converted.blocks[0].tibetan, '漢字藏文欄');
    expect(converted.blocks[0].chinesePronunciation, '汉字读音');
    expect(converted.blocks[0].chineseTranslation, '汉字翻译');
    expect(converted.blocks[1].tibetan, '汉字自由文字');
    expect(converted.pageSetup.titleTibetan, '漢字藏文標題');
    expect(converted.pageSetup.titleChinese, '汉字标题');
    expect(converted.pageSetup.leftVerticalTitle, '汉字侧题');
    expect(converted.pageSetup.headerCustomText, '汉字页眉');
    expect(converted.pageSetup.footerCustomText, '汉字页脚');
    expect(original.blocks[0].chineseTranslation, '漢字翻譯');
    expect(original.pageSetup.titleChinese, '漢字標題');
  });

  test('convertAndSave returns the saved project', () async {
    Project? savedInput;
    final original = project(
      blocks: const [TextBlock(id: '1', chineseTranslation: '漢字')],
    );

    final saved = await service.convertAndSave(
      original,
      ChineseScript.simplified,
      (converted) async {
        savedInput = converted;
        return converted.copyWith(updatedAt: 'saved');
      },
    );

    expect(savedInput?.blocks.single.chineseTranslation, '汉字');
    expect(saved.updatedAt, 'saved');
  });

  test('convertAndSave fails when persistence does not update a project', () {
    final original = project();

    expect(
      () => service.convertAndSave(
        original,
        ChineseScript.traditional,
        (_) async => null,
      ),
      throwsStateError,
    );
  });
}
