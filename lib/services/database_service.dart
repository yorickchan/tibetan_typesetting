import 'dart:convert';
import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/project.dart';
import 'database_file_validator.dart';
import 'database_service_core.dart';

const _uuid = Uuid();

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal(
    databaseFactory: databaseFactory,
    defaultDatabasesPath: getDatabasesPath,
  );
  factory DatabaseService() => _instance;
  DatabaseService._internal({
    required DatabaseFactory databaseFactory,
    required Future<String> Function() defaultDatabasesPath,
  }) : _databaseFactory = databaseFactory,
       _defaultDatabasesPath = defaultDatabasesPath;

  DatabaseService.withDependencies({
    required DatabaseFactory databaseFactory,
    required Future<String> Function() defaultDatabasesPath,
  }) : _databaseFactory = databaseFactory,
       _defaultDatabasesPath = defaultDatabasesPath;

  final DatabaseFactory _databaseFactory;
  final Future<String> Function() _defaultDatabasesPath;

  Future<Database>? _dbFuture;
  String? _configuredPath;
  bool _allowCreate = true;

  void configurePath(String path, {required bool allowCreate}) {
    if (_dbFuture != null) {
      throw StateError('Database path cannot change after opening');
    }
    _configuredPath = path;
    _allowCreate = allowCreate;
  }

  Future<Database> get database async {
    final existing = _dbFuture;
    if (existing != null) return existing;
    final pending = _initDb();
    _dbFuture = pending;
    try {
      return await pending;
    } catch (_) {
      if (identical(_dbFuture, pending)) _dbFuture = null;
      rethrow;
    }
  }

  Future<Database> _initDb() async {
    final path =
        _configuredPath ??
        '${await _defaultDatabasesPath()}/tibetan_typesetting.db';
    if (!_allowCreate && !await File(path).exists()) {
      throw FileSystemException('Selected database does not exist', path);
    }
    return _databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: currentDatabaseVersion,
        onCreate: (db, version) async {
          await _createProjectsTable(db);
          await _createAppSettingsTable(db);
          await _createPronunciationDictionaryTable(db);
          await _createTitlePageTemplatesTable(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await _createAppSettingsTable(db);
          }
          if (oldVersion < 3) {
            await _createPronunciationDictionaryTable(db);
          }
          if (oldVersion < 4) {
            await db.execute(
              'ALTER TABLE pronunciation_dictionary ADD COLUMN word_count INTEGER NOT NULL DEFAULT 1',
            );
          }
          if (oldVersion < 5) {
            await _createTitlePageTemplatesTable(db);
          }
        },
      ),
    );
  }

  Future<void> _createProjectsTable(Database db) async {
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
  }

  Future<void> _createAppSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value_json TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createPronunciationDictionaryTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pronunciation_dictionary (
        tibetan_syllable TEXT PRIMARY KEY,
        chinese_pronunciation TEXT NOT NULL,
        word_count INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createTitlePageTemplatesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS title_page_templates (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        svg_content TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<List<ProjectListItem>> listProjects({
    String? query,
    String? tag,
  }) async {
    final db = await database;
    final queryResult = buildProjectQuery(query: query, tag: tag);
    final rows = await db.query(
      'projects',
      columns: ['id', 'name', 'tags_json', 'updated_at'],
      where: queryResult.where,
      whereArgs: queryResult.args.isNotEmpty ? queryResult.args : null,
      orderBy: 'updated_at DESC',
    );
    return rows.map(rowToProjectListItem).toList();
  }

  Future<Project> createProject({
    required String name,
    List<String>? tags,
    PageSetup? pageSetup,
  }) async {
    final db = await database;
    final now = nowIso();
    final projectId = _uuid.v4().replaceAll('-', '');
    final projectTags = tags ?? [];
    final project = Project(
      id: projectId,
      name: name,
      tags: projectTags,
      blocks: [TextBlock(id: _uuid.v4().replaceAll('-', ''))],
      pageSetup: pageSetup,
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
    final updated = project.copyWith(updatedAt: nowIso());
    final count = await db.update(
      'projects',
      {
        'name': updated.name,
        'tags_json': jsonEncode(updated.tags),
        'project_json': updated.toJsonString(),
        'updated_at': updated.updatedAt,
      },
      where: 'id = ?',
      whereArgs: [updated.id],
    );
    if (count == 0) return null;
    return updated;
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
    await db.transaction((txn) async {
      await txn.insert('projects', {
        'id': newProject.id,
        'name': newProject.name,
        'tags_json': jsonEncode(newProject.tags),
        'project_json': newProject.toJsonString(),
        'created_at': newProject.createdAt,
        'updated_at': newProject.updatedAt,
      });
    });

    return newProject;
  }

  Future<Project> importProject(Project project) async {
    final now = nowIso();
    String genId() => _uuid.v4().replaceAll('-', '');
    final finalImported = project.copyWith(
      id: genId(),
      createdAt: now,
      updatedAt: now,
      blocks: normalizeImportedBlocks(project.blocks, genId),
    );

    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('projects', projectToRow(finalImported));
    });

    return finalImported;
  }
}
