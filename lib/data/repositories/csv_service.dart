import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/category_option.dart';
import '../models/content_option.dart';
import '../models/reward_rule.dart';
import '../models/reward_option.dart';
import '../models/study_record.dart';
import 'options_repository.dart';
import 'study_record_repository.dart';

enum CsvImportMode { append, overwrite }

enum CsvDatasetType {
  categories,
  contentOptions,
  rewardOptions,
  rewardRules,
  studyRecords,
}

class CsvExportResult {
  CsvExportResult({
    required this.directory,
    required this.files,
  });

  final Directory directory;
  final List<File> files;
}

class CsvImportSummary {
  CsvImportSummary({
    required this.categories,
    required this.contentOptions,
    required this.rewardOptions,
    required this.rewardRules,
    required this.studyRecords,
  });

  final int categories;
  final int contentOptions;
  final int rewardOptions;
  final int rewardRules;
  final int studyRecords;

  int get total =>
      categories + contentOptions + rewardOptions + rewardRules + studyRecords;
}

class CsvImportBundle {
  CsvImportBundle({
    required this.categories,
    required this.contentOptions,
    required this.rewardOptions,
    required this.rewardRules,
    required this.studyRecords,
    required this.includedTypes,
  });

  final List<CategoryOption> categories;
  final List<ContentOption> contentOptions;
  final List<RewardOption> rewardOptions;
  final List<RewardRule> rewardRules;
  final List<StudyRecord> studyRecords;
  final Set<CsvDatasetType> includedTypes;
}

abstract class CsvImportTarget {
  Future<void> replaceCategories(List<CategoryOption> items);

  Future<void> appendCategories(List<CategoryOption> items);

  Future<void> replaceContentOptions(List<ContentOption> items);

  Future<void> appendContentOptions(List<ContentOption> items);

  Future<void> replaceRewardOptions(List<RewardOption> items);

  Future<void> appendRewardOptions(List<RewardOption> items);

  Future<void> replaceRewardRules(List<RewardRule> items);

  Future<void> appendRewardRules(List<RewardRule> items);

  Future<void> replaceStudyRecords(List<StudyRecord> items);

  Future<void> appendStudyRecords(List<StudyRecord> items);

  Future<void> normalizeAfterImport();
}

class RepositoryCsvImportTarget implements CsvImportTarget {
  RepositoryCsvImportTarget({
    required this.optionsRepository,
    required this.studyRecordRepository,
  });

  final OptionsRepository optionsRepository;
  final StudyRecordRepository studyRecordRepository;

  @override
  Future<void> appendCategories(List<CategoryOption> items) {
    return optionsRepository.appendCategories(items);
  }

  @override
  Future<void> appendContentOptions(List<ContentOption> items) {
    return optionsRepository.appendContentOptions(items);
  }

  @override
  Future<void> appendRewardOptions(List<RewardOption> items) {
    return optionsRepository.appendRewardOptions(items);
  }

  @override
  Future<void> appendRewardRules(List<RewardRule> items) {
    return optionsRepository.appendRewardRules(items);
  }

  @override
  Future<void> appendStudyRecords(List<StudyRecord> items) {
    return studyRecordRepository.appendRecords(items);
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
  Future<void> replaceRewardOptions(List<RewardOption> items) {
    return optionsRepository.replaceRewardOptions(items);
  }

  @override
  Future<void> replaceRewardRules(List<RewardRule> items) {
    return optionsRepository.replaceRewardRules(items);
  }

  @override
  Future<void> replaceStudyRecords(List<StudyRecord> items) {
    return studyRecordRepository.replaceRecords(items);
  }
}

class CsvService {
  CsvService({
    required OptionsRepository optionsRepository,
    required StudyRecordRepository studyRecordRepository,
  }) : this._(
         optionsRepository: optionsRepository,
         studyRecordRepository: studyRecordRepository,
         importTarget: RepositoryCsvImportTarget(
           optionsRepository: optionsRepository,
           studyRecordRepository: studyRecordRepository,
         ),
       );

  CsvService.forImport({
    required this.importTarget,
  }) : optionsRepository = null,
       studyRecordRepository = null;

  CsvService._({
    this.optionsRepository,
    this.studyRecordRepository,
    required this.importTarget,
  });

  final OptionsRepository? optionsRepository;
  final StudyRecordRepository? studyRecordRepository;
  final CsvImportTarget importTarget;

  static const String categoriesFileName = 'categories.csv';
  static const String contentOptionsFileName = 'content_options.csv';
  static const String rewardOptionsFileName = 'reward_options.csv';
  static const String rewardRulesFileName = 'reward_rules.csv';
  static const String studyRecordsFileName = 'study_records.csv';

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
    'created_at',
    'updated_at',
  ];

  static const List<String> rewardOptionsHeaders = [
    'id',
    'name',
    'sort_order',
    'is_enabled',
    'created_at',
    'updated_at',
  ];

  static const List<String> rewardRulesHeaders = [
    'id',
    'name',
    'period_type',
    'threshold_points',
    'reward_text',
    'sort_order',
    'is_enabled',
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
    'pomodoro_count',
    'points',
    'created_at',
    'updated_at',
  ];

  Future<CsvExportResult> exportAllData() async {
    final categories = await optionsRepository!.getCategories();
    final contentOptions = await optionsRepository!.getContentOptions();
    final rewardOptions = await optionsRepository!.getRewardOptions();
    final rewardRules = await optionsRepository!.getRewardRules();
    final studyRecords = await studyRecordRepository!.getAllRecords();

    final exportFiles = buildExportFiles(
      categories: categories,
      contentOptions: contentOptions,
      rewardOptions: rewardOptions,
      rewardRules: rewardRules,
      studyRecords: studyRecords,
    );

    final rootDirectory =
        await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    final timestamp =
        DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
    final directory = Directory(
      p.join(rootDirectory.path, 'exports', 'study_export_$timestamp'),
    );
    await directory.create(recursive: true);

    final writtenFiles = <File>[];
    for (final entry in exportFiles.entries) {
      final file = File(p.join(directory.path, entry.key));
      await file.writeAsBytes(utf8.encode('\uFEFF${entry.value}'));
      writtenFiles.add(file);
    }
    return CsvExportResult(directory: directory, files: writtenFiles);
  }

  Map<String, String> buildExportFiles({
    required List<CategoryOption> categories,
    required List<ContentOption> contentOptions,
    required List<RewardOption> rewardOptions,
    required List<RewardRule> rewardRules,
    required List<StudyRecord> studyRecords,
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
                item.createdAt.toIso8601String(),
                item.updatedAt.toIso8601String(),
              ],
            )
            .toList(growable: false),
      ),
      rewardOptionsFileName: _encodeCsv(
        rewardOptionsHeaders,
        rewardOptions
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
      rewardRulesFileName: _encodeCsv(
        rewardRulesHeaders,
        rewardRules
            .map(
              (item) => [
                item.id,
                item.name,
                item.periodType.dbValue,
                item.thresholdPoints,
                item.rewardText,
                item.sortOrder,
                item.isEnabled ? 1 : 0,
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
                item.pomodoroCount,
                item.points,
                item.createdAt.toIso8601String(),
                item.updatedAt.toIso8601String(),
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
      throw const FormatException('请选择至少一个 CSV 文件。');
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

    if (bundle.includedTypes.contains(CsvDatasetType.rewardOptions)) {
      if (mode == CsvImportMode.overwrite) {
        await importTarget.replaceRewardOptions(bundle.rewardOptions);
      } else {
        await importTarget.appendRewardOptions(bundle.rewardOptions);
      }
    }

    if (bundle.includedTypes.contains(CsvDatasetType.rewardRules)) {
      if (mode == CsvImportMode.overwrite) {
        await importTarget.replaceRewardRules(bundle.rewardRules);
      } else {
        await importTarget.appendRewardRules(bundle.rewardRules);
      }
    }

    if (bundle.includedTypes.contains(CsvDatasetType.studyRecords)) {
      if (mode == CsvImportMode.overwrite) {
        await importTarget.replaceStudyRecords(bundle.studyRecords);
      } else {
        await importTarget.appendStudyRecords(bundle.studyRecords);
      }
    }

    await importTarget.normalizeAfterImport();

    return CsvImportSummary(
      categories: bundle.categories.length,
      contentOptions: bundle.contentOptions.length,
      rewardOptions: bundle.rewardOptions.length,
      rewardRules: bundle.rewardRules.length,
      studyRecords: bundle.studyRecords.length,
    );
  }

  CsvImportBundle parseFiles(Map<String, String> fileContents) {
    final categories = <CategoryOption>[];
    final contentOptions = <ContentOption>[];
    final rewardOptions = <RewardOption>[];
    final rewardRules = <RewardRule>[];
    final studyRecords = <StudyRecord>[];
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
        case rewardOptionsFileName:
          rewardOptions.addAll(_parseRewardOptions(entry.value));
          includedTypes.add(CsvDatasetType.rewardOptions);
          break;
        case rewardRulesFileName:
          rewardRules.addAll(_parseRewardRules(entry.value));
          includedTypes.add(CsvDatasetType.rewardRules);
          break;
        case studyRecordsFileName:
          studyRecords.addAll(_parseStudyRecords(entry.value));
          includedTypes.add(CsvDatasetType.studyRecords);
          break;
        default:
          throw FormatException('不支持的 CSV 文件：${entry.key}');
      }
    }

    return CsvImportBundle(
      categories: categories,
      contentOptions: contentOptions,
      rewardOptions: rewardOptions,
      rewardRules: rewardRules,
      studyRecords: studyRecords,
      includedTypes: includedTypes,
    );
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
    final rows = _decodeCsv(content, contentOptionsHeaders);
    return rows
        .map(
          (row) => ContentOption(
            id: _parseNullableInt(row[0]),
            name: _requireText(row[1], 'name'),
            categoryId: _parseNullableInt(row[2]),
            sortOrder: _parseRequiredInt(row[3], 'sort_order'),
            isEnabled: _parseBool(row[4], 'is_enabled'),
            createdAt: _parseDateTime(row[5], 'created_at'),
            updatedAt: _parseDateTime(row[6], 'updated_at'),
          ),
        )
        .toList(growable: false);
  }

  List<RewardOption> _parseRewardOptions(String content) {
    final rows = _decodeCsv(content, rewardOptionsHeaders);
    return rows
        .map(
          (row) => RewardOption(
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

  List<RewardRule> _parseRewardRules(String content) {
    final rows = _decodeCsv(content, rewardRulesHeaders);
    return rows
        .map(
          (row) => RewardRule(
            id: _parseNullableInt(row[0]),
            name: _requireText(row[1], 'name'),
            periodType: RewardRulePeriodTypeX.fromDbValue(
              _requireText(row[2], 'period_type'),
            ),
            thresholdPoints: _parseRequiredInt(row[3], 'threshold_points'),
            rewardText: _requireText(row[4], 'reward_text'),
            sortOrder: _parseRequiredInt(row[5], 'sort_order'),
            isEnabled: _parseBool(row[6], 'is_enabled'),
            createdAt: _parseDateTime(row[7], 'created_at'),
            updatedAt: _parseDateTime(row[8], 'updated_at'),
          ),
        )
        .toList(growable: false);
  }

  List<StudyRecord> _parseStudyRecords(String content) {
    final rows = _decodeCsv(content, studyRecordsHeaders);
    return rows
        .map(
          (row) => StudyRecord(
            id: _parseNullableInt(row[0]),
            occurredAt: _parseDateTime(row[1], 'occurred_at'),
            categoryId: _parseNullableInt(row[2]),
            categoryNameSnapshot: _requireText(row[3], 'category_name_snapshot'),
            contentOptionId: _parseNullableInt(row[4]),
            contentNameSnapshot: _requireText(row[5], 'content_name_snapshot'),
            rewardOptionId: _parseNullableInt(row[6]),
            rewardNameSnapshot: _requireText(row[7], 'reward_name_snapshot'),
            pomodoroCount: _parseRequiredInt(row[8], 'pomodoro_count'),
            points: _parseRequiredInt(row[9], 'points'),
            createdAt: _parseDateTime(row[10], 'created_at'),
            updatedAt: _parseDateTime(row[11], 'updated_at'),
          ),
        )
        .toList(growable: false);
  }

  List<List<dynamic>> _decodeCsv(String content, List<String> expectedHeaders) {
    final normalized = content.replaceFirst('\uFEFF', '');
    final rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(normalized);

    if (rows.isEmpty) {
      throw const FormatException('CSV 文件为空。');
    }

    final actualHeaders =
        rows.first
            .map((cell) => cell.toString().trim().replaceFirst('\uFEFF', ''))
            .toList(growable: false);

    if (!_headersMatch(actualHeaders, expectedHeaders)) {
      throw FormatException(
        'CSV 表头不匹配。期望：${expectedHeaders.join(', ')}；实际：${actualHeaders.join(', ')}',
      );
    }

    return rows
        .skip(1)
        .where((row) => row.any((cell) => cell.toString().trim().isNotEmpty))
        .toList(growable: false);
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
}
