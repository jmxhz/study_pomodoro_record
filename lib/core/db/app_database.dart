import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../data/models/reward_rule.dart';

class AppDatabase {
  static const _databaseName = 'study_pomodoro_record.db';
  static const _databaseVersion = 3;

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
        if (oldVersion < 2) {
          await _createRewardRulesTable(db);
        }
        if (oldVersion < 3) {
          await _migrateToV3(db);
        }
      },
      onOpen: (db) async {
        await _seedFreshDefaultsIfNeeded(db);
        await _seedRewardRulesIfNeeded(db);
        await _seedV3DefaultsIfNeeded(db);
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
        default_points INTEGER NOT NULL DEFAULT 1,
        allow_adjust INTEGER NOT NULL DEFAULT 1,
        min_points INTEGER NOT NULL DEFAULT 1,
        max_points INTEGER NOT NULL DEFAULT 4,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE reward_options (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE study_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        occurred_at TEXT NOT NULL,
        category_id INTEGER,
        category_name_snapshot TEXT NOT NULL,
        content_option_id INTEGER,
        content_name_snapshot TEXT NOT NULL,
        reward_option_id INTEGER,
        reward_name_snapshot TEXT NOT NULL,
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

    await _createRewardRulesTable(db);
    await _createWeaknessOptionsTable(db);
    await _createImprovementOptionsTable(db);
    await _createRedeemRewardsTable(db);
    await _createRewardRedemptionRecordsTable(db);
  }

  Future<void> _createRewardRulesTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reward_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        period_type TEXT NOT NULL,
        threshold_points INTEGER NOT NULL,
        reward_text TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createWeaknessOptionsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS weakness_options (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category_id INTEGER,
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

  Future<void> _seedDefaultsIfNeeded(Database db) async {
    final categoryCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM categories'),
        ) ??
        0;
    final contentCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM content_options'),
        ) ??
        0;
    final rewardCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM reward_options'),
        ) ??
        0;

    if (categoryCount > 0 || contentCount > 0 || rewardCount > 0) {
      return;
    }

    final now = DateTime.now().toIso8601String();
    final categoryIds = <String, int>{};

    await db.transaction((txn) async {
      final defaultCategories = ['行测', '申论', '英语'];
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

      final defaultContents = <String, List<String>>{
        '行测': ['判断推理', '资料分析', '言语理解', '常识', '数量关系'],
        '申论': ['练字', '摘抄', '概括题', '对策题', '公文题', '大作文'],
        '英语': ['单词', '精听', '跟读', '阅读', '口语', '写作'],
      };

      var contentSortOrder = 0;
      for (final entry in defaultContents.entries) {
        for (final name in entry.value) {
          await txn.insert('content_options', {
            'name': name,
            'category_id': categoryIds[entry.key],
            'sort_order': contentSortOrder++,
            'is_enabled': 1,
            'created_at': now,
            'updated_at': now,
          });
        }
      }

      final defaultRewards = ['拉伸', '喝水', '散步', '听歌', '休息10分钟'];
      for (var index = 0; index < defaultRewards.length; index++) {
        await txn.insert('reward_options', {
          'name': defaultRewards[index],
          'sort_order': index,
          'is_enabled': 1,
          'created_at': now,
          'updated_at': now,
        });
      }
    });
  }

  Future<void> _seedFreshDefaultsIfNeeded(Database db) async {
    final categoryCount =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM categories')) ?? 0;
    final contentCount =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM content_options')) ?? 0;
    final rewardCount =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM reward_options')) ?? 0;

    if (categoryCount > 0 || contentCount > 0 || rewardCount > 0) {
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
        '行测': ['判断推理', '资料分析', '言语理解', '常识', '数量关系'],
        '申论': ['练字', '摘抄', '概括题', '对策题', '公文题', '大作文'],
        '英语': ['单词', '精听', '跟读', '阅读', '口语', '写作'],
      };

      var contentSortOrder = 0;
      for (final entry in defaultContents.entries) {
        for (final name in entry.value) {
          final pointsConfig = _defaultPointsConfig(name);
          await txn.insert('content_options', {
            'name': name,
            'category_id': categoryIds[entry.key],
            'sort_order': contentSortOrder++,
            'is_enabled': 1,
            'default_points': pointsConfig.defaultPoints,
            'allow_adjust': pointsConfig.allowAdjust ? 1 : 0,
            'min_points': pointsConfig.minPoints,
            'max_points': pointsConfig.maxPoints,
            'created_at': now,
            'updated_at': now,
          });
        }
      }

      const defaultFeedbackOptions = [
        '默认短休息',
        '拉伸',
        '喝水',
        '起身走动',
        '闭眼休息3分钟',
        '上厕所',
      ];
      for (var index = 0; index < defaultFeedbackOptions.length; index++) {
        await txn.insert('reward_options', {
          'name': defaultFeedbackOptions[index],
          'sort_order': index,
          'is_enabled': 1,
          'created_at': now,
          'updated_at': now,
        });
      }
    });
  }

  Future<void> _seedRewardRulesIfNeeded(Database db) async {
    final rewardRuleCount =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM reward_rules')) ?? 0;
    if (rewardRuleCount > 0) {
      return;
    }

    final now = DateTime.now().toIso8601String();
    final defaultRules = [
      (
        name: '今日达标',
        periodType: RewardRulePeriodType.day,
        thresholdPoints: 4,
        rewardText: '今日达标'
      ),
      (
        name: '今日不错',
        periodType: RewardRulePeriodType.day,
        thresholdPoints: 6,
        rewardText: '休息15分钟'
      ),
      (
        name: '今日优秀',
        periodType: RewardRulePeriodType.day,
        thresholdPoints: 8,
        rewardText: '听歌10分钟'
      ),
      (
        name: '每周小奖励',
        periodType: RewardRulePeriodType.week,
        thresholdPoints: 30,
        rewardText: '买饮料'
      ),
      (
        name: '每周大奖励',
        periodType: RewardRulePeriodType.week,
        thresholdPoints: 40,
        rewardText: '安排一次更舒服的放松'
      ),
      (
        name: '每月小奖励',
        periodType: RewardRulePeriodType.month,
        thresholdPoints: 120,
        rewardText: '小奖励'
      ),
      (
        name: '每月大奖励',
        periodType: RewardRulePeriodType.month,
        thresholdPoints: 150,
        rewardText: '大奖励'
      ),
    ];

    await db.transaction((txn) async {
      for (var index = 0; index < defaultRules.length; index++) {
        final item = defaultRules[index];
        await txn.insert('reward_rules', {
          'name': item.name,
          'period_type': item.periodType.dbValue,
          'threshold_points': item.thresholdPoints,
          'reward_text': item.rewardText,
          'sort_order': index,
          'is_enabled': 1,
          'created_at': now,
          'updated_at': now,
        });
      }
    });
  }

  Future<void> _migrateToV3(Database db) async {
    await db.execute(
      'ALTER TABLE content_options ADD COLUMN default_points INTEGER NOT NULL DEFAULT 1',
    );
    await db.execute(
      'ALTER TABLE content_options ADD COLUMN allow_adjust INTEGER NOT NULL DEFAULT 1',
    );
    await db.execute(
      'ALTER TABLE content_options ADD COLUMN min_points INTEGER NOT NULL DEFAULT 1',
    );
    await db.execute(
      'ALTER TABLE content_options ADD COLUMN max_points INTEGER NOT NULL DEFAULT 4',
    );

    await db.execute('ALTER TABLE study_records ADD COLUMN feedback_option_id INTEGER');
    await db.execute('ALTER TABLE study_records ADD COLUMN feedback_name_snapshot TEXT');
    await db.execute('ALTER TABLE study_records ADD COLUMN detail_amount_text TEXT');
    await db.execute('ALTER TABLE study_records ADD COLUMN question_count INTEGER');
    await db.execute('ALTER TABLE study_records ADD COLUMN wrong_count INTEGER');
    await db.execute('ALTER TABLE study_records ADD COLUMN output_type TEXT');
    await db.execute('ALTER TABLE study_records ADD COLUMN weakness_tags TEXT');
    await db.execute('ALTER TABLE study_records ADD COLUMN improvement_tags TEXT');
    await db.execute('ALTER TABLE study_records ADD COLUMN notes TEXT');

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

    await _createWeaknessOptionsTable(db);
    await _createImprovementOptionsTable(db);
    await _createRedeemRewardsTable(db);
    await _createRewardRedemptionRecordsTable(db);
    await _backfillContentPointConfig(db);
  }

  Future<void> _seedV3DefaultsIfNeeded(Database db) async {
    await _seedWeaknessOptionsIfNeeded(db);
    await _seedImprovementOptionsIfNeeded(db);
    await _seedRedeemRewardsIfNeeded(db);
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
          'default_points': config.defaultPoints,
          'allow_adjust': config.allowAdjust ? 1 : 0,
          'min_points': config.minPoints,
          'max_points': config.maxPoints,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> _seedWeaknessOptionsIfNeeded(Database db) async {
    final count =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM weakness_options')) ?? 0;
    if (count > 0) {
      return;
    }
    await _seedCategoryBoundOptions(
      db: db,
      table: 'weakness_options',
      optionsByCategoryName: const {
        '行测': ['审题不清', '速度慢', '公式不熟', '逻辑混乱', '粗心', '时间分配差', '知识点遗忘'],
        '申论': ['字迹不稳', '概括不准', '要点遗漏', '语言空泛', '逻辑不清', '结构松散', '无法下笔'],
        '英语': ['发音不准', '听不清', '词义不熟', '句子看不懂', '反应慢', '输出困难', '语法薄弱'],
      },
    );
  }

  Future<void> _seedImprovementOptionsIfNeeded(Database db) async {
    final count =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM improvement_options')) ?? 0;
    if (count > 0) {
      return;
    }
    await _seedCategoryBoundOptions(
      db: db,
      table: 'improvement_options',
      optionsByCategoryName: const {
        '行测': ['重做错题', '复盘笔记', '总结题型', '限时训练', '查漏补缺', '背公式', '看解析'],
        '申论': ['抄写范文', '重写答案', '提炼要点', '积累表达', '列提纲', '看参考答案', '限时训练'],
        '英语': ['重听', '跟读', '查词', '记笔记', '复述', '复习单词', '精读句子'],
      },
    );
  }

  Future<void> _seedRedeemRewardsIfNeeded(Database db) async {
    final count =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM redeem_rewards')) ?? 0;
    if (count > 0) {
      return;
    }
    final now = DateTime.now().toIso8601String();
    const defaults = [
      ('听歌10分钟', 6),
      ('看视频20分钟', 10),
      ('散步15分钟', 12),
      ('买饮料', 15),
      ('周末多休息半小时', 20),
    ];
    await db.transaction((txn) async {
      for (var index = 0; index < defaults.length; index++) {
        final item = defaults[index];
        await txn.insert('redeem_rewards', {
          'name': item.$1,
          'cost_points': item.$2,
          'sort_order': index,
          'is_enabled': 1,
          'note': null,
          'created_at': now,
          'updated_at': now,
        });
      }
    });
  }

  Future<void> _seedCategoryBoundOptions({
    required Database db,
    required String table,
    required Map<String, List<String>> optionsByCategoryName,
  }) async {
    final categories = await db.query('categories');
    final categoryIds = {
      for (final row in categories) row['name'] as String: row['id'] as int,
    };
    final now = DateTime.now().toIso8601String();
    var sortOrder = 0;
    await db.transaction((txn) async {
      for (final entry in optionsByCategoryName.entries) {
        final categoryId = categoryIds[entry.key];
        for (final name in entry.value) {
          await txn.insert(table, {
            'name': name,
            'category_id': categoryId,
            'sort_order': sortOrder++,
            'is_enabled': 1,
            'created_at': now,
            'updated_at': now,
          });
        }
      }
    });
  }

  _PointsConfig _defaultPointsConfig(String contentName) {
    switch (contentName) {
      case '判断推理':
        return const _PointsConfig(defaultPoints: 2, minPoints: 1, maxPoints: 3);
      case '资料分析':
        return const _PointsConfig(defaultPoints: 3, minPoints: 2, maxPoints: 4);
      case '言语理解':
        return const _PointsConfig(defaultPoints: 2, minPoints: 1, maxPoints: 3);
      case '常识':
        return const _PointsConfig(defaultPoints: 1, minPoints: 1, maxPoints: 2);
      case '数量关系':
        return const _PointsConfig(defaultPoints: 3, minPoints: 2, maxPoints: 4);
      case '练字':
        return const _PointsConfig(defaultPoints: 1, minPoints: 1, maxPoints: 2);
      case '摘抄':
        return const _PointsConfig(defaultPoints: 1, minPoints: 1, maxPoints: 2);
      case '概括题':
        return const _PointsConfig(defaultPoints: 2, minPoints: 1, maxPoints: 3);
      case '对策题':
      case '公文题':
        return const _PointsConfig(defaultPoints: 3, minPoints: 2, maxPoints: 4);
      case '大作文':
        return const _PointsConfig(defaultPoints: 4, minPoints: 3, maxPoints: 4);
      case '单词':
        return const _PointsConfig(defaultPoints: 1, minPoints: 1, maxPoints: 2);
      case '精听':
      case '跟读':
      case '阅读':
        return const _PointsConfig(defaultPoints: 2, minPoints: 1, maxPoints: 3);
      case '口语':
      case '写作':
        return const _PointsConfig(defaultPoints: 3, minPoints: 2, maxPoints: 4);
      default:
        return const _PointsConfig(defaultPoints: 1, minPoints: 1, maxPoints: 4);
    }
  }
}

class _PointsConfig {
  const _PointsConfig({
    required this.defaultPoints,
    required this.minPoints,
    required this.maxPoints,
    this.allowAdjust = true,
  });

  final int defaultPoints;
  final bool allowAdjust;
  final int minPoints;
  final int maxPoints;
}
