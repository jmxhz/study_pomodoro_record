import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/db/app_database_runtime.dart';
import '../data/repositories/csv_service_runtime.dart';
import '../data/repositories/options_repository.dart';
import '../data/repositories/reward_redemption_repository.dart';
import '../data/repositories/study_record_repository.dart';

class AppServices {
  AppServices._({
    required this.database,
    required this.optionsRepository,
    required this.studyRecordRepository,
    required this.rewardRedemptionRepository,
    required this.csvService,
    required this.dataSyncNotifier,
    required this.themeController,
    required this.autoBackupController,
  });

  final AppDatabase database;
  final OptionsRepository optionsRepository;
  final StudyRecordRepository studyRecordRepository;
  final RewardRedemptionRepository rewardRedemptionRepository;
  final CsvService csvService;
  final DataSyncNotifier dataSyncNotifier;
  final ThemeController themeController;
  final AutoBackupController autoBackupController;

  static Future<AppServices> create() async {
    final database = AppDatabase();
    final optionsRepository = OptionsRepository(database);
    final studyRecordRepository = StudyRecordRepository(database);
    final rewardRedemptionRepository = RewardRedemptionRepository(database);
    final csvService = CsvService(
      optionsRepository: optionsRepository,
      studyRecordRepository: studyRecordRepository,
      rewardRedemptionRepository: rewardRedemptionRepository,
    );
    final dataSyncNotifier = DataSyncNotifier();
    final autoBackupController = AutoBackupController(
      csvService: csvService,
      dataSyncNotifier: dataSyncNotifier,
    );
    final themeController =
        ThemeController(optionsRepository, dataSyncNotifier);
    unawaited(themeController.load());

    return AppServices._(
      database: database,
      optionsRepository: optionsRepository,
      studyRecordRepository: studyRecordRepository,
      rewardRedemptionRepository: rewardRedemptionRepository,
      csvService: csvService,
      dataSyncNotifier: dataSyncNotifier,
      themeController: themeController,
      autoBackupController: autoBackupController,
    );
  }
}

class DataSyncNotifier extends ChangeNotifier {
  void notifyChanged() {
    notifyListeners();
  }
}

class ThemeController extends ChangeNotifier {
  ThemeController(this._optionsRepository, this._dataSyncNotifier);

  final OptionsRepository _optionsRepository;
  final DataSyncNotifier _dataSyncNotifier;
  String paletteKey = 'monet-mist';

  Future<void> load() async {
    paletteKey = await _optionsRepository.getThemePalette();
    notifyListeners();
  }

  Future<void> setPalette(String value) async {
    if (paletteKey == value) {
      return;
    }
    paletteKey = value;
    notifyListeners();
    await _optionsRepository.setThemePalette(value);
    _dataSyncNotifier.notifyChanged();
  }
}

class AutoBackupController {
  AutoBackupController({
    required CsvService csvService,
    required DataSyncNotifier dataSyncNotifier,
  })  : _csvService = csvService,
        _dataSyncNotifier = dataSyncNotifier {
    _listener = _scheduleBackup;
    _dataSyncNotifier.addListener(_listener);
  }

  final CsvService _csvService;
  final DataSyncNotifier _dataSyncNotifier;
  late final VoidCallback _listener;
  Timer? _debounceTimer;
  bool _isExporting = false;
  bool _queued = false;

  void _scheduleBackup() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), _flushBackup);
  }

  Future<void> _flushBackup() async {
    if (_isExporting) {
      _queued = true;
      return;
    }
    _isExporting = true;
    try {
      await _csvService.exportAutoBackupIfConfigured();
    } catch (_) {
      // 自动备份失败不打断正常业务保存流程。
    } finally {
      _isExporting = false;
      if (_queued) {
        _queued = false;
        _scheduleBackup();
      }
    }
  }

  void dispose() {
    _debounceTimer?.cancel();
    _dataSyncNotifier.removeListener(_listener);
  }
}
