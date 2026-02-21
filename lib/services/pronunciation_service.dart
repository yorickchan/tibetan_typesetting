import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../models/pronunciation_entry.dart';
import 'database_service.dart';

class PronunciationService {
  static final PronunciationService _instance =
      PronunciationService._internal();
  factory PronunciationService() => _instance;
  PronunciationService._internal();

  final _db = DatabaseService();

  Future<String?> getPronunciation(String tibetanSyllable) async {
    final db = await _db.database;
    final rows = await db.query(
      'pronunciation_dictionary',
      columns: ['chinese_pronunciation'],
      where: 'tibetan_syllable = ?',
      whereArgs: [tibetanSyllable],
    );
    if (rows.isEmpty) return null;
    return rows.first['chinese_pronunciation'] as String;
  }

  Future<int?> getWordCount(String tibetanSyllable) async {
    final db = await _db.database;
    final rows = await db.query(
      'pronunciation_dictionary',
      columns: ['word_count'],
      where: 'tibetan_syllable = ?',
      whereArgs: [tibetanSyllable],
    );
    if (rows.isEmpty) return null;
    return (rows.first['word_count'] as int?) ?? 1;
  }

  Future<void> savePronunciation(
    String tibetanSyllable,
    String chinesePronunciation, {
    int wordCount = 1,
  }) async {
    if (tibetanSyllable.trim().isEmpty || chinesePronunciation.trim().isEmpty) {
      return;
    }
    final db = await _db.database;
    final now = DateTime.now().toUtc().toIso8601String().replaceAll(
      RegExp(r'\.\d+'),
      '',
    );
    await db.insert('pronunciation_dictionary', {
      'tibetan_syllable': tibetanSyllable.trim(),
      'chinese_pronunciation': chinesePronunciation.trim(),
      'word_count': wordCount.clamp(1, 10),
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updatePronunciation(
    String tibetanSyllable,
    String chinesePronunciation, {
    int? wordCount,
  }) async {
    if (tibetanSyllable.trim().isEmpty || chinesePronunciation.trim().isEmpty) {
      return;
    }
    final db = await _db.database;
    final now = DateTime.now().toUtc().toIso8601String().replaceAll(
      RegExp(r'\.\d+'),
      '',
    );
    final updates = <String, dynamic>{
      'chinese_pronunciation': chinesePronunciation.trim(),
      'updated_at': now,
    };
    if (wordCount != null) {
      updates['word_count'] = wordCount.clamp(1, 10);
    }
    await db.update(
      'pronunciation_dictionary',
      updates,
      where: 'tibetan_syllable = ?',
      whereArgs: [tibetanSyllable.trim()],
    );
  }

  Future<List<PronunciationEntry>> getAllEntries() async {
    final db = await _db.database;
    final rows = await db.query(
      'pronunciation_dictionary',
      orderBy: 'updated_at DESC',
    );
    return rows
        .map(
          (row) => PronunciationEntry(
            tibetanSyllable: row['tibetan_syllable'] as String,
            chinesePronunciation: row['chinese_pronunciation'] as String,
            wordCount: (row['word_count'] as int?) ?? 1,
            createdAt: row['created_at'] as String? ?? '',
            updatedAt: row['updated_at'] as String? ?? '',
          ),
        )
        .toList();
  }

  Future<void> deleteEntry(String tibetanSyllable) async {
    final db = await _db.database;
    await db.delete(
      'pronunciation_dictionary',
      where: 'tibetan_syllable = ?',
      whereArgs: [tibetanSyllable],
    );
  }

  Future<String> exportToJson() async {
    final entries = await getAllEntries();
    final data = entries
        .map(
          (e) => {
            'tibetanSyllable': e.tibetanSyllable,
            'chinesePronunciation': e.chinesePronunciation,
            'wordCount': e.wordCount,
          },
        )
        .toList();
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<int> importFromJson(String jsonStr, {bool overwrite = false}) async {
    final List<dynamic> data = jsonDecode(jsonStr) as List<dynamic>;
    int imported = 0;
    for (final item in data) {
      final map = item as Map<String, dynamic>;
      final syllable = map['tibetanSyllable'] as String?;
      final pronunciation = map['chinesePronunciation'] as String?;
      final wordCount = (map['wordCount'] as int?) ?? 1;
      if (syllable == null || pronunciation == null) continue;
      if (syllable.trim().isEmpty || pronunciation.trim().isEmpty) continue;

      if (!overwrite) {
        final existing = await getPronunciation(syllable);
        if (existing != null) continue;
      }
      await savePronunciation(syllable, pronunciation, wordCount: wordCount);
      imported++;
    }
    return imported;
  }
}
