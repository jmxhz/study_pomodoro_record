import 'package:sqflite/sqflite.dart';

import '../../core/db/app_database_runtime.dart';
import '../models/reward_redemption_record.dart';

class RewardRedemptionRepository {
  RewardRedemptionRepository(this._database);

  final AppDatabase _database;

  Future<int> insertRecord(RewardRedemptionRecord record) async {
    final db = await _database.database;
    return db.insert('reward_redemption_records', record.toMap());
  }

  Future<void> deleteRecord(int id) async {
    final db = await _database.database;
    await db.delete('reward_redemption_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<RewardRedemptionRecord>> getAllRecords() async {
    final db = await _database.database;
    final maps = await db.query(
      'reward_redemption_records',
      orderBy: 'redeemed_at DESC, id DESC',
    );
    return maps.map(RewardRedemptionRecord.fromMap).toList(growable: false);
  }

  Future<List<RewardRedemptionRecord>> getRecordsBetween(
    DateTime start,
    DateTime endExclusive,
  ) async {
    final db = await _database.database;
    final maps = await db.query(
      'reward_redemption_records',
      where: 'redeemed_at >= ? AND redeemed_at < ?',
      whereArgs: [start.toIso8601String(), endExclusive.toIso8601String()],
      orderBy: 'redeemed_at DESC, id DESC',
    );
    return maps.map(RewardRedemptionRecord.fromMap).toList(growable: false);
  }

  Future<List<RewardRedemptionRecord>> getRecordsBefore(DateTime before) async {
    final db = await _database.database;
    final maps = await db.query(
      'reward_redemption_records',
      where: 'redeemed_at < ?',
      whereArgs: [before.toIso8601String()],
      orderBy: 'redeemed_at DESC, id DESC',
    );
    return maps.map(RewardRedemptionRecord.fromMap).toList(growable: false);
  }

  Future<int> countRecordsBefore(DateTime before) async {
    final db = await _database.database;
    return Sqflite.firstIntValue(
          await db.query(
            'reward_redemption_records',
            columns: const ['COUNT(*)'],
            where: 'redeemed_at < ?',
            whereArgs: [before.toIso8601String()],
          ),
        ) ??
        0;
  }

  Future<int> totalRedeemedPoints() async {
    final db = await _database.database;
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COALESCE(SUM(cost_points), 0) FROM reward_redemption_records'),
        ) ??
        0;
  }

  Future<void> replaceRecords(List<RewardRedemptionRecord> items) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.delete('reward_redemption_records');
      await _insertRecords(txn, items);
    });
  }

  Future<void> appendRecords(List<RewardRedemptionRecord> items) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await _insertRecords(txn, items);
    });
  }

  Future<void> _insertRecords(
    DatabaseExecutor executor,
    List<RewardRedemptionRecord> items,
  ) async {
    final batch = executor.batch();
    for (final item in items) {
      batch.insert(
        'reward_redemption_records',
        item.toMap(includeId: true),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}
