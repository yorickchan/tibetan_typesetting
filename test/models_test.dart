import 'package:flutter_test/flutter_test.dart';
import 'package:tibetan_typesetting/models/project.dart';

void main() {
  group('MarginMm', () {
    test('copyWith preserves unchanged fields', () {
      final original = MarginMm(top: 10, right: 20, bottom: 30, left: 40);
      final copy = original.copyWith(top: 15);
      
      expect(copy.top, 15);
      expect(copy.right, 20);
      expect(copy.bottom, 30);
      expect(copy.left, 40);
    });

    test('serialization round-trip', () {
      final original = MarginMm(top: 10, right: 20, bottom: 30, left: 40);
      final json = original.toJson();
      final restored = MarginMm.fromJson(json);
      
      expect(restored.top, original.top);
      expect(restored.right, original.right);
      expect(restored.bottom, original.bottom);
      expect(restored.left, original.left);
    });
  });

  group('TextBlock', () {
    test('copyWith preserves unchanged fields', () {
      final original = TextBlock(
        id: 'test-id',
        tibetan: 'བོད་སྐད',
        chinesePronunciation: 'bod skad',
        chineseTranslation: '藏语',
        pageBreakBefore: true,
        columnBreakBefore: false,
        smallText: true,
        format: TextBlockFormat.normal,
        columnSpan: 2,
      );
      
      final copy = original.copyWith(tibetan: 'བོད་ཡིག');
      
      expect(copy.id, original.id);
      expect(copy.tibetan, 'བོད་ཡིག');
      expect(copy.chinesePronunciation, original.chinesePronunciation);
      expect(copy.chineseTranslation, original.chineseTranslation);
      expect(copy.pageBreakBefore, original.pageBreakBefore);
      expect(copy.columnBreakBefore, original.columnBreakBefore);
      expect(copy.smallText, original.smallText);
      expect(copy.format, original.format);
      expect(copy.columnSpan, original.columnSpan);
    });

    test('copyWith with clearColumnSpan', () {
      final original = TextBlock(id: 'test', columnSpan: 2);
      final copy = original.copyWith(clearColumnSpan: true);
      
      expect(copy.columnSpan, null);
    });

    test('serialization round-trip', () {
      final original = TextBlock(
        id: 'test-id',
        tibetan: 'བོད་སྐད',
        chinesePronunciation: 'bod skad',
        chineseTranslation: '藏语',
        pageBreakBefore: true,
        columnBreakBefore: false,
        smallText: true,
        format: TextBlockFormat.freeText,
        columnSpan: 2,
      );
      
      final json = original.toJson();
      final restored = TextBlock.fromJson(json);
      
      expect(restored.id, original.id);
      expect(restored.tibetan, original.tibetan);
      expect(restored.chinesePronunciation, original.chinesePronunciation);
      expect(restored.chineseTranslation, original.chineseTranslation);
      expect(restored.pageBreakBefore, original.pageBreakBefore);
      expect(restored.columnBreakBefore, original.columnBreakBefore);
      expect(restored.smallText, original.smallText);
      expect(restored.format, original.format);
      expect(restored.columnSpan, original.columnSpan);
    });
  });

  group('PageSetup', () {
    test('copyWith preserves unchanged fields', () {
      final original = PageSetup(
        pageWidthMm: 300,
        pageHeightMm: 120,
        columnCount: 5,
        showFrame: true,
      );
      
      final copy = original.copyWith(pageWidthMm: 350);
      
      expect(copy.pageWidthMm, 350);
      expect(copy.pageHeightMm, original.pageHeightMm);
      expect(copy.columnCount, original.columnCount);
      expect(copy.showFrame, original.showFrame);
    });

    test('serialization round-trip', () {
      final original = PageSetup(
        pageWidthMm: 300,
        pageHeightMm: 120,
        columnCount: 5,
        showFrame: true,
        leftVerticalTitle: 'Test',
        pageNumber: '1',
        flowGap: 0.02,
      );
      
      final json = original.toJson();
      final restored = PageSetup.fromJson(json);
      
      expect(restored.pageWidthMm, original.pageWidthMm);
      expect(restored.pageHeightMm, original.pageHeightMm);
      expect(restored.columnCount, original.columnCount);
      expect(restored.showFrame, original.showFrame);
      expect(restored.leftVerticalTitle, original.leftVerticalTitle);
      expect(restored.pageNumber, original.pageNumber);
      expect(restored.flowGap, original.flowGap);
    });
  });

  group('Project', () {
    test('copyWith preserves unchanged fields', () {
      final original = Project(
        id: 'test-id',
        name: 'Test Project',
        tags: ['tag1', 'tag2'],
        blocks: [TextBlock(id: 'block1')],
        updatedAt: '2026-01-01T00:00:00Z',
        createdAt: '2026-01-01T00:00:00Z',
      );
      
      final copy = original.copyWith(name: 'Updated Name');
      
      expect(copy.id, original.id);
      expect(copy.name, 'Updated Name');
      expect(copy.tags, original.tags);
      expect(copy.blocks.length, original.blocks.length);
      expect(copy.updatedAt, original.updatedAt);
      expect(copy.createdAt, original.createdAt);
    });

    test('serialization round-trip', () {
      final original = Project(
        id: 'test-id',
        name: 'Test Project',
        tags: ['tag1', 'tag2'],
        blocks: [
          TextBlock(id: 'block1', tibetan: 'བོད་སྐད'),
          TextBlock(id: 'block2', tibetan: 'བོད་ཡིག'),
        ],
        updatedAt: '2026-01-01T00:00:00Z',
        createdAt: '2026-01-01T00:00:00Z',
      );
      
      final jsonStr = original.toJsonString();
      final restored = Project.fromJsonString(jsonStr);
      
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.tags, original.tags);
      expect(restored.blocks.length, original.blocks.length);
      expect(restored.blocks[0].tibetan, original.blocks[0].tibetan);
      expect(restored.blocks[1].tibetan, original.blocks[1].tibetan);
      expect(restored.updatedAt, original.updatedAt);
      expect(restored.createdAt, original.createdAt);
    });
  });
}
