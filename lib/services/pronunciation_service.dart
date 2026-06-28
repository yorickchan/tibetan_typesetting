import 'dart:convert';

import 'app_database.dart';

import '../models/pronunciation_entry.dart';
import '../models/project.dart' show nowIso;
import 'database_service.dart';

class _ImportEntry {
  final String syllable;
  final String pronunciation;
  final int wordCount;
  _ImportEntry(this.syllable, this.pronunciation, this.wordCount);
}

class PronunciationService {
  static final PronunciationService _instance =
      PronunciationService._internal();
  factory PronunciationService() => _instance;
  PronunciationService._internal();

  static final RegExp _savablePronunciationChar = RegExp(
    r'[\p{L}\p{N}]',
    unicode: true,
  );

  final _db = DatabaseService();

  static bool isSavablePronunciation(String value) {
    return _savablePronunciationChar.hasMatch(value.trim());
  }

  static List<String> savablePronunciationCharacters(String value) {
    return value.runes
        .map(String.fromCharCode)
        .where((c) => _savablePronunciationChar.hasMatch(c))
        .toList();
  }

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

  Future<List<String>> checkSpelling(String tibetanText) async {
    final db = await _db.database;
    final tibetanRegex = RegExp(r'[\u0F00-\u0FFF]+');
    final matches = tibetanRegex.allMatches(tibetanText);
    final unknown = <String>[];
    for (final match in matches) {
      final syllable = match.group(0)!;
      final rows = await db.query(
        'pronunciation_dictionary',
        columns: ['tibetan_syllable'],
        where: 'tibetan_syllable = ?',
        whereArgs: [syllable],
        limit: 1,
      );
      if (rows.isEmpty) {
        unknown.add(syllable);
      }
    }
    return unknown;
  }

  Future<bool> savePronunciation(
    String tibetanSyllable,
    String chinesePronunciation, {
    int wordCount = 1,
  }) async {
    if (tibetanSyllable.trim().isEmpty ||
        !isSavablePronunciation(chinesePronunciation)) {
      return false;
    }
    final db = await _db.database;
    final now = nowIso();
    await db.insert('pronunciation_dictionary', {
      'tibetan_syllable': tibetanSyllable.trim(),
      'chinese_pronunciation': chinesePronunciation.trim(),
      'word_count': wordCount.clamp(1, 10),
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: DbConflictAlgorithm.replace);
    return true;
  }

  Future<bool> updatePronunciation(
    String tibetanSyllable,
    String chinesePronunciation, {
    int? wordCount,
  }) async {
    if (tibetanSyllable.trim().isEmpty ||
        !isSavablePronunciation(chinesePronunciation)) {
      return false;
    }
    final db = await _db.database;
    final now = nowIso();
    final updates = <String, dynamic>{
      'chinese_pronunciation': chinesePronunciation.trim(),
      'updated_at': now,
    };
    if (wordCount != null) {
      updates['word_count'] = wordCount.clamp(1, 10);
    }
    final count = await db.update(
      'pronunciation_dictionary',
      updates,
      where: 'tibetan_syllable = ?',
      whereArgs: [tibetanSyllable.trim()],
    );
    return count > 0;
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

    // Validate and collect entries
    final entries = <_ImportEntry>[];
    for (final item in data) {
      if (item is! Map<String, dynamic>) continue;
      final syllable = (item['tibetanSyllable'] as String?)?.trim();
      final pronunciation = (item['chinesePronunciation'] as String?)?.trim();
      final wordCount = (item['wordCount'] as int?) ?? 1;
      if (syllable == null || syllable.isEmpty) continue;
      if (pronunciation == null || !isSavablePronunciation(pronunciation)) continue;
      entries.add(_ImportEntry(syllable, pronunciation, wordCount.clamp(1, 10)));
    }
    if (entries.isEmpty) return 0;

    final db = await _db.database;

    // Fetch all existing syllables in a single query
    Set<String> existingSyllables;
    if (!overwrite) {
      final syllables = entries.map((e) => e.syllable).toList();
      final placeholders = syllables.map((_) => '?').join(',');
      final rows = await db.rawQuery(
        'SELECT tibetan_syllable FROM pronunciation_dictionary WHERE tibetan_syllable IN ($placeholders)',
        syllables,
      );
      existingSyllables = rows.map((r) => r['tibetan_syllable'] as String).toSet();
    } else {
      existingSyllables = {};
    }

    // Batch insert all new entries
    final now = nowIso();
    final batch = db.batch();
    int imported = 0;
    for (final entry in entries) {
      if (!overwrite && existingSyllables.contains(entry.syllable)) continue;
      batch.insert('pronunciation_dictionary', {
        'tibetan_syllable': entry.syllable,
        'chinese_pronunciation': entry.pronunciation,
        'word_count': entry.wordCount,
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: DbConflictAlgorithm.replace);
      imported++;
    }
    await db.commitBatch(batch, noResult: true);
    return imported;
  }
}
