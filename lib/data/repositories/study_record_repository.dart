import 'package:sqflite/sqflite.dart';

import '../../core/db/app_database_runtime.dart';
import '../models/study_record.dart';

class StudyRecordRepository {
  StudyRecordRepository(this._database);

  final AppDatabase _database;

  Future<int> insertRecord(StudyRecord record) async {
    final db = await _database.database;
    return db.insert('study_records', record.toMap());
  }

  Future<void> updateRecord(StudyRecord record) async {
    final db = await _database.database;
    await db.update(
      'study_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<void> deleteRecord(int id) async {
    final db = await _database.database;
    await db.delete('study_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<StudyRecord?> getRecordById(int id) async {
    final db = await _database.database;
    final maps = await db.query(
      'study_records',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) {
      return null;
    }
    return StudyRecord.fromMap(maps.first);
  }

  Future<List<StudyRecord>> getAllRecords() async {
    final db = await _database.database;
    final maps = await db.query(
      'study_records',
      orderBy: 'occurred_at DESC, id DESC',
    );
    return maps.map(StudyRecord.fromMap).toList(growable: false);
  }

  Future<int> totalEarnedPoints() async {
    final db = await _database.database;
    final studyPoints = Sqflite.firstIntValue(
          await db.rawQuery(
            "SELECT COALESCE(SUM(points), 0) FROM study_records WHERE record_kind = 'study'",
          ),
        ) ??
        0;

    final lifeRows = await db.rawQuery('''
      SELECT
        substr(occurred_at, 1, 10) AS life_day,
        COALESCE(SUM(points), 0) AS day_points
      FROM study_records
      WHERE record_kind = 'life'
      GROUP BY life_day
    ''');

    var lifeBonusPoints = 0;
    for (final row in lifeRows) {
      final day = row['life_day'] as String?;
      if (day == null || day.isEmpty) {
        continue;
      }
      final dayPoints = (row['day_points'] as num?)?.toInt() ?? 0;
      final settings = await _getLifeRewardSettingsAt(
        db,
        effectiveAtIso: '${day}T23:59:59.999',
      );
      if (dayPoints >= settings.targetPoints) {
        lifeBonusPoints += settings.bonusPoints;
      }
    }

    return studyPoints + lifeBonusPoints;
  }

  Future<({int targetPoints, int bonusPoints})> _getLifeRewardSettings(
      Database db) async {
    final rows = await db.query(
      'app_settings',
      columns: const ['setting_key', 'setting_value'],
      where: 'setting_key IN (?, ?)',
      whereArgs: const [
        'life_daily_target_points',
        'life_daily_target_bonus_points',
      ],
    );
    var targetPoints = 10;
    var bonusPoints = 5;
    for (final row in rows) {
      final key = row['setting_key'] as String? ?? '';
      final value = int.tryParse(row['setting_value'] as String? ?? '');
      if (value == null) {
        continue;
      }
      if (key == 'life_daily_target_points' && value > 0) {
        targetPoints = value;
      } else if (key == 'life_daily_target_bonus_points' && value >= 0) {
        bonusPoints = value;
      }
    }
    return (targetPoints: targetPoints, bonusPoints: bonusPoints);
  }

  Future<({int targetPoints, int bonusPoints})> _getLifeRewardSettingsAt(
    Database db, {
    required String effectiveAtIso,
  }) async {
    final fallback = await _getLifeRewardSettings(db);
    final targetPoints = await _findLifeSettingValueFromHistory(
      db,
      settingKey: 'life_daily_target_points',
      effectiveAtIso: effectiveAtIso,
    );
    final bonusPoints = await _findLifeSettingValueFromHistory(
      db,
      settingKey: 'life_daily_target_bonus_points',
      effectiveAtIso: effectiveAtIso,
    );
    return (
      targetPoints: targetPoints ?? fallback.targetPoints,
      bonusPoints: bonusPoints ?? fallback.bonusPoints,
    );
  }

  Future<int?> _findLifeSettingValueFromHistory(
    Database db, {
    required String settingKey,
    required String effectiveAtIso,
  }) async {
    final rows = await db.query(
      'app_settings_history',
      columns: const ['setting_value'],
      where: 'setting_key = ? AND effective_at <= ?',
      whereArgs: [settingKey, effectiveAtIso],
      orderBy: 'effective_at DESC, id DESC',
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return int.tryParse(rows.first['setting_value'] as String? ?? '');
  }

  Future<List<StudyRecord>> getRecordsBetween(
      DateTime start, DateTime endExclusive,
      {String recordKind = 'study'}) async {
    final db = await _database.database;
    final maps = await db.query(
      'study_records',
      where: 'occurred_at >= ? AND occurred_at < ? AND record_kind = ?',
      whereArgs: [
        start.toIso8601String(),
        endExclusive.toIso8601String(),
        recordKind,
      ],
      orderBy: 'occurred_at DESC, id DESC',
    );
    return maps.map(StudyRecord.fromMap).toList(growable: false);
  }

  Future<List<StudyRecord>> getLifeRecordsBetween(
    DateTime start,
    DateTime endExclusive,
  ) {
    return getRecordsBetween(start, endExclusive, recordKind: 'life');
  }

  Future<Map<int, int>> getContentUsageCounts() async {
    final db = await _database.database;
    final rows = await db.rawQuery('''
      SELECT content_option_id, COUNT(*) AS usage_count
      FROM study_records
      WHERE content_option_id IS NOT NULL
        AND record_kind = 'study'
      GROUP BY content_option_id
    ''');

    return {
      for (final row in rows)
        row['content_option_id'] as int: row['usage_count'] as int,
    };
  }

  Future<int> countRecordsOnDay(
    DateTime day, {
    int? excludingRecordId,
  }) async {
    final db = await _database.database;
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final whereParts = <String>[
      'occurred_at >= ?',
      'occurred_at < ?',
      "record_kind = 'study'",
    ];
    final whereArgs = <Object?>[
      start.toIso8601String(),
      end.toIso8601String(),
    ];
    if (excludingRecordId != null) {
      whereParts.add('id != ?');
      whereArgs.add(excludingRecordId);
    }
    return Sqflite.firstIntValue(
          await db.query(
            'study_records',
            columns: const ['COUNT(*)'],
            where: whereParts.join(' AND '),
            whereArgs: whereArgs,
          ),
        ) ??
        0;
  }

  Future<int> countSessionRecordsBefore(
    DateTime anchor, {
    required int gapMinutes,
    int? excludingRecordId,
  }) async {
    final db = await _database.database;
    final whereParts = <String>['occurred_at <= ?'];
    whereParts.add("record_kind = 'study'");
    final whereArgs = <Object?>[anchor.toIso8601String()];
    if (excludingRecordId != null) {
      whereParts.add('id != ?');
      whereArgs.add(excludingRecordId);
    }

    final maps = await db.query(
      'study_records',
      columns: const ['id', 'occurred_at'],
      where: whereParts.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'occurred_at DESC, id DESC',
    );

    if (maps.isEmpty) {
      return 0;
    }

    final allowedGap = Duration(minutes: gapMinutes);
    var count = 0;
    DateTime? previous;

    for (final map in maps) {
      final occurredAt = DateTime.parse(map['occurred_at'] as String);
      if (previous == null) {
        if (anchor.difference(occurredAt) > allowedGap) {
          break;
        }
        previous = occurredAt;
        count += 1;
        continue;
      }

      if (previous.difference(occurredAt) > allowedGap) {
        break;
      }
      previous = occurredAt;
      count += 1;
    }

    return count;
  }

  Future<int> countLowPointRecordsOnDay(
    DateTime day, {
    int threshold = 2,
    int? excludingRecordId,
  }) async {
    final db = await _database.database;
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final whereParts = <String>[
      'occurred_at >= ?',
      'occurred_at < ?',
      'points < ?',
      "record_kind = 'study'",
    ];
    final whereArgs = <Object?>[
      start.toIso8601String(),
      end.toIso8601String(),
      threshold,
    ];
    if (excludingRecordId != null) {
      whereParts.add('id != ?');
      whereArgs.add(excludingRecordId);
    }
    return Sqflite.firstIntValue(
          await db.query(
            'study_records',
            columns: const ['COUNT(*)'],
            where: whereParts.join(' AND '),
            whereArgs: whereArgs,
          ),
        ) ??
        0;
  }

  Future<Map<int, int>> countLowPointRecordsByCategoryOnDay(
    DateTime day, {
    int threshold = 2,
    int? excludingRecordId,
  }) async {
    final db = await _database.database;
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final whereParts = <String>[
      'occurred_at >= ?',
      'occurred_at < ?',
      'points < ?',
      'category_id IS NOT NULL',
      "record_kind = 'study'",
    ];
    final whereArgs = <Object?>[
      start.toIso8601String(),
      end.toIso8601String(),
      threshold,
    ];
    if (excludingRecordId != null) {
      whereParts.add('id != ?');
      whereArgs.add(excludingRecordId);
    }

    final rows = await db.rawQuery(
      '''
      SELECT category_id, COUNT(*) AS record_count
      FROM study_records
      WHERE ${whereParts.join(' AND ')}
      GROUP BY category_id
      ''',
      whereArgs,
    );

    return {
      for (final row in rows)
        row['category_id'] as int: (row['record_count'] as int?) ?? 0,
    };
  }

  Future<Map<int, int>> countRecordsByPointsOnDay(
    DateTime day, {
    int? excludingRecordId,
  }) async {
    final db = await _database.database;
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final whereParts = <String>[
      'occurred_at >= ?',
      'occurred_at < ?',
      "record_kind = 'study'",
    ];
    final whereArgs = <Object?>[
      start.toIso8601String(),
      end.toIso8601String(),
    ];
    if (excludingRecordId != null) {
      whereParts.add('id != ?');
      whereArgs.add(excludingRecordId);
    }

    final rows = await db.rawQuery(
      '''
      SELECT points, COUNT(*) AS record_count
      FROM study_records
      WHERE ${whereParts.join(' AND ')}
      GROUP BY points
      ''',
      whereArgs,
    );

    return {
      for (final row in rows)
        (row['points'] as int?) ?? 0: (row['record_count'] as int?) ?? 0,
    };
  }

  Future<void> replaceRecords(List<StudyRecord> items) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.delete('study_records');
      await _insertRecords(txn, items);
    });
  }

  Future<void> appendRecords(List<StudyRecord> items) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await _insertRecords(txn, items);
    });
  }

  Future<void> _insertRecords(
    DatabaseExecutor executor,
    List<StudyRecord> items,
  ) async {
    final batch = executor.batch();
    for (final item in items) {
      batch.insert(
        'study_records',
        item.toMap(includeId: true),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}
