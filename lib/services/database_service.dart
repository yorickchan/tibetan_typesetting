import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/project.dart';

const _uuid = Uuid();

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/tibetan_typesetting.db';
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS projects (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            tags_json TEXT NOT NULL,
            project_json TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_projects_updated_at ON projects(updated_at)',
        );
      },
    );
  }

  Future<List<ProjectListItem>> listProjects({String? query, String? tag}) async {
    final db = await database;
    final rows = await db.query(
      'projects',
      columns: ['id', 'name', 'tags_json', 'updated_at'],
      orderBy: 'updated_at DESC',
    );

    var items = rows.map((row) {
      final tags = (jsonDecode(row['tags_json'] as String) as List<dynamic>).cast<String>();
      return ProjectListItem(
        id: row['id'] as String,
        name: row['name'] as String,
        tags: tags,
        updatedAt: row['updated_at'] as String,
      );
    }).toList();

    final q = (query ?? '').trim().toLowerCase();
    final t = (tag ?? '').trim().toLowerCase();

    if (q.isNotEmpty) {
      items = items
          .where((i) =>
              i.name.toLowerCase().contains(q) ||
              i.tags.any((x) => x.toLowerCase().contains(q)))
          .toList();
    }
    if (t.isNotEmpty) {
      items = items
          .where((i) => i.tags.any((x) => x.toLowerCase() == t))
          .toList();
    }

    return items;
  }

  Future<Project> createProject({required String name, List<String>? tags}) async {
    final db = await database;
    final now = nowIso();
    final projectId = _uuid.v4().replaceAll('-', '');
    final projectTags = tags ?? [];
    final project = Project(
      id: projectId,
      name: name,
      tags: projectTags,
      blocks: [TextBlock(id: _uuid.v4().replaceAll('-', ''))],
      updatedAt: now,
      createdAt: now,
    );

    await db.insert('projects', {
      'id': project.id,
      'name': project.name,
      'tags_json': jsonEncode(project.tags),
      'project_json': project.toJsonString(),
      'created_at': project.createdAt,
      'updated_at': project.updatedAt,
    });

    return project;
  }

  Future<Project?> getProject(String projectId) async {
    final db = await database;
    final rows = await db.query(
      'projects',
      columns: ['project_json'],
      where: 'id = ?',
      whereArgs: [projectId],
    );
    if (rows.isEmpty) return null;
    return Project.fromJsonString(rows.first['project_json'] as String);
  }

  Future<Project?> updateProject(Project project) async {
    final db = await database;
    project.updatedAt = nowIso();
    final count = await db.update(
      'projects',
      {
        'name': project.name,
        'tags_json': jsonEncode(project.tags),
        'project_json': project.toJsonString(),
        'updated_at': project.updatedAt,
      },
      where: 'id = ?',
      whereArgs: [project.id],
    );
    if (count == 0) return null;
    return project;
  }

  Future<bool> deleteProject(String projectId) async {
    final db = await database;
    final count = await db.delete(
      'projects',
      where: 'id = ?',
      whereArgs: [projectId],
    );
    return count > 0;
  }

  Future<Project> duplicateProject(String projectId) async {
    final original = await getProject(projectId);
    if (original == null) throw Exception('Project not found');

    final now = nowIso();
    final newProject = original.copyWith(
      id: _uuid.v4().replaceAll('-', ''),
      name: '${original.name} (copy)',
      createdAt: now,
      updatedAt: now,
      blocks: original.blocks
          .map((b) => b.copyWith(id: _uuid.v4().replaceAll('-', '')))
          .toList(),
    );

    final db = await database;
    await db.insert('projects', {
      'id': newProject.id,
      'name': newProject.name,
      'tags_json': jsonEncode(newProject.tags),
      'project_json': newProject.toJsonString(),
      'created_at': newProject.createdAt,
      'updated_at': newProject.updatedAt,
    });

    return newProject;
  }

  Future<Project> importProject(Project project) async {
    final now = nowIso();
    final imported = project.copyWith(
      id: _uuid.v4().replaceAll('-', ''),
      createdAt: now,
      updatedAt: now,
    );
    for (final b in imported.blocks) {
      if (b.id.isEmpty) b.id = _uuid.v4().replaceAll('-', '');
    }
    if (imported.blocks.isEmpty) {
      imported.blocks = [TextBlock(id: _uuid.v4().replaceAll('-', ''))];
    }

    final db = await database;
    await db.insert('projects', {
      'id': imported.id,
      'name': imported.name,
      'tags_json': jsonEncode(imported.tags),
      'project_json': imported.toJsonString(),
      'created_at': imported.createdAt,
      'updated_at': imported.updatedAt,
    });

    return imported;
  }
}
