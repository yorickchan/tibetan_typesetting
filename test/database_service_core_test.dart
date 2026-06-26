import 'package:flutter_test/flutter_test.dart';
import 'package:tibetan_typesetting/models/project.dart';
import 'package:tibetan_typesetting/services/database_service_core.dart';

void main() {
  group('buildProjectQuery', () {
    test('empty query and tag returns null where', () {
      final result = buildProjectQuery(query: null, tag: null);
      expect(result.where, isNull);
      expect(result.args, isEmpty);
    });

    test('query adds name and tags LIKE clauses', () {
      final result = buildProjectQuery(query: 'dharma', tag: null);
      expect(result.where, contains('name'));
      expect(result.args, hasLength(2));
      expect(
        result.args.every((a) => (a as String).contains('dharma')),
        isTrue,
      );
    });

    test('tag adds tags_json LIKE clause', () {
      final result = buildProjectQuery(query: null, tag: 'sutra');
      expect(result.where, contains('tags_json'));
      expect(result.args, hasLength(1));
    });

    test('both query and tag join with AND', () {
      final result = buildProjectQuery(query: 'dharma', tag: 'sutra');
      expect(result.where, contains('AND'));
      expect(result.args, hasLength(3));
    });
  });

  group('normalizeImportedBlocks', () {
    test('fills empty ids with generated ids', () {
      final blocks = [
        TextBlock(id: '', tibetan: 'a'),
        TextBlock(id: 'existing', tibetan: 'b'),
      ];
      final result = normalizeImportedBlocks(blocks, () => 'generated-id');
      expect(result[0].id, 'generated-id');
      expect(result[1].id, 'existing');
    });

    test('empty list returns single block with generated id', () {
      final result = normalizeImportedBlocks(const [], () => 'gen');
      expect(result.length, 1);
      expect(result[0].id, 'gen');
    });
  });

  group('projectToRow', () {
    test('builds insert map with json fields', () {
      final project = Project(
        id: 'p1',
        name: 'Test',
        tags: const ['a', 'b'],
        createdAt: '2024-01-01',
        updatedAt: '2024-01-02',
        blocks: const [],
      );
      final row = projectToRow(project);
      expect(row['id'], 'p1');
      expect(row['name'], 'Test');
      expect(row['tags_json'], contains('a'));
      expect(row['created_at'], '2024-01-01');
    });
  });

  group('rowToProjectListItem', () {
    test('decodes row into ProjectListItem', () {
      final row = <String, Object?>{
        'id': 'p1',
        'name': 'Test',
        'tags_json': '["a","b"]',
        'updated_at': '2024-01-02',
      };
      final item = rowToProjectListItem(row);
      expect(item.id, 'p1');
      expect(item.name, 'Test');
      expect(item.tags, ['a', 'b']);
      expect(item.updatedAt, '2024-01-02');
    });
  });
}
