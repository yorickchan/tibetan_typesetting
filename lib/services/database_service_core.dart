import 'dart:convert';

import '../models/project.dart';

({String? where, List<Object> args}) buildProjectQuery({
  String? query,
  String? tag,
}) {
  final q = (query ?? '').trim().toLowerCase();
  final t = (tag ?? '').trim().toLowerCase();
  final whereClauses = <String>[];
  final whereArgs = <Object>[];

  if (q.isNotEmpty) {
    whereClauses.add('(LOWER(name) LIKE ? OR LOWER(tags_json) LIKE ?)');
    whereArgs.add('%$q%');
    whereArgs.add('%$q%');
  }
  if (t.isNotEmpty) {
    whereClauses.add('LOWER(tags_json) LIKE ?');
    whereArgs.add('%"$t"%');
  }

  return (
    where: whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null,
    args: whereArgs,
  );
}

List<TextBlock> normalizeImportedBlocks(
  List<TextBlock> blocks,
  String Function() generateId,
) {
  final filled = blocks
      .map((b) => b.id.isEmpty ? b.copyWith(id: generateId()) : b)
      .toList();
  return filled.isEmpty ? [TextBlock(id: generateId())] : filled;
}

Map<String, Object> projectToRow(Project project) => {
      'id': project.id,
      'name': project.name,
      'tags_json': jsonEncode(project.tags),
      'project_json': project.toJsonString(),
      'created_at': project.createdAt,
      'updated_at': project.updatedAt,
    };

ProjectListItem rowToProjectListItem(Map<String, Object?> row) {
  final tags =
      (jsonDecode(row['tags_json'] as String) as List<dynamic>).cast<String>();
  return ProjectListItem(
    id: row['id'] as String,
    name: row['name'] as String,
    tags: tags,
    updatedAt: row['updated_at'] as String,
  );
}
