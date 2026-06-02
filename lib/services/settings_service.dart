import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../models/app_settings.dart';
import 'database_service.dart';

const _settingsKey = 'app_settings_v1';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  final _db = DatabaseService();
  AppSettings? _cached;

  Future<AppSettings> getSettings() async {
    if (_cached != null) return _cached!;
    final db = await _db.database;
    final rows = await db.query(
      'app_settings',
      columns: ['value_json'],
      where: 'key = ?',
      whereArgs: [_settingsKey],
    );
    if (rows.isEmpty) {
      _cached = AppSettings();
      return _cached!;
    }
    try {
      _cached =
          AppSettings.fromJsonString(rows.first['value_json'] as String);
    } catch (e) {
      debugPrint('Failed to parse app settings, using defaults: $e');
      _cached = const AppSettings();
    }
    return _cached!;
  }

  Future<void> updateSettings(AppSettings settings) async {
    final db = await _db.database;
    final json = settings.toJsonString();
    await db.insert(
      'app_settings',
      {'key': _settingsKey, 'value_json': json},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _cached = settings;
  }

  void invalidateCache() => _cached = null;
}
