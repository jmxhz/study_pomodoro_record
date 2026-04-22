import 'package:sqflite/sqflite.dart';

import '../../core/db/app_database_runtime.dart';
import '../models/category_option.dart';
import '../models/content_option.dart';
import '../models/improvement_option.dart';
import '../models/life_option.dart';
import '../models/redeem_reward.dart';
import '../models/reward_option.dart';
import '../models/weakness_option.dart';

class OptionsRepository {
  OptionsRepository(this._database);

  final AppDatabase _database;

  Future<List<CategoryOption>> getCategories({
    bool includeDisabled = true,
  }) async {
    final db = await _database.database;
    final maps = await db.query(
      'categories',
      where: includeDisabled ? null : 'is_enabled = 1',
      orderBy: 'sort_order ASC, id ASC',
    );
    return maps.map(CategoryOption.fromMap).toList(growable: false);
  }

  Future<List<ContentOption>> getContentOptions({
    bool includeDisabled = true,
  }) async {
    final db = await _database.database;
    final maps = await db.query(
      'content_options',
      where: includeDisabled ? null : 'is_enabled = 1',
      orderBy: 'sort_order ASC, id ASC',
    );
    return maps.map(ContentOption.fromMap).toList(growable: false);
  }

  Future<List<RewardOption>> getRewardOptions({
    bool includeDisabled = true,
    String? type,
  }) async {
    final db = await _database.database;
    final whereParts = <String>[];
    final whereArgs = <Object?>[];
    if (!includeDisabled) {
      whereParts.add('is_enabled = 1');
    }
    if (type != null) {
      whereParts.add('break_type = ?');
      whereArgs.add(type);
    }
    final maps = await db.query(
      'reward_options',
      where: whereParts.isEmpty ? null : whereParts.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'sort_order ASC, id ASC',
    );
    return maps.map(RewardOption.fromMap).toList(growable: false);
  }

  Future<int> getLongBreakEvery() async {
    final db = await _database.database;
    final maps = await db.query(
      'app_settings',
      columns: ['setting_value'],
      where: 'setting_key = ?',
      whereArgs: ['long_break_every'],
      limit: 1,
    );
    if (maps.isEmpty) {
      return 4;
    }
    return int.tryParse(maps.first['setting_value'] as String? ?? '') ?? 4;
  }

  Future<int> getSessionGapMinutes() async {
    final db = await _database.database;
    final maps = await db.query(
      'app_settings',
      columns: ['setting_value'],
      where: 'setting_key = ?',
      whereArgs: ['session_gap_minutes'],
      limit: 1,
    );
    if (maps.isEmpty) {
      return 90;
    }
    return int.tryParse(maps.first['setting_value'] as String? ?? '') ?? 90;
  }

  Future<int> getLifeDailyTargetPoints() async {
    final db = await _database.database;
    final maps = await db.query(
      'app_settings',
      columns: ['setting_value'],
      where: 'setting_key = ?',
      whereArgs: ['life_daily_target_points'],
      limit: 1,
    );
    if (maps.isEmpty) {
      return 10;
    }
    return int.tryParse(maps.first['setting_value'] as String? ?? '') ?? 10;
  }

  Future<int> getLifeDailyTargetBonusPoints() async {
    final db = await _database.database;
    final maps = await db.query(
      'app_settings',
      columns: ['setting_value'],
      where: 'setting_key = ?',
      whereArgs: ['life_daily_target_bonus_points'],
      limit: 1,
    );
    if (maps.isEmpty) {
      return 5;
    }
    return int.tryParse(maps.first['setting_value'] as String? ?? '') ?? 5;
  }

  Future<String> getThemePalette() async {
    final db = await _database.database;
    final maps = await db.query(
      'app_settings',
      columns: ['setting_value'],
      where: 'setting_key = ?',
      whereArgs: ['theme_palette'],
      limit: 1,
    );
    if (maps.isEmpty) {
      return 'monet-mist';
    }
    final value = maps.first['setting_value'] as String? ?? '';
    return value.trim().isEmpty ? 'monet-mist' : value;
  }

  Future<void> setThemePalette(String value) async {
    final db = await _database.database;
    await db.insert(
      'app_settings',
      {
        'setting_key': 'theme_palette',
        'setting_value': value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getBackupDirectoryPath() async {
    final db = await _database.database;
    final maps = await db.query(
      'app_settings',
      columns: ['setting_value'],
      where: 'setting_key = ?',
      whereArgs: ['backup_directory_path'],
      limit: 1,
    );
    if (maps.isEmpty) {
      return null;
    }
    final value = maps.first['setting_value'] as String? ?? '';
    return value.trim().isEmpty ? null : value;
  }

  Future<void> setBackupDirectoryPath(String value) async {
    final db = await _database.database;
    await db.insert(
      'app_settings',
      {
        'setting_key': 'backup_directory_path',
        'setting_value': value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getLastTransferDirectoryPath() async {
    final db = await _database.database;
    final maps = await db.query(
      'app_settings',
      columns: ['setting_value'],
      where: 'setting_key = ?',
      whereArgs: ['last_transfer_directory_path'],
      limit: 1,
    );
    if (maps.isEmpty) {
      return null;
    }
    final value = maps.first['setting_value'] as String? ?? '';
    return value.trim().isEmpty ? null : value;
  }

  Future<void> setLastTransferDirectoryPath(String value) async {
    final db = await _database.database;
    await db.insert(
      'app_settings',
      {
        'setting_key': 'last_transfer_directory_path',
        'setting_value': value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, String>> getBackupableAppSettings() async {
    final db = await _database.database;
    final maps = await db.query(
      'app_settings',
      columns: ['setting_key', 'setting_value'],
      where: 'setting_key IN (?, ?, ?, ?, ?)',
      whereArgs: [
        'long_break_every',
        'theme_palette',
        'session_gap_minutes',
        'life_daily_target_points',
        'life_daily_target_bonus_points',
      ],
    );
    return {
      for (final item in maps)
        item['setting_key'] as String: item['setting_value'] as String? ?? '',
    };
  }

  Future<void> upsertAppSettings(Map<String, String> values) async {
    if (values.isEmpty) {
      return;
    }
    final db = await _database.database;
    await db.transaction((txn) async {
      for (final entry in values.entries) {
        await txn.insert(
          'app_settings',
          {
            'setting_key': entry.key,
            'setting_value': entry.value,
            'updated_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> setLongBreakEvery(int value) async {
    final db = await _database.database;
    await db.insert(
      'app_settings',
      {
        'setting_key': 'long_break_every',
        'setting_value': '$value',
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> setSessionGapMinutes(int value) async {
    final db = await _database.database;
    await db.insert(
      'app_settings',
      {
        'setting_key': 'session_gap_minutes',
        'setting_value': '$value',
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> setLifeDailyTargetPoints(int value) async {
    final db = await _database.database;
    await db.insert(
      'app_settings',
      {
        'setting_key': 'life_daily_target_points',
        'setting_value': '$value',
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> setLifeDailyTargetBonusPoints(int value) async {
    final db = await _database.database;
    await db.insert(
      'app_settings',
      {
        'setting_key': 'life_daily_target_bonus_points',
        'setting_value': '$value',
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<WeaknessOption>> getWeaknessOptions({
    bool includeDisabled = true,
  }) async {
    final db = await _database.database;
    final maps = await db.query(
      'weakness_options',
      where: includeDisabled ? null : 'is_enabled = 1',
      orderBy: 'sort_order ASC, id ASC',
    );
    return maps.map(WeaknessOption.fromMap).toList(growable: false);
  }

  Future<List<ImprovementOption>> getImprovementOptions({
    bool includeDisabled = true,
  }) async {
    final db = await _database.database;
    final maps = await db.query(
      'improvement_options',
      where: includeDisabled ? null : 'is_enabled = 1',
      orderBy: 'sort_order ASC, id ASC',
    );
    return maps.map(ImprovementOption.fromMap).toList(growable: false);
  }

  Future<List<RedeemReward>> getRedeemRewards({
    bool includeDisabled = true,
  }) async {
    final db = await _database.database;
    final maps = await db.query(
      'redeem_rewards',
      where: includeDisabled ? null : 'is_enabled = 1',
      orderBy: 'sort_order ASC, id ASC',
    );
    return maps.map(RedeemReward.fromMap).toList(growable: false);
  }

  Future<List<LifeOption>> getLifeOptions({
    bool includeDisabled = true,
  }) async {
    final db = await _database.database;
    final maps = await db.query(
      'life_options',
      where: includeDisabled ? null : 'is_enabled = 1',
      orderBy: 'sort_order ASC, id ASC',
    );
    return maps.map(LifeOption.fromMap).toList(growable: false);
  }

  Future<int> insertCategory(CategoryOption category) async {
    final db = await _database.database;
    return db.insert('categories', category.toMap());
  }

  Future<void> updateCategory(CategoryOption category) async {
    final db = await _database.database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(int id) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.update(
        'content_options',
        {'category_id': null},
        where: 'category_id = ?',
        whereArgs: [id],
      );
      await txn.delete('categories', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> reorderCategories(List<CategoryOption> categories) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      for (var index = 0; index < categories.length; index++) {
        await txn.update(
          'categories',
          {
            'sort_order': index,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [categories[index].id],
        );
      }
    });
  }

  Future<int> insertContentOption(ContentOption contentOption) async {
    final db = await _database.database;
    return db.insert('content_options', contentOption.toMap());
  }

  Future<void> updateContentOption(ContentOption contentOption) async {
    final db = await _database.database;
    await db.update(
      'content_options',
      contentOption.toMap(),
      where: 'id = ?',
      whereArgs: [contentOption.id],
    );
  }

  Future<void> deleteContentOption(int id) async {
    final db = await _database.database;
    await db.delete('content_options', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> reorderContentOptions(List<ContentOption> options) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      for (var index = 0; index < options.length; index++) {
        await txn.update(
          'content_options',
          {
            'sort_order': index,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [options[index].id],
        );
      }
    });
  }

  Future<int> insertRewardOption(RewardOption rewardOption) async {
    final db = await _database.database;
    return db.insert('reward_options', rewardOption.toMap());
  }

  Future<int> insertWeaknessOption(WeaknessOption item) async {
    final db = await _database.database;
    return db.insert('weakness_options', item.toMap());
  }

  Future<int> insertImprovementOption(ImprovementOption item) async {
    final db = await _database.database;
    return db.insert('improvement_options', item.toMap());
  }

  Future<int> insertRedeemReward(RedeemReward item) async {
    final db = await _database.database;
    return db.insert('redeem_rewards', item.toMap());
  }

  Future<int> insertLifeOption(LifeOption item) async {
    final db = await _database.database;
    return db.insert('life_options', item.toMap());
  }

  Future<void> updateRewardOption(RewardOption rewardOption) async {
    final db = await _database.database;
    await db.update(
      'reward_options',
      rewardOption.toMap(),
      where: 'id = ?',
      whereArgs: [rewardOption.id],
    );
  }

  Future<void> updateWeaknessOption(WeaknessOption item) async {
    final db = await _database.database;
    await db.update(
      'weakness_options',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> updateImprovementOption(ImprovementOption item) async {
    final db = await _database.database;
    await db.update(
      'improvement_options',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> updateRedeemReward(RedeemReward item) async {
    final db = await _database.database;
    await db.update(
      'redeem_rewards',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> updateLifeOption(LifeOption item) async {
    final db = await _database.database;
    await db.update(
      'life_options',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteRewardOption(int id) async {
    final db = await _database.database;
    await db.delete('reward_options', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteWeaknessOption(int id) async {
    final db = await _database.database;
    await db.delete('weakness_options', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteImprovementOption(int id) async {
    final db = await _database.database;
    await db.delete('improvement_options', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteRedeemReward(int id) async {
    final db = await _database.database;
    await db.delete('redeem_rewards', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteLifeOption(int id) async {
    final db = await _database.database;
    await db.delete('life_options', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> reorderRewardOptions(List<RewardOption> options) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      for (var index = 0; index < options.length; index++) {
        await txn.update(
          'reward_options',
          {
            'sort_order': index,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [options[index].id],
        );
      }
    });
  }

  Future<void> reorderWeaknessOptions(List<WeaknessOption> items) async {
    await _reorderSimpleTable(
        'weakness_options', items.map((item) => item.id).toList());
  }

  Future<void> reorderImprovementOptions(List<ImprovementOption> items) async {
    await _reorderSimpleTable(
        'improvement_options', items.map((item) => item.id).toList());
  }

  Future<void> reorderRedeemRewards(List<RedeemReward> items) async {
    await _reorderSimpleTable(
        'redeem_rewards', items.map((item) => item.id).toList());
  }

  Future<void> reorderLifeOptions(List<LifeOption> items) async {
    await _reorderSimpleTable(
        'life_options', items.map((item) => item.id).toList());
  }

  Future<int> nextCategorySortOrder() => _nextSortOrder('categories');

  Future<int> nextContentSortOrder() => _nextSortOrder('content_options');

  Future<int> nextRewardSortOrder() => _nextSortOrder('reward_options');

  Future<int> nextWeaknessSortOrder() => _nextSortOrder('weakness_options');

  Future<int> nextImprovementSortOrder() =>
      _nextSortOrder('improvement_options');

  Future<int> nextRedeemRewardSortOrder() => _nextSortOrder('redeem_rewards');

  Future<int> nextLifeOptionSortOrder() => _nextSortOrder('life_options');

  Future<int> _nextSortOrder(String table) async {
    final db = await _database.database;
    final result = Sqflite.firstIntValue(
          await db.rawQuery('SELECT MAX(sort_order) FROM $table'),
        ) ??
        -1;
    return result + 1;
  }

  Future<void> replaceCategories(List<CategoryOption> items) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.update('content_options', {'category_id': null});
      await txn.delete('categories');
      await _insertCategories(txn, items);
    });
  }

  Future<void> appendCategories(List<CategoryOption> items) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await _insertCategories(txn, items);
    });
  }

  Future<void> replaceContentOptions(List<ContentOption> items) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.delete('content_options');
      await _insertContentOptions(txn, items);
    });
  }

  Future<void> appendContentOptions(List<ContentOption> items) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await _insertContentOptions(txn, items);
    });
  }

  Future<void> replaceRewardOptions(List<RewardOption> items) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.delete('reward_options');
      await _insertRewardOptions(txn, items);
    });
  }

  Future<void> appendRewardOptions(List<RewardOption> items) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await _insertRewardOptions(txn, items);
    });
  }

  Future<void> replaceWeaknessOptions(List<WeaknessOption> items) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.delete('weakness_options');
      await _insertWeaknessOptions(txn, items);
    });
  }

  Future<void> appendWeaknessOptions(List<WeaknessOption> items) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await _insertWeaknessOptions(txn, items);
    });
  }

  Future<void> replaceImprovementOptions(List<ImprovementOption> items) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.delete('improvement_options');
      await _insertImprovementOptions(txn, items);
    });
  }

  Future<void> appendImprovementOptions(List<ImprovementOption> items) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await _insertImprovementOptions(txn, items);
    });
  }

  Future<void> replaceRedeemRewards(List<RedeemReward> items) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.delete('redeem_rewards');
      await _insertRedeemRewards(txn, items);
    });
  }

  Future<void> appendRedeemRewards(List<RedeemReward> items) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await _insertRedeemRewards(txn, items);
    });
  }

  Future<void> replaceLifeOptions(List<LifeOption> items) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.delete('life_options');
      await _insertLifeOptions(txn, items);
    });
  }

  Future<void> appendLifeOptions(List<LifeOption> items) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await _insertLifeOptions(txn, items);
    });
  }

  Future<void> normalizeContentCategoryBindings() async {
    final db = await _database.database;
    await db.transaction((txn) async {
      for (final table in const [
        'content_options',
        'weakness_options',
        'improvement_options',
      ]) {
        await txn.rawUpdate('''
          UPDATE $table
          SET category_id = NULL
          WHERE category_id IS NOT NULL
            AND category_id NOT IN (SELECT id FROM categories)
        ''');
      }
      for (final table in const ['weakness_options', 'improvement_options']) {
        await txn.rawUpdate('''
          UPDATE $table
          SET content_option_id = NULL
          WHERE content_option_id IS NOT NULL
            AND content_option_id NOT IN (SELECT id FROM content_options)
        ''');
      }
    });
  }

  Future<void> _reorderSimpleTable(String table, List<int?> ids) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      for (var index = 0; index < ids.length; index++) {
        await txn.update(
          table,
          {
            'sort_order': index,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [ids[index]],
        );
      }
    });
  }

  Future<void> _insertCategories(
    DatabaseExecutor executor,
    List<CategoryOption> items,
  ) async {
    final batch = executor.batch();
    for (final item in items) {
      batch.insert(
        'categories',
        item.toMap(includeId: true),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> _insertContentOptions(
    DatabaseExecutor executor,
    List<ContentOption> items,
  ) async {
    final batch = executor.batch();
    for (final item in items) {
      batch.insert(
        'content_options',
        item.toMap(includeId: true),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> _insertRewardOptions(
    DatabaseExecutor executor,
    List<RewardOption> items,
  ) async {
    final batch = executor.batch();
    for (final item in items) {
      batch.insert(
        'reward_options',
        item.toMap(includeId: true),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> _insertWeaknessOptions(
    DatabaseExecutor executor,
    List<WeaknessOption> items,
  ) async {
    final batch = executor.batch();
    for (final item in items) {
      batch.insert(
        'weakness_options',
        item.toMap(includeId: true),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> _insertImprovementOptions(
    DatabaseExecutor executor,
    List<ImprovementOption> items,
  ) async {
    final batch = executor.batch();
    for (final item in items) {
      batch.insert(
        'improvement_options',
        item.toMap(includeId: true),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> _insertRedeemRewards(
    DatabaseExecutor executor,
    List<RedeemReward> items,
  ) async {
    final batch = executor.batch();
    for (final item in items) {
      batch.insert(
        'redeem_rewards',
        item.toMap(includeId: true),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> _insertLifeOptions(
    DatabaseExecutor executor,
    List<LifeOption> items,
  ) async {
    final batch = executor.batch();
    for (final item in items) {
      batch.insert(
        'life_options',
        item.toMap(includeId: true),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}
