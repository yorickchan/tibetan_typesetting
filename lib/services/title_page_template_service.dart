import 'package:uuid/uuid.dart';

import '../models/title_page_template.dart';
import 'database_service.dart';

const _uuid = Uuid();

class TitlePageTemplateService {
  static final TitlePageTemplateService _instance =
      TitlePageTemplateService._internal();
  factory TitlePageTemplateService() => _instance;
  TitlePageTemplateService._internal();

  final _db = DatabaseService();
  List<TitlePageTemplate>? _cached;

  Future<List<TitlePageTemplate>> listTemplates() async {
    if (_cached != null) return _cached!;
    final db = await _db.database;
    final rows = await db.query(
      'title_page_templates',
      orderBy: 'created_at DESC',
    );
    _cached = rows
        .map((r) => TitlePageTemplate(
              id: r['id'] as String,
              name: r['name'] as String,
              svgContent: r['svg_content'] as String,
            ))
        .toList();
    return _cached!;
  }

  Future<TitlePageTemplate> addTemplate(String name, String svgContent) async {
    final db = await _db.database;
    final id = _uuid.v4().replaceAll('-', '');
    final now = DateTime.now().toIso8601String();
    await db.insert('title_page_templates', {
      'id': id,
      'name': name,
      'svg_content': svgContent,
      'created_at': now,
    });
    _invalidateCache();
    final t = TitlePageTemplate(id: id, name: name, svgContent: svgContent);
    return t;
  }

  Future<void> deleteTemplate(String id) async {
    final db = await _db.database;
    await db.delete('title_page_templates', where: 'id = ?', whereArgs: [id]);
    _invalidateCache();
  }

  Future<void> renameTemplate(String id, String name) async {
    final db = await _db.database;
    await db.update(
      'title_page_templates',
      {'name': name},
      where: 'id = ?',
      whereArgs: [id],
    );
    _invalidateCache();
  }

  Future<TitlePageTemplate?> getTemplate(String id) async {
    final templates = await listTemplates();
    try {
      return templates.firstWhere((t) => t.id == id);
    } on StateError {
      return null;
    }
  }

  void _invalidateCache() => _cached = null;
}
