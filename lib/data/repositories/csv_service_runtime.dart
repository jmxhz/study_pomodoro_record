import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;

import '../models/category_option.dart';
import '../models/content_option.dart';
import '../models/improvement_option.dart';
import '../models/redeem_reward.dart';
import '../models/reward_option.dart';
import '../models/reward_redemption_record.dart';
import '../models/study_record.dart';
import '../models/weakness_option.dart';
import 'options_repository.dart';
import 'reward_redemption_repository.dart';
import 'study_record_repository.dart';

enum CsvImportMode { append, overwrite }

enum CsvDatasetType {
  categories,
  contentOptions,
  feedbackOptions,
  weaknessOptions,
  improvementOptions,
  redeemRewards,
  studyRecords,
  rewardRedemptionRecords,
}

class CsvExportResult {
  CsvExportResult({
    required this.directory,
    required this.files,
    required this.primaryFile,
  });

  final Directory directory;
  final List<File> files;
  final File primaryFile;
}

class CsvImportSummary {
  CsvImportSummary({
    required this.categories,
    required this.contentOptions,
    required this.feedbackOptions,
    required this.weaknessOptions,
    required this.improvementOptions,
    required this.redeemRewards,
    required this.studyRecords,
    required this.rewardRedemptionRecords,
  });

  final int categories;
  final int contentOptions;
  final int feedbackOptions;
  final int weaknessOptions;
  final int improvementOptions;
  final int redeemRewards;
  final int studyRecords;
  final int rewardRedemptionRecords;

  int get total =>
      categories +
      contentOptions +
      feedbackOptions +
      weaknessOptions +
      improvementOptions +
      redeemRewards +
      studyRecords +
      rewardRedemptionRecords;
}

class CsvImportBundle {
  CsvImportBundle({
    required this.categories,
    required this.contentOptions,
    required this.feedbackOptions,
    required this.weaknessOptions,
    required this.improvementOptions,
    required this.redeemRewards,
    required this.studyRecords,
    required this.rewardRedemptionRecords,
    required this.includedTypes,
  });

  final List<CategoryOption> categories;
  final List<ContentOption> contentOptions;
  final List<RewardOption> feedbackOptions;
  final List<WeaknessOption> weaknessOptions;
  final List<ImprovementOption> improvementOptions;
  final List<RedeemReward> redeemRewards;
  final List<StudyRecord> studyRecords;
  final List<RewardRedemptionRecord> rewardRedemptionRecords;
  final Set<CsvDatasetType> includedTypes;
}

abstract class CsvImportTarget {
  Future<void> replaceCategories(List<CategoryOption> items);

  Future<void> appendCategories(List<CategoryOption> items);

  Future<void> replaceContentOptions(List<ContentOption> items);

  Future<void> appendContentOptions(List<ContentOption> items);

  Future<void> replaceFeedbackOptions(List<RewardOption> items);

  Future<void> appendFeedbackOptions(List<RewardOption> items);

  Future<void> replaceWeaknessOptions(List<WeaknessOption> items);

  Future<void> appendWeaknessOptions(List<WeaknessOption> items);

  Future<void> replaceImprovementOptions(List<ImprovementOption> items);

  Future<void> appendImprovementOptions(List<ImprovementOption> items);

  Future<void> replaceRedeemRewards(List<RedeemReward> items);

  Future<void> appendRedeemRewards(List<RedeemReward> items);

  Future<void> replaceStudyRecords(List<StudyRecord> items);

  Future<void> appendStudyRecords(List<StudyRecord> items);

  Future<void> replaceRewardRedemptionRecords(
      List<RewardRedemptionRecord> items);

  Future<void> appendRewardRedemptionRecords(
      List<RewardRedemptionRecord> items);

  Future<void> replaceAppSettings(Map<String, String> items);

  Future<void> appendAppSettings(Map<String, String> items);

  Future<void> normalizeAfterImport();
}

class RepositoryCsvImportTarget implements CsvImportTarget {
  RepositoryCsvImportTarget({
    required this.optionsRepository,
    required this.studyRecordRepository,
    required this.rewardRedemptionRepository,
  });

  final OptionsRepository optionsRepository;
  final StudyRecordRepository studyRecordRepository;
  final RewardRedemptionRepository rewardRedemptionRepository;

  @override
  Future<void> appendCategories(List<CategoryOption> items) {
    return optionsRepository.appendCategories(items);
  }

  @override
  Future<void> appendContentOptions(List<ContentOption> items) {
    return optionsRepository.appendContentOptions(items);
  }

  @override
  Future<void> appendFeedbackOptions(List<RewardOption> items) {
    return optionsRepository.appendRewardOptions(items);
  }

  @override
  Future<void> appendImprovementOptions(List<ImprovementOption> items) {
    return optionsRepository.appendImprovementOptions(items);
  }

  @override
  Future<void> appendRedeemRewards(List<RedeemReward> items) {
    return optionsRepository.appendRedeemRewards(items);
  }

  @override
  Future<void> appendRewardRedemptionRecords(
      List<RewardRedemptionRecord> items) {
    return rewardRedemptionRepository.appendRecords(items);
  }

  @override
  Future<void> appendStudyRecords(List<StudyRecord> items) {
    return studyRecordRepository.appendRecords(items);
  }

  @override
  Future<void> appendWeaknessOptions(List<WeaknessOption> items) {
    return optionsRepository.appendWeaknessOptions(items);
  }

  @override
  Future<void> appendAppSettings(Map<String, String> items) {
    return optionsRepository.upsertAppSettings(items);
  }

  @override
  Future<void> normalizeAfterImport() {
    return optionsRepository.normalizeContentCategoryBindings();
  }

  @override
  Future<void> replaceCategories(List<CategoryOption> items) {
    return optionsRepository.replaceCategories(items);
  }

  @override
  Future<void> replaceContentOptions(List<ContentOption> items) {
    return optionsRepository.replaceContentOptions(items);
  }

  @override
  Future<void> replaceFeedbackOptions(List<RewardOption> items) {
    return optionsRepository.replaceRewardOptions(items);
  }

  @override
  Future<void> replaceImprovementOptions(List<ImprovementOption> items) {
    return optionsRepository.replaceImprovementOptions(items);
  }

  @override
  Future<void> replaceRedeemRewards(List<RedeemReward> items) {
    return optionsRepository.replaceRedeemRewards(items);
  }

  @override
  Future<void> replaceRewardRedemptionRecords(
      List<RewardRedemptionRecord> items) {
    return rewardRedemptionRepository.replaceRecords(items);
  }

  @override
  Future<void> replaceStudyRecords(List<StudyRecord> items) {
    return studyRecordRepository.replaceRecords(items);
  }

  @override
  Future<void> replaceWeaknessOptions(List<WeaknessOption> items) {
    return optionsRepository.replaceWeaknessOptions(items);
  }

  @override
  Future<void> replaceAppSettings(Map<String, String> items) {
    return optionsRepository.upsertAppSettings(items);
  }
}

class CsvService {
  CsvService({
    required OptionsRepository optionsRepository,
    required StudyRecordRepository studyRecordRepository,
    required RewardRedemptionRepository rewardRedemptionRepository,
  }) : this._(
          optionsRepository: optionsRepository,
          studyRecordRepository: studyRecordRepository,
          rewardRedemptionRepository: rewardRedemptionRepository,
          importTarget: RepositoryCsvImportTarget(
            optionsRepository: optionsRepository,
            studyRecordRepository: studyRecordRepository,
            rewardRedemptionRepository: rewardRedemptionRepository,
          ),
        );

  CsvService.forImport({
    required this.importTarget,
  })  : optionsRepository = null,
        studyRecordRepository = null,
        rewardRedemptionRepository = null;

  CsvService._({
    required this.importTarget,
    this.optionsRepository,
    this.studyRecordRepository,
    this.rewardRedemptionRepository,
  });

  final OptionsRepository? optionsRepository;
  final StudyRecordRepository? studyRecordRepository;
  final RewardRedemptionRepository? rewardRedemptionRepository;
  final CsvImportTarget importTarget;

  static const String categoriesFileName = 'categories.csv';
  static const String contentOptionsFileName = 'content_options.csv';
  static const String feedbackOptionsFileName = 'feedback_options.csv';
  static const String legacyRewardOptionsFileName = 'reward_options.csv';
  static const String weaknessOptionsFileName = 'weakness_options.csv';
  static const String improvementOptionsFileName = 'improvement_options.csv';
  static const String redeemRewardsFileName = 'redeem_rewards.csv';
  static const String studyRecordsFileName = 'study_records.csv';
  static const String rewardRedemptionRecordsFileName =
      'reward_redemption_records.csv';
  static const String autoBackupFileName = 'study_pomodoro_autobackup.json';
  static const String backupSchema = 'study_pomodoro_backup_v1';

  static const List<String> categoriesHeaders = [
    'id',
    'name',
    'sort_order',
    'is_enabled',
    'created_at',
    'updated_at',
  ];

  static const List<String> contentOptionsHeaders = [
    'id',
    'name',
    'category_id',
    'sort_order',
    'is_enabled',
    'points',
    'created_at',
    'updated_at',
  ];

  static const List<String> legacyContentOptionsHeaders = [
    'id',
    'name',
    'category_id',
    'sort_order',
    'is_enabled',
    'default_points',
    'allow_adjust',
    'min_points',
    'max_points',
    'created_at',
    'updated_at',
  ];

  static const List<String> feedbackOptionsHeaders = [
    'id',
    'name',
    'break_type',
    'sort_order',
    'is_enabled',
    'created_at',
    'updated_at',
  ];

  static const List<String> legacyFeedbackOptionsHeaders = [
    'id',
    'name',
    'sort_order',
    'is_enabled',
    'created_at',
    'updated_at',
  ];

  static const List<String> weaknessOptionsHeaders = [
    'id',
    'name',
    'category_id',
    'content_option_id',
    'sort_order',
    'is_enabled',
    'created_at',
    'updated_at',
  ];

  static const List<String> legacyWeaknessOptionsHeaders = [
    'id',
    'name',
    'category_id',
    'sort_order',
    'is_enabled',
    'created_at',
    'updated_at',
  ];

  static const List<String> improvementOptionsHeaders = [
    'id',
    'name',
    'category_id',
    'content_option_id',
    'sort_order',
    'is_enabled',
    'created_at',
    'updated_at',
  ];

  static const List<String> legacyImprovementOptionsHeaders = [
    'id',
    'name',
    'category_id',
    'sort_order',
    'is_enabled',
    'created_at',
    'updated_at',
  ];

  static const List<String> redeemRewardsHeaders = [
    'id',
    'name',
    'cost_points',
    'sort_order',
    'is_enabled',
    'note',
    'created_at',
    'updated_at',
  ];

  static const List<String> studyRecordsHeaders = [
    'id',
    'occurred_at',
    'category_id',
    'category_name_snapshot',
    'content_option_id',
    'content_name_snapshot',
    'reward_option_id',
    'reward_name_snapshot',
    'break_type',
    'feedback_option_id',
    'feedback_name_snapshot',
    'pomodoro_count',
    'points',
    'detail_amount_text',
    'question_count',
    'wrong_count',
    'output_type',
    'weakness_tags',
    'improvement_tags',
    'notes',
    'created_at',
    'updated_at',
  ];

  static const List<String> legacyStudyRecordsHeaders = [
    'id',
    'occurred_at',
    'category_id',
    'category_name_snapshot',
    'content_option_id',
    'content_name_snapshot',
    'reward_option_id',
    'reward_name_snapshot',
    'feedback_option_id',
    'feedback_name_snapshot',
    'pomodoro_count',
    'points',
    'detail_amount_text',
    'question_count',
    'wrong_count',
    'output_type',
    'weakness_tags',
    'improvement_tags',
    'notes',
    'created_at',
    'updated_at',
  ];

  static const List<String> rewardRedemptionRecordsHeaders = [
    'id',
    'reward_id',
    'reward_name_snapshot',
    'cost_points',
    'redeemed_at',
    'note',
    'created_at',
  ];

  Future<CsvExportResult> exportAllData({
    String? directoryPath,
    bool rememberDirectory = false,
    String? fileName,
  }) async {
    final resolvedDirectoryPath =
        directoryPath ?? await optionsRepository?.getBackupDirectoryPath();
    if (resolvedDirectoryPath == null || resolvedDirectoryPath.trim().isEmpty) {
      throw const FileSystemException('尚未设置备份文件夹，请先在设置页选择一次备份文件夹。');
    }
    if (rememberDirectory && optionsRepository != null) {
      await optionsRepository!.setBackupDirectoryPath(resolvedDirectoryPath);
    }

    final directory = Directory(resolvedDirectoryPath);
    await directory.create(recursive: true);
    final file = File(p.join(directory.path, fileName ?? autoBackupFileName));
    final payload = await buildBackupPayload();
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    return CsvExportResult(
      directory: directory,
      files: [file],
      primaryFile: file,
    );
  }

  Future<CsvExportResult?> exportAutoBackupIfConfigured() async {
    final directoryPath = await optionsRepository?.getBackupDirectoryPath();
    if (directoryPath == null || directoryPath.trim().isEmpty) {
      return null;
    }
    return exportAllData(directoryPath: directoryPath);
  }

  Future<CsvExportResult> exportManualSnapshot({
    required String directoryPath,
  }) {
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll('-', '')
        .replaceAll(':', '')
        .replaceAll('.', '')
        .replaceAll('T', '_');
    return exportAllData(
      directoryPath: directoryPath,
      fileName: 'study_pomodoro_export_$timestamp.json',
    );
  }

  Future<Map<String, Object?>> buildBackupPayload() async {
    final exportFiles = buildExportFiles(
      categories: await optionsRepository!.getCategories(),
      contentOptions: await optionsRepository!.getContentOptions(),
      feedbackOptions: await optionsRepository!.getRewardOptions(),
      weaknessOptions: await optionsRepository!.getWeaknessOptions(),
      improvementOptions: await optionsRepository!.getImprovementOptions(),
      redeemRewards: await optionsRepository!.getRedeemRewards(),
      studyRecords: await studyRecordRepository!.getAllRecords(),
      rewardRedemptionRecords:
          await rewardRedemptionRepository!.getAllRecords(),
    );
    final appSettings = await optionsRepository?.getBackupableAppSettings() ??
        const <String, String>{};
    return {
      'schema': backupSchema,
      'exported_at': DateTime.now().toIso8601String(),
      'app_settings': appSettings,
      'csv_datasets': exportFiles,
    };
  }

  Map<String, String> buildExportFiles({
    required List<CategoryOption> categories,
    required List<ContentOption> contentOptions,
    required List<RewardOption> feedbackOptions,
    required List<WeaknessOption> weaknessOptions,
    required List<ImprovementOption> improvementOptions,
    required List<RedeemReward> redeemRewards,
    required List<StudyRecord> studyRecords,
    required List<RewardRedemptionRecord> rewardRedemptionRecords,
  }) {
    return {
      categoriesFileName: _encodeCsv(
        categoriesHeaders,
        categories
            .map(
              (item) => [
                item.id,
                item.name,
                item.sortOrder,
                item.isEnabled ? 1 : 0,
                item.createdAt.toIso8601String(),
                item.updatedAt.toIso8601String(),
              ],
            )
            .toList(growable: false),
      ),
      contentOptionsFileName: _encodeCsv(
        contentOptionsHeaders,
        contentOptions
            .map(
              (item) => [
                item.id,
                item.name,
                item.categoryId ?? '',
                item.sortOrder,
                item.isEnabled ? 1 : 0,
                item.points,
                item.createdAt.toIso8601String(),
                item.updatedAt.toIso8601String(),
              ],
            )
            .toList(growable: false),
      ),
      feedbackOptionsFileName: _encodeCsv(
        feedbackOptionsHeaders,
        feedbackOptions
            .map(
              (item) => [
                item.id,
                item.name,
                item.type,
                item.sortOrder,
                item.isEnabled ? 1 : 0,
                item.createdAt.toIso8601String(),
                item.updatedAt.toIso8601String(),
              ],
            )
            .toList(growable: false),
      ),
      weaknessOptionsFileName: _encodeCsv(
        weaknessOptionsHeaders,
        weaknessOptions
            .map(
              (item) => [
                item.id,
                item.name,
                item.categoryId ?? '',
                item.contentOptionId ?? '',
                item.sortOrder,
                item.isEnabled ? 1 : 0,
                item.createdAt.toIso8601String(),
                item.updatedAt.toIso8601String(),
              ],
            )
            .toList(growable: false),
      ),
      improvementOptionsFileName: _encodeCsv(
        improvementOptionsHeaders,
        improvementOptions
            .map(
              (item) => [
                item.id,
                item.name,
                item.categoryId ?? '',
                item.contentOptionId ?? '',
                item.sortOrder,
                item.isEnabled ? 1 : 0,
                item.createdAt.toIso8601String(),
                item.updatedAt.toIso8601String(),
              ],
            )
            .toList(growable: false),
      ),
      redeemRewardsFileName: _encodeCsv(
        redeemRewardsHeaders,
        redeemRewards
            .map(
              (item) => [
                item.id,
                item.name,
                item.costPoints,
                item.sortOrder,
                item.isEnabled ? 1 : 0,
                item.note ?? '',
                item.createdAt.toIso8601String(),
                item.updatedAt.toIso8601String(),
              ],
            )
            .toList(growable: false),
      ),
      studyRecordsFileName: _encodeCsv(
        studyRecordsHeaders,
        studyRecords
            .map(
              (item) => [
                item.id,
                item.occurredAt.toIso8601String(),
                item.categoryId ?? '',
                item.categoryNameSnapshot,
                item.contentOptionId ?? '',
                item.contentNameSnapshot,
                item.rewardOptionId ?? '',
                item.rewardNameSnapshot,
                item.breakType ?? '',
                item.feedbackOptionId ?? '',
                item.feedbackNameSnapshot ?? '',
                item.pomodoroCount,
                item.points,
                item.detailAmountText ?? '',
                item.questionCount ?? '',
                item.wrongCount ?? '',
                item.outputType ?? '',
                jsonEncode(item.weaknessTags),
                jsonEncode(item.improvementTags),
                item.notes ?? '',
                item.createdAt.toIso8601String(),
                item.updatedAt.toIso8601String(),
              ],
            )
            .toList(growable: false),
      ),
      rewardRedemptionRecordsFileName: _encodeCsv(
        rewardRedemptionRecordsHeaders,
        rewardRedemptionRecords
            .map(
              (item) => [
                item.id,
                item.rewardId ?? '',
                item.rewardNameSnapshot,
                item.costPoints,
                item.redeemedAt.toIso8601String(),
                item.note ?? '',
                item.createdAt.toIso8601String(),
              ],
            )
            .toList(growable: false),
      ),
    };
  }

  Future<CsvImportSummary> importFromPaths(
    List<String> paths,
    CsvImportMode mode,
  ) async {
    if (paths.isEmpty) {
      throw const FormatException('请至少选择一个备份文件。');
    }

    if (paths.length == 1 && _isBackupJsonPath(paths.first)) {
      final file = File(paths.first);
      final content = utf8.decode(await file.readAsBytes());
      return importFromBackupContent(content, mode);
    }

    final fileContents = <String, String>{};
    for (final path in paths) {
      final file = File(path);
      final bytes = await file.readAsBytes();
      fileContents[p.basename(path).toLowerCase()] = utf8.decode(bytes);
    }

    return importFromFileContents(fileContents, mode);
  }

  Future<CsvImportSummary> importFromFileContents(
    Map<String, String> fileContents,
    CsvImportMode mode,
  ) async {
    final bundle = parseFiles(fileContents);
    if (bundle.includedTypes.isEmpty) {
      throw const FormatException('未检测到可导入的 CSV 文件。');
    }

    if (bundle.includedTypes.contains(CsvDatasetType.categories)) {
      if (mode == CsvImportMode.overwrite) {
        await importTarget.replaceCategories(bundle.categories);
      } else {
        await importTarget.appendCategories(bundle.categories);
      }
    }

    if (bundle.includedTypes.contains(CsvDatasetType.contentOptions)) {
      if (mode == CsvImportMode.overwrite) {
        await importTarget.replaceContentOptions(bundle.contentOptions);
      } else {
        await importTarget.appendContentOptions(bundle.contentOptions);
      }
    }

    if (bundle.includedTypes.contains(CsvDatasetType.feedbackOptions)) {
      if (mode == CsvImportMode.overwrite) {
        await importTarget.replaceFeedbackOptions(bundle.feedbackOptions);
      } else {
        await importTarget.appendFeedbackOptions(bundle.feedbackOptions);
      }
    }

    if (bundle.includedTypes.contains(CsvDatasetType.weaknessOptions)) {
      if (mode == CsvImportMode.overwrite) {
        await importTarget.replaceWeaknessOptions(bundle.weaknessOptions);
      } else {
        await importTarget.appendWeaknessOptions(bundle.weaknessOptions);
      }
    }

    if (bundle.includedTypes.contains(CsvDatasetType.improvementOptions)) {
      if (mode == CsvImportMode.overwrite) {
        await importTarget.replaceImprovementOptions(bundle.improvementOptions);
      } else {
        await importTarget.appendImprovementOptions(bundle.improvementOptions);
      }
    }

    if (bundle.includedTypes.contains(CsvDatasetType.redeemRewards)) {
      if (mode == CsvImportMode.overwrite) {
        await importTarget.replaceRedeemRewards(bundle.redeemRewards);
      } else {
        await importTarget.appendRedeemRewards(bundle.redeemRewards);
      }
    }

    if (bundle.includedTypes.contains(CsvDatasetType.studyRecords)) {
      if (mode == CsvImportMode.overwrite) {
        await importTarget.replaceStudyRecords(bundle.studyRecords);
      } else {
        await importTarget.appendStudyRecords(bundle.studyRecords);
      }
    }

    if (bundle.includedTypes.contains(CsvDatasetType.rewardRedemptionRecords)) {
      if (mode == CsvImportMode.overwrite) {
        await importTarget
            .replaceRewardRedemptionRecords(bundle.rewardRedemptionRecords);
      } else {
        await importTarget
            .appendRewardRedemptionRecords(bundle.rewardRedemptionRecords);
      }
    }

    await importTarget.normalizeAfterImport();

    return CsvImportSummary(
      categories: bundle.categories.length,
      contentOptions: bundle.contentOptions.length,
      feedbackOptions: bundle.feedbackOptions.length,
      weaknessOptions: bundle.weaknessOptions.length,
      improvementOptions: bundle.improvementOptions.length,
      redeemRewards: bundle.redeemRewards.length,
      studyRecords: bundle.studyRecords.length,
      rewardRedemptionRecords: bundle.rewardRedemptionRecords.length,
    );
  }

  Future<CsvImportSummary> importFromBackupContent(
    String content,
    CsvImportMode mode,
  ) async {
    final decoded = jsonDecode(content);
    if (decoded is! Map) {
      throw const FormatException('备份文件格式不正确。');
    }
    final root = Map<String, Object?>.from(decoded.cast<String, Object?>());
    if ((root['schema'] as String?) != backupSchema) {
      throw const FormatException('不支持的备份文件版本。');
    }

    final appSettings = _parseAppSettings(root['app_settings']);
    final csvDatasets = _parseCsvDatasets(root['csv_datasets']);
    final summary = await importFromFileContents(csvDatasets, mode);
    if (mode == CsvImportMode.overwrite) {
      await importTarget.replaceAppSettings(appSettings);
    } else {
      await importTarget.appendAppSettings(appSettings);
    }
    return summary;
  }

  CsvImportBundle parseFiles(Map<String, String> fileContents) {
    final categories = <CategoryOption>[];
    final contentOptions = <ContentOption>[];
    final feedbackOptions = <RewardOption>[];
    final weaknessOptions = <WeaknessOption>[];
    final improvementOptions = <ImprovementOption>[];
    final redeemRewards = <RedeemReward>[];
    final studyRecords = <StudyRecord>[];
    final rewardRedemptionRecords = <RewardRedemptionRecord>[];
    final includedTypes = <CsvDatasetType>{};

    for (final entry in fileContents.entries) {
      switch (entry.key.toLowerCase()) {
        case categoriesFileName:
          categories.addAll(_parseCategories(entry.value));
          includedTypes.add(CsvDatasetType.categories);
          break;
        case contentOptionsFileName:
          contentOptions.addAll(_parseContentOptions(entry.value));
          includedTypes.add(CsvDatasetType.contentOptions);
          break;
        case feedbackOptionsFileName:
        case legacyRewardOptionsFileName:
          feedbackOptions.addAll(_parseFeedbackOptions(entry.value));
          includedTypes.add(CsvDatasetType.feedbackOptions);
          break;
        case weaknessOptionsFileName:
          weaknessOptions.addAll(_parseWeaknessOptions(entry.value));
          includedTypes.add(CsvDatasetType.weaknessOptions);
          break;
        case improvementOptionsFileName:
          improvementOptions.addAll(_parseImprovementOptions(entry.value));
          includedTypes.add(CsvDatasetType.improvementOptions);
          break;
        case redeemRewardsFileName:
          redeemRewards.addAll(_parseRedeemRewards(entry.value));
          includedTypes.add(CsvDatasetType.redeemRewards);
          break;
        case studyRecordsFileName:
          studyRecords.addAll(_parseStudyRecords(entry.value));
          includedTypes.add(CsvDatasetType.studyRecords);
          break;
        case rewardRedemptionRecordsFileName:
          rewardRedemptionRecords
              .addAll(_parseRewardRedemptionRecords(entry.value));
          includedTypes.add(CsvDatasetType.rewardRedemptionRecords);
          break;
        default:
          throw FormatException('不支持的 CSV 文件：${entry.key}');
      }
    }

    return CsvImportBundle(
      categories: categories,
      contentOptions: contentOptions,
      feedbackOptions: feedbackOptions,
      weaknessOptions: weaknessOptions,
      improvementOptions: improvementOptions,
      redeemRewards: redeemRewards,
      studyRecords: studyRecords,
      rewardRedemptionRecords: rewardRedemptionRecords,
      includedTypes: includedTypes,
    );
  }

  bool _isBackupJsonPath(String path) =>
      p.extension(path).toLowerCase() == '.json';

  Map<String, String> _parseAppSettings(Object? raw) {
    if (raw is! Map) {
      return const {};
    }
    final result = <String, String>{};
    for (final entry in raw.entries) {
      final key = entry.key.toString();
      final value = entry.value?.toString() ?? '';
      if (key.trim().isEmpty) {
        continue;
      }
      result[key] = value;
    }
    return result;
  }

  Map<String, String> _parseCsvDatasets(Object? raw) {
    if (raw is! Map) {
      throw const FormatException('备份文件中缺少数据内容。');
    }
    final result = <String, String>{};
    for (final entry in raw.entries) {
      result[entry.key.toString().toLowerCase()] =
          entry.value?.toString() ?? '';
    }
    return result;
  }

  List<CategoryOption> _parseCategories(String content) {
    final rows = _decodeCsv(content, categoriesHeaders);
    return rows
        .map(
          (row) => CategoryOption(
            id: _parseNullableInt(row[0]),
            name: _requireText(row[1], 'name'),
            sortOrder: _parseRequiredInt(row[2], 'sort_order'),
            isEnabled: _parseBool(row[3], 'is_enabled'),
            createdAt: _parseDateTime(row[4], 'created_at'),
            updatedAt: _parseDateTime(row[5], 'updated_at'),
          ),
        )
        .toList(growable: false);
  }

  List<ContentOption> _parseContentOptions(String content) {
    final decoded = _decodeCsvWithHeaders(content, [
      contentOptionsHeaders,
      legacyContentOptionsHeaders,
    ]);
    final rows = decoded.rows;
    return rows
        .map(
          (row) => ContentOption(
            id: _parseNullableInt(row[0]),
            name: _requireText(row[1], 'name'),
            categoryId: _parseNullableInt(row[2]),
            sortOrder: _parseRequiredInt(row[3], 'sort_order'),
            isEnabled: _parseBool(row[4], 'is_enabled'),
            points: decoded.headers == contentOptionsHeaders
                ? _parseRequiredInt(row[5], 'points')
                : _parseRequiredInt(row[5], 'default_points'),
            defaultPoints: decoded.headers == contentOptionsHeaders
                ? _parseRequiredInt(row[5], 'points')
                : _parseRequiredInt(row[5], 'default_points'),
            allowAdjust: false,
            minPoints: decoded.headers == contentOptionsHeaders
                ? _parseRequiredInt(row[5], 'points')
                : _parseRequiredInt(row[5], 'default_points'),
            maxPoints: decoded.headers == contentOptionsHeaders
                ? _parseRequiredInt(row[5], 'points')
                : _parseRequiredInt(row[5], 'default_points'),
            createdAt: _parseDateTime(
              row[decoded.headers == contentOptionsHeaders ? 6 : 9],
              'created_at',
            ),
            updatedAt: _parseDateTime(
              row[decoded.headers == contentOptionsHeaders ? 7 : 10],
              'updated_at',
            ),
          ),
        )
        .toList(growable: false);
  }

  List<RewardOption> _parseFeedbackOptions(String content) {
    final decoded = _decodeCsvWithHeaders(content, [
      feedbackOptionsHeaders,
      legacyFeedbackOptionsHeaders,
    ]);
    final rows = decoded.rows;
    return rows
        .map(
          (row) => RewardOption(
            id: _parseNullableInt(row[0]),
            name: _requireText(row[1], 'name'),
            type: decoded.headers == feedbackOptionsHeaders
                ? _requireText(row[2], 'break_type')
                : 'short',
            sortOrder: _parseRequiredInt(
              row[decoded.headers == feedbackOptionsHeaders ? 3 : 2],
              'sort_order',
            ),
            isEnabled: _parseBool(
              row[decoded.headers == feedbackOptionsHeaders ? 4 : 3],
              'is_enabled',
            ),
            createdAt: _parseDateTime(
              row[decoded.headers == feedbackOptionsHeaders ? 5 : 4],
              'created_at',
            ),
            updatedAt: _parseDateTime(
              row[decoded.headers == feedbackOptionsHeaders ? 6 : 5],
              'updated_at',
            ),
          ),
        )
        .toList(growable: false);
  }

  List<WeaknessOption> _parseWeaknessOptions(String content) {
    final decoded = _decodeCsvWithHeaders(content, [
      weaknessOptionsHeaders,
      legacyWeaknessOptionsHeaders,
    ]);
    final rows = decoded.rows;
    return rows
        .map(
          (row) => WeaknessOption(
            id: _parseNullableInt(row[0]),
            name: _requireText(row[1], 'name'),
            categoryId: _parseNullableInt(row[2]),
            contentOptionId: decoded.headers == weaknessOptionsHeaders
                ? _parseNullableInt(row[3])
                : null,
            sortOrder: _parseRequiredInt(
              row[decoded.headers == weaknessOptionsHeaders ? 4 : 3],
              'sort_order',
            ),
            isEnabled: _parseBool(
              row[decoded.headers == weaknessOptionsHeaders ? 5 : 4],
              'is_enabled',
            ),
            createdAt: _parseDateTime(
              row[decoded.headers == weaknessOptionsHeaders ? 6 : 5],
              'created_at',
            ),
            updatedAt: _parseDateTime(
              row[decoded.headers == weaknessOptionsHeaders ? 7 : 6],
              'updated_at',
            ),
          ),
        )
        .toList(growable: false);
  }

  List<ImprovementOption> _parseImprovementOptions(String content) {
    final decoded = _decodeCsvWithHeaders(content, [
      improvementOptionsHeaders,
      legacyImprovementOptionsHeaders,
    ]);
    final rows = decoded.rows;
    return rows
        .map(
          (row) => ImprovementOption(
            id: _parseNullableInt(row[0]),
            name: _requireText(row[1], 'name'),
            categoryId: _parseNullableInt(row[2]),
            contentOptionId: decoded.headers == improvementOptionsHeaders
                ? _parseNullableInt(row[3])
                : null,
            sortOrder: _parseRequiredInt(
              row[decoded.headers == improvementOptionsHeaders ? 4 : 3],
              'sort_order',
            ),
            isEnabled: _parseBool(
              row[decoded.headers == improvementOptionsHeaders ? 5 : 4],
              'is_enabled',
            ),
            createdAt: _parseDateTime(
              row[decoded.headers == improvementOptionsHeaders ? 6 : 5],
              'created_at',
            ),
            updatedAt: _parseDateTime(
              row[decoded.headers == improvementOptionsHeaders ? 7 : 6],
              'updated_at',
            ),
          ),
        )
        .toList(growable: false);
  }

  List<RedeemReward> _parseRedeemRewards(String content) {
    final rows = _decodeCsv(content, redeemRewardsHeaders);
    return rows
        .map(
          (row) => RedeemReward(
            id: _parseNullableInt(row[0]),
            name: _requireText(row[1], 'name'),
            costPoints: _parseRequiredInt(row[2], 'cost_points'),
            sortOrder: _parseRequiredInt(row[3], 'sort_order'),
            isEnabled: _parseBool(row[4], 'is_enabled'),
            note: _parseNullableText(row[5]),
            createdAt: _parseDateTime(row[6], 'created_at'),
            updatedAt: _parseDateTime(row[7], 'updated_at'),
          ),
        )
        .toList(growable: false);
  }

  List<StudyRecord> _parseStudyRecords(String content) {
    final decoded = _decodeCsvWithHeaders(content, [
      studyRecordsHeaders,
      legacyStudyRecordsHeaders,
    ]);
    final rows = decoded.rows;
    return rows
        .map(
          (row) => StudyRecord(
            id: _parseNullableInt(row[0]),
            occurredAt: _parseDateTime(row[1], 'occurred_at'),
            categoryId: _parseNullableInt(row[2]),
            categoryNameSnapshot:
                _requireText(row[3], 'category_name_snapshot'),
            contentOptionId: _parseNullableInt(row[4]),
            contentNameSnapshot: _requireText(row[5], 'content_name_snapshot'),
            rewardOptionId: _parseNullableInt(row[6]),
            rewardNameSnapshot: _requireText(row[7], 'reward_name_snapshot'),
            breakType: decoded.headers == studyRecordsHeaders
                ? _parseNullableText(row[8])
                : null,
            feedbackOptionId: _parseNullableInt(
              row[decoded.headers == studyRecordsHeaders ? 9 : 8],
            ),
            feedbackNameSnapshot: _parseNullableText(
              row[decoded.headers == studyRecordsHeaders ? 10 : 9],
            ),
            pomodoroCount: _parseRequiredInt(
              row[decoded.headers == studyRecordsHeaders ? 11 : 10],
              'pomodoro_count',
            ),
            points: _parseRequiredInt(
              row[decoded.headers == studyRecordsHeaders ? 12 : 11],
              'points',
            ),
            detailAmountText: _parseNullableText(
              row[decoded.headers == studyRecordsHeaders ? 13 : 12],
            ),
            questionCount: _parseNullableInt(
              row[decoded.headers == studyRecordsHeaders ? 14 : 13],
            ),
            wrongCount: _parseNullableInt(
              row[decoded.headers == studyRecordsHeaders ? 15 : 14],
            ),
            outputType: _parseNullableText(
              row[decoded.headers == studyRecordsHeaders ? 16 : 15],
            ),
            weaknessTags: _parseTagList(
              row[decoded.headers == studyRecordsHeaders ? 17 : 16],
            ),
            improvementTags: _parseTagList(
              row[decoded.headers == studyRecordsHeaders ? 18 : 17],
            ),
            notes: _parseNullableText(
              row[decoded.headers == studyRecordsHeaders ? 19 : 18],
            ),
            createdAt: _parseDateTime(
              row[decoded.headers == studyRecordsHeaders ? 20 : 19],
              'created_at',
            ),
            updatedAt: _parseDateTime(
              row[decoded.headers == studyRecordsHeaders ? 21 : 20],
              'updated_at',
            ),
          ),
        )
        .toList(growable: false);
  }

  List<RewardRedemptionRecord> _parseRewardRedemptionRecords(String content) {
    final rows = _decodeCsv(content, rewardRedemptionRecordsHeaders);
    return rows
        .map(
          (row) => RewardRedemptionRecord(
            id: _parseNullableInt(row[0]),
            rewardId: _parseNullableInt(row[1]),
            rewardNameSnapshot: _requireText(row[2], 'reward_name_snapshot'),
            costPoints: _parseRequiredInt(row[3], 'cost_points'),
            redeemedAt: _parseDateTime(row[4], 'redeemed_at'),
            note: _parseNullableText(row[5]),
            createdAt: _parseDateTime(row[6], 'created_at'),
          ),
        )
        .toList(growable: false);
  }

  List<List<dynamic>> _decodeCsv(String content, List<String> expectedHeaders) {
    return _decodeCsvWithHeaders(content, [expectedHeaders]).rows;
  }

  _DecodedCsv _decodeCsvWithHeaders(
    String content,
    List<List<String>> acceptedHeaders,
  ) {
    final normalized = content.replaceFirst('\uFEFF', '');
    final rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(normalized);

    if (rows.isEmpty) {
      throw const FormatException('CSV 文件为空。');
    }

    final actualHeaders = rows.first
        .map((cell) => cell.toString().trim().replaceFirst('\uFEFF', ''))
        .toList(growable: false);

    final matchedHeaders = acceptedHeaders.firstWhere(
      (headers) => _headersMatch(actualHeaders, headers),
      orElse: () => <String>[],
    );

    if (matchedHeaders.isEmpty) {
      throw FormatException(
        'CSV 表头不匹配。实际：${actualHeaders.join(', ')}',
      );
    }

    return _DecodedCsv(
      headers: matchedHeaders,
      rows: rows
          .skip(1)
          .where((row) => row.any((cell) => cell.toString().trim().isNotEmpty))
          .toList(growable: false),
    );
  }

  bool _headersMatch(List<String> actual, List<String> expected) {
    if (actual.length != expected.length) {
      return false;
    }
    for (var index = 0; index < actual.length; index++) {
      if (actual[index] != expected[index]) {
        return false;
      }
    }
    return true;
  }

  String _encodeCsv(List<String> headers, List<List<Object?>> rows) {
    return const ListToCsvConverter(eol: '\n').convert([
      headers,
      ...rows,
    ]);
  }

  int? _parseNullableInt(Object? value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    return int.parse(text);
  }

  int _parseRequiredInt(Object? value, String fieldName) {
    final parsed = _parseNullableInt(value);
    if (parsed == null) {
      throw FormatException('字段 $fieldName 不能为空。');
    }
    return parsed;
  }

  bool _parseBool(Object? value, String fieldName) {
    final text = value?.toString().trim().toLowerCase() ?? '';
    if (text == '1' || text == 'true') {
      return true;
    }
    if (text == '0' || text == 'false') {
      return false;
    }
    throw FormatException('字段 $fieldName 只能是 0/1/true/false。');
  }

  DateTime _parseDateTime(Object? value, String fieldName) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) {
      throw FormatException('字段 $fieldName 不能为空。');
    }
    return DateTime.parse(text);
  }

  String _requireText(Object? value, String fieldName) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) {
      throw FormatException('字段 $fieldName 不能为空。');
    }
    return text;
  }

  String? _parseNullableText(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  List<String> _parseTagList(Object? value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(text);
      if (decoded is List) {
        return decoded
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false);
      }
    } catch (_) {
      return text
          .split('\u0001')
          .expand((item) => item.split('|'))
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }

    return const [];
  }
}

class _DecodedCsv {
  const _DecodedCsv({
    required this.headers,
    required this.rows,
  });

  final List<String> headers;
  final List<List<dynamic>> rows;
}
