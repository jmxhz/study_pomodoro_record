import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const _databaseName = 'study_pomodoro_record.db';
  static const _databaseVersion = 7;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _open();
    return _database!;
  }

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), _databaseName);
    return openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = OFF;');
      },
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await _migrateToV3(db);
        }
        if (oldVersion < 4) {
          await _migrateToV4(db);
        }
        if (oldVersion < 5) {
          await _migrateToV5(db);
        }
        if (oldVersion < 6) {
          await _migrateToV6(db);
        }
        if (oldVersion < 7) {
          await _migrateToV7(db);
        }
      },
      onOpen: (db) async {
        await _seedFreshDefaultsIfNeeded(db);
        await _seedOptionDefaultsIfNeeded(db);
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE content_options (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category_id INTEGER,
        sort_order INTEGER NOT NULL,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        points INTEGER NOT NULL DEFAULT 1,
        default_points INTEGER NOT NULL DEFAULT 1,
        allow_adjust INTEGER NOT NULL DEFAULT 0,
        min_points INTEGER NOT NULL DEFAULT 1,
        max_points INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE reward_options (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        break_type TEXT NOT NULL DEFAULT 'short',
        sort_order INTEGER NOT NULL,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await _createWeaknessOptionsTable(db);
    await _createImprovementOptionsTable(db);
    await _createRedeemRewardsTable(db);
    await _createLifeOptionsTable(db);

    await db.execute('''
      CREATE TABLE study_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        record_kind TEXT NOT NULL DEFAULT 'study',
        life_option_id INTEGER,
        occurred_at TEXT NOT NULL,
        category_id INTEGER,
        category_name_snapshot TEXT NOT NULL,
        content_option_id INTEGER,
        content_name_snapshot TEXT NOT NULL,
        reward_option_id INTEGER,
        reward_name_snapshot TEXT NOT NULL,
        break_type TEXT,
        feedback_option_id INTEGER,
        feedback_name_snapshot TEXT,
        pomodoro_count INTEGER NOT NULL,
        points INTEGER NOT NULL,
        detail_amount_text TEXT,
        question_count INTEGER,
        wrong_count INTEGER,
        output_type TEXT,
        weakness_tags TEXT,
        improvement_tags TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await _createRewardRedemptionRecordsTable(db);
    await _createAppSettingsTable(db);
  }

  Future<void> _createWeaknessOptionsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS weakness_options (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category_id INTEGER,
        content_option_id INTEGER,
        sort_order INTEGER NOT NULL,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createImprovementOptionsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS improvement_options (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category_id INTEGER,
        content_option_id INTEGER,
        sort_order INTEGER NOT NULL,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createRedeemRewardsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS redeem_rewards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        cost_points INTEGER NOT NULL,
        sort_order INTEGER NOT NULL,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        note TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createRewardRedemptionRecordsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reward_redemption_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reward_id INTEGER,
        reward_name_snapshot TEXT NOT NULL,
        cost_points INTEGER NOT NULL,
        redeemed_at TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createLifeOptionsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS life_options (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        points INTEGER NOT NULL,
        sort_order INTEGER NOT NULL,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createAppSettingsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        setting_key TEXT PRIMARY KEY,
        setting_value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _migrateToV3(Database db) async {
    await _addColumnIfMissing(
      db,
      table: 'content_options',
      columnName: 'default_points',
      definition: 'INTEGER NOT NULL DEFAULT 1',
    );
    await _addColumnIfMissing(
      db,
      table: 'content_options',
      columnName: 'allow_adjust',
      definition: 'INTEGER NOT NULL DEFAULT 1',
    );
    await _addColumnIfMissing(
      db,
      table: 'content_options',
      columnName: 'min_points',
      definition: 'INTEGER NOT NULL DEFAULT 1',
    );
    await _addColumnIfMissing(
      db,
      table: 'content_options',
      columnName: 'max_points',
      definition: 'INTEGER NOT NULL DEFAULT 4',
    );

    await _addColumnIfMissing(
      db,
      table: 'study_records',
      columnName: 'feedback_option_id',
      definition: 'INTEGER',
    );
    await _addColumnIfMissing(
      db,
      table: 'study_records',
      columnName: 'feedback_name_snapshot',
      definition: 'TEXT',
    );
    await _addColumnIfMissing(
      db,
      table: 'study_records',
      columnName: 'detail_amount_text',
      definition: 'TEXT',
    );
    await _addColumnIfMissing(
      db,
      table: 'study_records',
      columnName: 'question_count',
      definition: 'INTEGER',
    );
    await _addColumnIfMissing(
      db,
      table: 'study_records',
      columnName: 'wrong_count',
      definition: 'INTEGER',
    );
    await _addColumnIfMissing(
      db,
      table: 'study_records',
      columnName: 'output_type',
      definition: 'TEXT',
    );
    await _addColumnIfMissing(
      db,
      table: 'study_records',
      columnName: 'weakness_tags',
      definition: 'TEXT',
    );
    await _addColumnIfMissing(
      db,
      table: 'study_records',
      columnName: 'improvement_tags',
      definition: 'TEXT',
    );
    await _addColumnIfMissing(
      db,
      table: 'study_records',
      columnName: 'notes',
      definition: 'TEXT',
    );

    await _createWeaknessOptionsTable(db);
    await _createImprovementOptionsTable(db);
    await _createRedeemRewardsTable(db);
    await _createRewardRedemptionRecordsTable(db);

    await db.execute('''
      UPDATE study_records
      SET feedback_option_id = reward_option_id
      WHERE feedback_option_id IS NULL
    ''');
    await db.execute('''
      UPDATE study_records
      SET feedback_name_snapshot = reward_name_snapshot
      WHERE feedback_name_snapshot IS NULL
    ''');

    await _backfillContentPointConfig(db);
  }

  Future<void> _migrateToV4(Database db) async {
    await _addColumnIfMissing(
      db,
      table: 'content_options',
      columnName: 'points',
      definition: 'INTEGER NOT NULL DEFAULT 1',
    );
    await _addColumnIfMissing(
      db,
      table: 'reward_options',
      columnName: 'break_type',
      definition: "TEXT NOT NULL DEFAULT 'short'",
    );
    await _addColumnIfMissing(
      db,
      table: 'study_records',
      columnName: 'break_type',
      definition: 'TEXT',
    );

    await _createAppSettingsTable(db);

    await _backfillContentPointConfig(db);
    await _backfillBreakTypes(db);
    await _seedLongBreakSettingIfNeeded(db);
    await _migrateRedeemRewardDefaults(db);
  }

  Future<void> _migrateToV5(Database db) async {
    await _addColumnIfMissing(
      db,
      table: 'weakness_options',
      columnName: 'content_option_id',
      definition: 'INTEGER',
    );
    await _addColumnIfMissing(
      db,
      table: 'improvement_options',
      columnName: 'content_option_id',
      definition: 'INTEGER',
    );
  }

  Future<void> _migrateToV6(Database db) async {
    await _syncContentStudyTypes(db);
  }

  Future<void> _migrateToV7(Database db) async {
    await _addColumnIfMissing(
      db,
      table: 'study_records',
      columnName: 'record_kind',
      definition: "TEXT NOT NULL DEFAULT 'study'",
    );
    await _addColumnIfMissing(
      db,
      table: 'study_records',
      columnName: 'life_option_id',
      definition: 'INTEGER',
    );
    await _createLifeOptionsTable(db);
    await db.execute('''
      UPDATE study_records
      SET record_kind = 'study'
      WHERE record_kind IS NULL OR TRIM(record_kind) = ''
    ''');
    await _seedLifeOptionsIfNeeded(db);
  }

  Future<void> _seedFreshDefaultsIfNeeded(Database db) async {
    final categoryCount = await _count(db, 'categories');
    final contentCount = await _count(db, 'content_options');
    final feedbackCount = await _count(db, 'reward_options');

    if (categoryCount > 0 || contentCount > 0 || feedbackCount > 0) {
      return;
    }

    final now = DateTime.now().toIso8601String();
    final categoryIds = <String, int>{};

    await db.transaction((txn) async {
      const defaultCategories = ['行测', '申论', '英语'];
      for (var index = 0; index < defaultCategories.length; index++) {
        final id = await txn.insert('categories', {
          'name': defaultCategories[index],
          'sort_order': index,
          'is_enabled': 1,
          'created_at': now,
          'updated_at': now,
        });
        categoryIds[defaultCategories[index]] = id;
      }

      const defaultContents = <String, List<String>>{
        '行测': ['判断推理', '资料分析', '语言理解', '常识判断', '数量关系'],
        '申论': ['练字', '摘抄', '概括题', '对策题', '公文题', '大作文'],
        '英语': ['单词', '精听', '跟读', '阅读', '口语', '写作', '泛听'],
      };

      var contentSortOrder = 0;
      for (final entry in defaultContents.entries) {
        for (final name in entry.value) {
          final config = _defaultPointsConfig(name);
          await txn.insert('content_options', {
            'name': name,
            'category_id': categoryIds[entry.key],
            'sort_order': contentSortOrder++,
            'is_enabled': 1,
            'points': config.points,
            'default_points': config.points,
            'allow_adjust': 0,
            'min_points': config.points,
            'max_points': config.points,
            'created_at': now,
            'updated_at': now,
          });
        }
      }

      const shortBreaks = [
        '拉伸',
        '喝水',
        '闭眼休息5分钟',
        '起身站立',
        '深呼吸1分钟',
        '上厕所',
      ];
      const longBreaks = [
        '散步10~15分钟',
        '听歌10分钟',
        '洗脸/透气',
        '吃点东西',
        '发呆10分钟',
        '休息15分钟',
      ];
      var sortOrder = 0;
      for (final item in shortBreaks) {
        await txn.insert('reward_options', {
          'name': item,
          'break_type': 'short',
          'sort_order': sortOrder++,
          'is_enabled': 1,
          'created_at': now,
          'updated_at': now,
        });
      }
      for (final item in longBreaks) {
        await txn.insert('reward_options', {
          'name': item,
          'break_type': 'long',
          'sort_order': sortOrder++,
          'is_enabled': 1,
          'created_at': now,
          'updated_at': now,
        });
      }
    });
    await _seedLongBreakSettingIfNeeded(db);
    await _seedSessionGapSettingIfNeeded(db);
    await _seedThemePaletteIfNeeded(db);
    await _seedLifeOptionsIfNeeded(db);
    await _syncLifeOptionDefaults(db);
    await _syncContentStudyTypes(db);
  }

  Future<void> _seedOptionDefaultsIfNeeded(Database db) async {
    await _seedMissingContentBoundOptions(
      db: db,
      table: 'weakness_options',
      optionsByContentName: _defaultWeaknessOptionsByContentName,
    );

    await _seedMissingContentBoundOptions(
      db: db,
      table: 'improvement_options',
      optionsByContentName: _defaultImprovementOptionsByContentName,
    );

    if (await _count(db, 'redeem_rewards') == 0) {
      await _replaceRedeemRewardDefaults(db);
    }

    await _seedLongBreakSettingIfNeeded(db);
    await _seedSessionGapSettingIfNeeded(db);
    await _seedLifeOptionsIfNeeded(db);
    await _syncLifeOptionDefaults(db);
    await _syncContentStudyTypes(db);
  }

  Future<void> _seedLifeOptionsIfNeeded(Database db) async {
    if (await _count(db, 'life_options') > 0) {
      return;
    }
    final now = DateTime.now().toIso8601String();
    const defaults = [
      ('肩颈放松', 1),
      ('轻度锻炼', 1),
      ('起床后立刻离床', 2),
      ('回家后立刻洗漱', 2),
      ('早晨未在床上刷视频', 3),
      ('晚上未刷视频/未玩游戏失控', 3),
      ('22:00 前上床', 4),
      ('23:00 前睡觉，且打卡后不再玩手机', 4),
    ];
    await db.transaction((txn) async {
      for (var index = 0; index < defaults.length; index++) {
        final item = defaults[index];
        await txn.insert('life_options', {
          'name': item.$1,
          'points': item.$2,
          'sort_order': index,
          'is_enabled': 1,
          'created_at': now,
          'updated_at': now,
        });
      }
    });
  }

  Future<void> _syncLifeOptionDefaults(Database db) async {
    final now = DateTime.now().toIso8601String();
    const defaults = [
      ('肩颈放松', 1),
      ('轻度锻炼', 1),
      ('起床后立刻离床', 2),
      ('回家后立刻洗漱', 2),
      ('早晨未在床上刷视频', 3),
      ('晚上未刷视频/未玩游戏失控', 3),
      ('22:00 前上床', 4),
      ('23:00 前睡觉，且打卡后不再玩手机', 4),
    ];
    const legacyToCanonical = {
      '22点前上床': '22:00 前上床',
      '23点前睡觉': '23:00 前睡觉，且打卡后不再玩手机',
      '22:30打卡后未继续玩手机': '23:00 前睡觉，且打卡后不再玩手机',
      '晚上未刷视频/未玩游戏': '晚上未刷视频/未玩游戏失控',
    };
    const managedNames = {
      '肩颈放松',
      '轻度锻炼',
      '起床后立刻离床',
      '回家后立刻洗漱',
      '早晨未在床上刷视频',
      '晚上未刷视频/未玩游戏失控',
      '22:00 前上床',
      '23:00 前睡觉，且打卡后不再玩手机',
      '22点前上床',
      '23点前睡觉',
      '22:30打卡后未继续玩手机',
      '晚上未刷视频/未玩游戏',
    };

    final rows = await db.query('life_options');
    final rowByName = <String, Map<String, Object?>>{
      for (final row in rows) (row['name'] as String): row,
    };

    await db.transaction((txn) async {
      for (var index = 0; index < defaults.length; index++) {
        final targetName = defaults[index].$1;
        final targetPoints = defaults[index].$2;
        Map<String, Object?>? source = rowByName[targetName];
        if (source == null) {
          for (final entry in rowByName.entries) {
            final canonical = legacyToCanonical[entry.key] ?? entry.key;
            if (canonical == targetName) {
              source = entry.value;
              break;
            }
          }
        }

        if (source != null) {
          await txn.update(
            'life_options',
            {
              'name': targetName,
              'points': targetPoints,
              'sort_order': index,
              'updated_at': now,
            },
            where: 'id = ?',
            whereArgs: [source['id']],
          );
        } else {
          await txn.insert('life_options', {
            'name': targetName,
            'points': targetPoints,
            'sort_order': index,
            'is_enabled': 1,
            'created_at': now,
            'updated_at': now,
          });
        }
      }

      final refreshed = await txn.query('life_options');
      for (final row in refreshed) {
        final name = row['name'] as String;
        if (!managedNames.contains(name)) {
          continue;
        }
        if (defaults.any((item) => item.$1 == name)) {
          continue;
        }
        await txn.delete(
          'life_options',
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      }
    });
  }

  Future<void> _seedContentBoundOptions({
    required Database db,
    required String table,
    required Map<String, List<String>> optionsByContentName,
  }) async {
    final contents = await db.query('content_options');
    final contentIds = {
      for (final row in contents) row['name'] as String: row['id'] as int,
    };
    final now = DateTime.now().toIso8601String();
    var sortOrder = 0;

    await db.transaction((txn) async {
      for (final entry in optionsByContentName.entries) {
        final contentOptionId = contentIds[entry.key];
        if (contentOptionId == null) {
          continue;
        }
        for (final name in entry.value) {
          await txn.insert(table, {
            'name': name,
            'category_id': null,
            'content_option_id': contentOptionId,
            'sort_order': sortOrder++,
            'is_enabled': 1,
            'created_at': now,
            'updated_at': now,
          });
        }
      }
    });
  }

  Future<void> _seedMissingContentBoundOptions({
    required Database db,
    required String table,
    required Map<String, List<String>> optionsByContentName,
  }) async {
    final contents = await db.query('content_options');
    final existing = await db.query(
      table,
      columns: const ['content_option_id'],
      where: 'content_option_id IS NOT NULL',
    );
    final existingContentIds = existing
        .map((row) => row['content_option_id'] as int?)
        .whereType<int>()
        .toSet();

    final missing = <String, List<String>>{};
    for (final row in contents) {
      final id = row['id'] as int?;
      final name = row['name'] as String?;
      if (id == null || name == null) {
        continue;
      }
      final options = optionsByContentName[name];
      if (options == null || existingContentIds.contains(id)) {
        continue;
      }
      missing[name] = options;
    }

    if (missing.isEmpty) {
      return;
    }

    await _seedContentBoundOptions(
      db: db,
      table: table,
      optionsByContentName: missing,
    );
  }

  Future<void> _backfillContentPointConfig(Database db) async {
    final rows = await db.query('content_options');
    for (final row in rows) {
      final id = row['id'] as int?;
      final name = row['name'] as String?;
      if (id == null || name == null) {
        continue;
      }
      final config = _defaultPointsConfig(name);
      await db.update(
        'content_options',
        {
          'points': config.points,
          'default_points': config.points,
          'allow_adjust': 0,
          'min_points': config.points,
          'max_points': config.points,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> _syncContentStudyTypes(Database db) async {
    final categories =
        await db.query('categories', columns: const ['id', 'name']);
    final categoryIds = <String, int>{
      for (final row in categories)
        if (row['id'] is int && row['name'] is String)
          row['name'] as String: row['id'] as int,
    };
    final existingContents = await db.query('content_options');
    final existingByName = <String, Map<String, Object?>>{
      for (final row in existingContents)
        if (row['name'] is String) row['name'] as String: row,
    };
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      for (final entry in _studyTypeContentDefaults.entries) {
        final name = entry.key;
        final categoryId = categoryIds[entry.value.categoryName];
        if (categoryId == null) {
          continue;
        }
        final existing = existingByName[name];
        if (existing == null) {
          final sortOrder = await _nextSortOrderInTxn(txn, 'content_options');
          await txn.insert('content_options', {
            'name': name,
            'category_id': categoryId,
            'sort_order': sortOrder,
            'is_enabled': 1,
            'points': entry.value.points,
            'default_points': entry.value.points,
            'allow_adjust': 0,
            'min_points': entry.value.points,
            'max_points': entry.value.points,
            'created_at': now,
            'updated_at': now,
          });
          continue;
        }

        await txn.update(
          'content_options',
          {
            'category_id': categoryId,
            'points': entry.value.points,
            'default_points': entry.value.points,
            'allow_adjust': 0,
            'min_points': entry.value.points,
            'max_points': entry.value.points,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [existing['id']],
        );
      }
    });
  }

  Future<int> _nextSortOrderInTxn(DatabaseExecutor db, String table) async {
    return Sqflite.firstIntValue(
          await db
              .rawQuery('SELECT COALESCE(MAX(sort_order), -1) + 1 FROM $table'),
        ) ??
        0;
  }

  Future<void> _backfillBreakTypes(Database db) async {
    final rows = await db.query('reward_options');
    for (final row in rows) {
      final id = row['id'] as int?;
      final name = row['name'] as String?;
      if (id == null || name == null) {
        continue;
      }
      await db.update(
        'reward_options',
        {'break_type': _inferBreakType(name)},
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    await db.rawUpdate('''
      UPDATE study_records
      SET break_type = (
        SELECT reward_options.break_type
        FROM reward_options
        WHERE reward_options.id = study_records.feedback_option_id
      )
      WHERE break_type IS NULL AND feedback_option_id IS NOT NULL
    ''');
  }

  Future<void> _seedLongBreakSettingIfNeeded(Database db) async {
    final rows = await db.query(
      'app_settings',
      where: 'setting_key = ?',
      whereArgs: ['long_break_every'],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return;
    }
    await db.insert('app_settings', {
      'setting_key': 'long_break_every',
      'setting_value': '4',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _seedSessionGapSettingIfNeeded(Database db) async {
    final rows = await db.query(
      'app_settings',
      where: 'setting_key = ?',
      whereArgs: ['session_gap_minutes'],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return;
    }
    await db.insert('app_settings', {
      'setting_key': 'session_gap_minutes',
      'setting_value': '90',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _seedThemePaletteIfNeeded(Database db) async {
    final rows = await db.query(
      'app_settings',
      where: 'setting_key = ?',
      whereArgs: ['theme_palette'],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return;
    }
    await db.insert('app_settings', {
      'setting_key': 'theme_palette',
      'setting_value': 'monet-mist',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _migrateRedeemRewardDefaults(Database db) async {
    final rows = await db.query(
      'redeem_rewards',
      orderBy: 'sort_order ASC, id ASC',
    );
    if (rows.isEmpty) {
      return;
    }

    const oldDefaultNames = {
      '听歌10分钟',
      '看视频20分钟',
      '散步15分钟',
      '买饮料',
      '周末多休息半小时',
    };
    final currentNames = rows.map((row) => row['name'] as String).toSet();
    if (currentNames.length != oldDefaultNames.length ||
        !currentNames.containsAll(oldDefaultNames)) {
      return;
    }

    await _replaceRedeemRewardDefaults(db);
  }

  Future<void> _replaceRedeemRewardDefaults(Database db) async {
    final now = DateTime.now().toIso8601String();
    const defaults = [
      ('看短视频10分钟', 3),
      ('躺着放空10分钟', 3),
      ('看视频20分钟', 5),
      ('打游戏20分钟', 6),
      ('吃一个小零食', 6),
      ('买饮料', 8),
      ('看一集动漫/剧', 10),
      ('周末额外娱乐30分钟', 10),
      ('打游戏40分钟', 10),
      ('买一份想吃的小吃', 12),
    ];

    await db.transaction((txn) async {
      await txn.delete('redeem_rewards');
      for (var index = 0; index < defaults.length; index++) {
        await txn.insert('redeem_rewards', {
          'name': defaults[index].$1,
          'cost_points': defaults[index].$2,
          'sort_order': index,
          'is_enabled': 1,
          'note': null,
          'created_at': now,
          'updated_at': now,
        });
      }
    });
  }

  Future<void> _addColumnIfMissing(
    Database db, {
    required String table,
    required String columnName,
    required String definition,
  }) async {
    if (await _hasColumn(db, table: table, columnName: columnName)) {
      return;
    }
    await db.execute('ALTER TABLE $table ADD COLUMN $columnName $definition');
  }

  Future<bool> _hasColumn(
    Database db, {
    required String table,
    required String columnName,
  }) async {
    final rows = await db.rawQuery('PRAGMA table_info($table)');
    return rows.any((row) => row['name'] == columnName);
  }

  Future<int> _count(Database db, String table) async {
    return Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM $table')) ??
        0;
  }

  _PointsConfig _defaultPointsConfig(String contentName) {
    switch (contentName) {
      case '判断推理':
        return const _PointsConfig(points: 2);
      case '资料分析':
        return const _PointsConfig(points: 3);
      case '言语理解':
      case '语言理解':
        return const _PointsConfig(points: 2);
      case '常识':
      case '常识判断':
        return const _PointsConfig(points: 1);
      case '数量关系':
        return const _PointsConfig(points: 3);
      case '练字':
      case '摘抄':
        return const _PointsConfig(points: 1);
      case '概括题':
        return const _PointsConfig(points: 2);
      case '对策题':
      case '公文题':
        return const _PointsConfig(points: 3);
      case '大作文':
        return const _PointsConfig(points: 4);
      case '单词':
      case '泛听':
        return const _PointsConfig(points: 1);
      case '精听':
      case '跟读':
      case '阅读':
        return const _PointsConfig(points: 2);
      case '口语':
      case '写作':
        return const _PointsConfig(points: 3);
      default:
        return const _PointsConfig(points: 1);
    }
  }

  String _inferBreakType(String name) {
    const longNames = {
      '散步',
      '散步10~15分钟',
      '听歌',
      '听歌10分钟',
      '洗脸/透气',
      '吃点东西',
      '发呆10分钟',
      '休息15分钟',
    };
    for (final item in longNames) {
      if (name.contains(item)) {
        return 'long';
      }
    }
    return 'short';
  }

  static const Map<String, List<String>> _defaultWeaknessOptionsByContentName =
      {
    '判断推理': ['条件不清', '削弱加强混淆', '图形规律不稳', '定义抓不准', '推理链断裂'],
    '资料分析': ['公式不熟', '找数慢', '列式错误', '估算不稳', '时间分配差'],
    '语言理解': ['主旨抓不准', '选项排除慢', '逻辑关系不清', '关键词不敏感', '易受干扰项影响'],
    '常识判断': ['知识点遗忘', '范围太散', '记忆不牢', '混淆相近概念', '积累不足'],
    '数量关系': ['公式不熟', '建模慢', '计算易错', '题型识别慢', '不会取舍'],
    '单词': ['记不住', '拼写易错', '词义混淆', '熟词僻义不清', '复习不及时'],
    '精听': ['连读听不出', '生词多', '反应慢', '句子结构不清', '听完就忘'],
    '跟读': ['发音不准', '连读不自然', '节奏不对', '重音错误', '开口不顺'],
    '阅读': ['长难句看不懂', '词义不熟', '逻辑关系不清', '定位慢', '主旨不清'],
    '口语': ['发音不准', '组织慢', '词不达意', '句型单一', '不敢开口'],
    '写作': ['语法错误', '词汇贫乏', '句型单一', '逻辑不清', '审题偏差'],
    '泛听': ['听不住', '容易走神', '大意抓不住', '生词干扰', '语速不适应'],
    '练字': ['字迹不稳', '结构松散', '大小不一', '书写慢', '易连笔'],
    '摘抄': ['机械抄写', '不理解内容', '表达没吸收', '速度慢', '易走神'],
    '概括题': ['要点遗漏', '概括不准', '表达啰嗦', '审题不清', '层次混乱'],
    '对策题': ['对策空泛', '对策不具体', '针对性不足', '逻辑混乱', '审题偏差'],
    '公文题': ['格式错误', '角色意识弱', '语气不对', '要点遗漏', '结构不清'],
    '大作文': ['立意不稳', '结构松散', '论证空泛', '开头结尾弱', '无法下笔'],
  };

  static const Map<String, List<String>>
      _defaultImprovementOptionsByContentName = {
    '判断推理': ['重画关系', '总结题型', '对照解析补链路', '限时训练', '回看错题'],
    '资料分析': ['重背公式', '标数据点', '重算错题', '练速算', '限时训练'],
    '语言理解': ['划关键词', '总结错因', '对比选项', '分题型训练', '回看错题'],
    '常识判断': ['专题积累', '整理易混点', '重复记忆', '刷题巩固', '当天复盘'],
    '数量关系': ['背公式', '总结模型', '分题型训练', '练速算', '学会放弃'],
    '单词': ['重复记忆', '例句记忆', '词根词缀', '制作错词表', '当天复习'],
    '精听': ['重听', '对照文本', '查词', '精读句子', '跟读模仿'],
    '跟读': ['分句跟读', '慢速模仿', '录音对比', '重复朗读', '模仿重音节奏'],
    '阅读': ['精读句子', '查词', '画结构', '总结主旨', '回看错题'],
    '口语': ['复述', '句型替换', '录音复盘', '限时表达', '背表达'],
    '写作': ['改写句子', '背范文表达', '总结模板', '逐句修改', '重写'],
    '泛听': ['降低难度', '缩短材料', '先听主旨', '重复输入', '配合文本'],
    '练字': ['放慢写', '控制间距', '临摹', '分字练习', '保持坐姿握笔'],
    '摘抄': ['边抄边想', '标关键词', '摘录表达', '抄后复述', '控制时长'],
    '概括题': ['对答案补点', '提炼关键词', '练分层', '重写答案', '总结模板'],
    '对策题': ['结合材料补充', '看参考答案', '总结对策模板', '重写答案', '限时训练'],
    '公文题': ['记格式', '看范文', '重写答案', '总结模板', '强化审题'],
    '大作文': ['列提纲', '抄写范文', '积累论据', '重写段落', '限时训练'],
  };
}

class _PointsConfig {
  const _PointsConfig({
    required this.points,
  });

  final int points;
}

class _StudyTypeContentDefault {
  const _StudyTypeContentDefault({
    required this.categoryName,
    required this.points,
  });

  final String categoryName;
  final int points;
}

const Map<String, _StudyTypeContentDefault> _studyTypeContentDefaults = {
  '\u5224\u65ad\u63a8\u7406':
      _StudyTypeContentDefault(categoryName: '\u884c\u6d4b', points: 2),
  '\u8d44\u6599\u5206\u6790':
      _StudyTypeContentDefault(categoryName: '\u884c\u6d4b', points: 2),
  '\u8bed\u8a00\u7406\u89e3':
      _StudyTypeContentDefault(categoryName: '\u884c\u6d4b', points: 2),
  '\u5e38\u8bc6\u5224\u65ad':
      _StudyTypeContentDefault(categoryName: '\u884c\u6d4b', points: 1),
  '\u6570\u91cf\u5173\u7cfb':
      _StudyTypeContentDefault(categoryName: '\u884c\u6d4b', points: 2),
  '\u9519\u9898\u6574\u7406':
      _StudyTypeContentDefault(categoryName: '\u884c\u6d4b', points: 4),
  '\u7ec3\u5b57':
      _StudyTypeContentDefault(categoryName: '\u7533\u8bba', points: 1),
  '\u6458\u6284':
      _StudyTypeContentDefault(categoryName: '\u7533\u8bba', points: 1),
  '\u6982\u62ec\u9898':
      _StudyTypeContentDefault(categoryName: '\u7533\u8bba', points: 3),
  '\u5bf9\u7b56\u9898':
      _StudyTypeContentDefault(categoryName: '\u7533\u8bba', points: 3),
  '\u516c\u6587\u9898':
      _StudyTypeContentDefault(categoryName: '\u7533\u8bba', points: 3),
  '\u5927\u4f5c\u6587':
      _StudyTypeContentDefault(categoryName: '\u7533\u8bba', points: 3),
  '\u8868\u8fbe\u4fee\u6539':
      _StudyTypeContentDefault(categoryName: '\u7533\u8bba', points: 4),
  '\u5355\u8bcd':
      _StudyTypeContentDefault(categoryName: '\u82f1\u8bed', points: 1),
  '\u7cbe\u542c':
      _StudyTypeContentDefault(categoryName: '\u82f1\u8bed', points: 2),
  '\u8ddf\u8bfb':
      _StudyTypeContentDefault(categoryName: '\u82f1\u8bed', points: 2),
  '\u9605\u8bfb':
      _StudyTypeContentDefault(categoryName: '\u82f1\u8bed', points: 2),
  '\u53e3\u8bed':
      _StudyTypeContentDefault(categoryName: '\u82f1\u8bed', points: 3),
  '\u5199\u4f5c':
      _StudyTypeContentDefault(categoryName: '\u82f1\u8bed', points: 3),
  '\u6cdb\u542c':
      _StudyTypeContentDefault(categoryName: '\u82f1\u8bed', points: 1),
  '\u9519\u56e0\u590d\u76d8':
      _StudyTypeContentDefault(categoryName: '\u82f1\u8bed', points: 4),
};
