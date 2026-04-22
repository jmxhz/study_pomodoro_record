import 'package:flutter/foundation.dart';

import '../../../app/app_services.dart';
import '../../../data/models/category_option.dart';
import '../../../data/models/content_option.dart';
import '../../../data/models/improvement_option.dart';
import '../../../data/models/life_option.dart';
import '../../../data/models/redeem_reward.dart';
import '../../../data/models/reward_option.dart';
import '../../../data/models/weakness_option.dart';
import '../../../data/repositories/csv_service_runtime.dart';
import '../../../data/repositories/options_repository.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({
    required this.optionsRepository,
    required this.csvService,
    required this.dataSyncNotifier,
  }) {
    load();
  }

  final OptionsRepository optionsRepository;
  final CsvService csvService;
  final DataSyncNotifier dataSyncNotifier;

  bool isLoading = true;
  bool isBusy = false;
  String? errorMessage;

  List<CategoryOption> categories = const [];
  List<ContentOption> contentOptions = const [];
  List<RewardOption> shortBreakOptions = const [];
  List<RewardOption> longBreakOptions = const [];
  List<WeaknessOption> weaknessOptions = const [];
  List<ImprovementOption> improvementOptions = const [];
  List<RedeemReward> redeemRewards = const [];
  List<LifeOption> lifeOptions = const [];
  int longBreakEvery = 4;
  int sessionGapMinutes = 90;
  int lifeDailyTargetPoints = 10;
  int lifeDailyTargetBonusPoints = 5;
  String? backupDirectoryPath;
  String? lastTransferDirectoryPath;

  Future<void> load() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();
      final results = await Future.wait([
        optionsRepository.getCategories(),
        optionsRepository.getContentOptions(),
        optionsRepository.getRewardOptions(type: 'short'),
        optionsRepository.getRewardOptions(type: 'long'),
        optionsRepository.getWeaknessOptions(),
        optionsRepository.getImprovementOptions(),
        optionsRepository.getRedeemRewards(),
        optionsRepository.getLifeOptions(),
        optionsRepository.getLongBreakEvery(),
        optionsRepository.getSessionGapMinutes(),
        optionsRepository.getLifeDailyTargetPoints(),
        optionsRepository.getLifeDailyTargetBonusPoints(),
        optionsRepository.getBackupDirectoryPath(),
        optionsRepository.getLastTransferDirectoryPath(),
      ]);
      categories = results[0] as List<CategoryOption>;
      contentOptions = results[1] as List<ContentOption>;
      shortBreakOptions = results[2] as List<RewardOption>;
      longBreakOptions = results[3] as List<RewardOption>;
      weaknessOptions = results[4] as List<WeaknessOption>;
      improvementOptions = results[5] as List<ImprovementOption>;
      redeemRewards = results[6] as List<RedeemReward>;
      lifeOptions = results[7] as List<LifeOption>;
      longBreakEvery = results[8] as int;
      sessionGapMinutes = results[9] as int;
      lifeDailyTargetPoints = results[10] as int;
      lifeDailyTargetBonusPoints = results[11] as int;
      backupDirectoryPath = results[12] as String?;
      lastTransferDirectoryPath = results[13] as String?;
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String categoryNameOf(int? categoryId) {
    if (categoryId == null) {
      return '全部分类';
    }
    final match = categories.where((item) => item.id == categoryId);
    return match.isEmpty ? '未找到分类' : match.first.name;
  }

  String contentNameOf(int? contentOptionId) {
    if (contentOptionId == null) {
      return '未绑定内容';
    }
    final match = contentOptions.where((item) => item.id == contentOptionId);
    return match.isEmpty ? '未找到内容' : match.first.name;
  }

  Future<void> addCategory({
    required String name,
    required bool isEnabled,
  }) async {
    await _runBusyAction(() async {
      final now = DateTime.now();
      final sortOrder = await optionsRepository.nextCategorySortOrder();
      await optionsRepository.insertCategory(
        CategoryOption(
          name: name,
          sortOrder: sortOrder,
          isEnabled: isEnabled,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await load();
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> updateCategory(CategoryOption item) async {
    await _runBusyAction(() async {
      await optionsRepository
          .updateCategory(item.copyWith(updatedAt: DateTime.now()));
      await load();
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> deleteCategory(CategoryOption item) async {
    if (item.id == null) {
      return;
    }
    await _runBusyAction(() async {
      await optionsRepository.deleteCategory(item.id!);
      await load();
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> reorderCategories(int oldIndex, int newIndex) async {
    final items = [...categories];
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    await _runBusyAction(() async {
      await optionsRepository.reorderCategories(items);
      await load();
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> addContent({
    required String name,
    required int? categoryId,
    required bool isEnabled,
    required int points,
  }) async {
    await _runBusyAction(() async {
      final now = DateTime.now();
      final sortOrder = await optionsRepository.nextContentSortOrder();
      await optionsRepository.insertContentOption(
        ContentOption(
          name: name,
          categoryId: categoryId,
          sortOrder: sortOrder,
          isEnabled: isEnabled,
          points: points,
          defaultPoints: points,
          allowAdjust: false,
          minPoints: points,
          maxPoints: points,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await load();
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> updateContent(ContentOption item) async {
    await _runBusyAction(() async {
      await optionsRepository
          .updateContentOption(item.copyWith(updatedAt: DateTime.now()));
      await load();
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> deleteContent(ContentOption item) async {
    if (item.id == null) {
      return;
    }
    await _runBusyAction(() async {
      await optionsRepository.deleteContentOption(item.id!);
      await load();
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> reorderContents(int oldIndex, int newIndex) async {
    final items = [...contentOptions];
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    await _runBusyAction(() async {
      await optionsRepository.reorderContentOptions(items);
      await load();
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> reorderContentsInCategory(
    int? categoryId,
    int oldIndex,
    int newIndex,
  ) async {
    final reordered = _reorderWithinCategory<ContentOption>(
      items: contentOptions,
      categoryId: categoryId,
      categoryIdOf: (item) => item.categoryId,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
    await _runBusyAction(() async {
      await optionsRepository.reorderContentOptions(reordered);
      await load();
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> addReward({
    required String name,
    required String type,
    required bool isEnabled,
  }) async {
    await _runBusyAction(() async {
      final now = DateTime.now();
      final sortOrder = await optionsRepository.nextRewardSortOrder();
      await optionsRepository.insertRewardOption(
        RewardOption(
          name: name,
          type: type,
          sortOrder: sortOrder,
          isEnabled: isEnabled,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await load();
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> updateReward(RewardOption item) async {
    await _runBusyAction(() async {
      await optionsRepository
          .updateRewardOption(item.copyWith(updatedAt: DateTime.now()));
      await load();
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> deleteReward(RewardOption item) async {
    if (item.id == null) {
      return;
    }
    await _runBusyAction(() async {
      await optionsRepository.deleteRewardOption(item.id!);
      await load();
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> reorderRewards(int oldIndex, int newIndex) async {
    final items = [...shortBreakOptions, ...longBreakOptions];
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    await _runBusyAction(() async {
      await optionsRepository.reorderRewardOptions(items);
      await load();
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> reorderBreaksByType(
      String type, int oldIndex, int newIndex) async {
    final reordered = _reorderWithinCategory<RewardOption>(
      items: [...shortBreakOptions, ...longBreakOptions],
      categoryId: type == 'long' ? 1 : 0,
      categoryIdOf: (item) => item.type == 'long' ? 1 : 0,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
    await _runBusyAction(() async {
      await optionsRepository.reorderRewardOptions(reordered);
      await load();
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> setLongBreakEveryValue(int value) async {
    await _runBusyAction(() async {
      await optionsRepository.setLongBreakEvery(value);
      longBreakEvery = value;
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> setSessionGapMinutesValue(int value) async {
    await _runBusyAction(() async {
      await optionsRepository.setSessionGapMinutes(value);
      sessionGapMinutes = value;
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> setLifeDailyTargetPointsValue(int value) async {
    await _runBusyAction(() async {
      await optionsRepository.setLifeDailyTargetPoints(value);
      lifeDailyTargetPoints = value;
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> setLifeDailyTargetBonusPointsValue(int value) async {
    await _runBusyAction(() async {
      await optionsRepository.setLifeDailyTargetBonusPoints(value);
      lifeDailyTargetBonusPoints = value;
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> addWeaknessOption({
    required String name,
    required int? contentOptionId,
    required bool isEnabled,
  }) async {
    await _runBusyAction(() async {
      final now = DateTime.now();
      final sortOrder = await optionsRepository.nextWeaknessSortOrder();
      await optionsRepository.insertWeaknessOption(
        WeaknessOption(
          name: name,
          contentOptionId: contentOptionId,
          sortOrder: sortOrder,
          isEnabled: isEnabled,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await load();
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> updateWeaknessOption(WeaknessOption item) async {
    await _runBusyAction(() async {
      await optionsRepository
          .updateWeaknessOption(item.copyWith(updatedAt: DateTime.now()));
      await load();
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> deleteWeaknessOption(WeaknessOption item) async {
    if (item.id == null) {
      return;
    }
    await _runBusyAction(() async {
      await optionsRepository.deleteWeaknessOption(item.id!);
      await load();
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> reorderWeaknessOptions(int oldIndex, int newIndex) async {
    final items = [...weaknessOptions];
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    await _runBusyAction(() async {
      await optionsRepository.reorderWeaknessOptions(items);
      await load();
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> reorderWeaknessOptionsInCategory(
    int? contentOptionId,
    int oldIndex,
    int newIndex,
  ) async {
    final reordered = _reorderWithinCategory<WeaknessOption>(
      items: weaknessOptions,
      categoryId: contentOptionId,
      categoryIdOf: (item) => item.contentOptionId,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
    await _runBusyAction(() async {
      await optionsRepository.reorderWeaknessOptions(reordered);
      await load();
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> reorderWeaknessOptionsInLegacyCategory(
    int? categoryId,
    int oldIndex,
    int newIndex,
  ) async {
    final reordered = _reorderWithinCategory<WeaknessOption>(
      items: weaknessOptions,
      categoryId: categoryId,
      categoryIdOf: (item) => item.categoryId,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
    await _runBusyAction(() async {
      await optionsRepository.reorderWeaknessOptions(reordered);
      await load();
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> addImprovementOption({
    required String name,
    required int? contentOptionId,
    required bool isEnabled,
  }) async {
    await _runBusyAction(() async {
      final now = DateTime.now();
      final sortOrder = await optionsRepository.nextImprovementSortOrder();
      await optionsRepository.insertImprovementOption(
        ImprovementOption(
          name: name,
          contentOptionId: contentOptionId,
          sortOrder: sortOrder,
          isEnabled: isEnabled,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await load();
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> updateImprovementOption(ImprovementOption item) async {
    await _runBusyAction(() async {
      await optionsRepository
          .updateImprovementOption(item.copyWith(updatedAt: DateTime.now()));
      await load();
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> deleteImprovementOption(ImprovementOption item) async {
    if (item.id == null) {
      return;
    }
    await _runBusyAction(() async {
      await optionsRepository.deleteImprovementOption(item.id!);
      await load();
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> reorderImprovementOptions(int oldIndex, int newIndex) async {
    final items = [...improvementOptions];
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    await _runBusyAction(() async {
      await optionsRepository.reorderImprovementOptions(items);
      await load();
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> reorderImprovementOptionsInCategory(
    int? contentOptionId,
    int oldIndex,
    int newIndex,
  ) async {
    final reordered = _reorderWithinCategory<ImprovementOption>(
      items: improvementOptions,
      categoryId: contentOptionId,
      categoryIdOf: (item) => item.contentOptionId,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
    await _runBusyAction(() async {
      await optionsRepository.reorderImprovementOptions(reordered);
      await load();
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> reorderImprovementOptionsInLegacyCategory(
    int? categoryId,
    int oldIndex,
    int newIndex,
  ) async {
    final reordered = _reorderWithinCategory<ImprovementOption>(
      items: improvementOptions,
      categoryId: categoryId,
      categoryIdOf: (item) => item.categoryId,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
    await _runBusyAction(() async {
      await optionsRepository.reorderImprovementOptions(reordered);
      await load();
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> addRedeemReward({
    required String name,
    required int costPoints,
    required String? note,
    required bool isEnabled,
  }) async {
    await _runBusyAction(() async {
      final now = DateTime.now();
      final sortOrder = await optionsRepository.nextRedeemRewardSortOrder();
      await optionsRepository.insertRedeemReward(
        RedeemReward(
          name: name,
          costPoints: costPoints,
          sortOrder: sortOrder,
          isEnabled: isEnabled,
          note: note,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await load();
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> updateRedeemReward(RedeemReward item) async {
    await _runBusyAction(() async {
      await optionsRepository
          .updateRedeemReward(item.copyWith(updatedAt: DateTime.now()));
      await load();
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> deleteRedeemReward(RedeemReward item) async {
    if (item.id == null) {
      return;
    }
    await _runBusyAction(() async {
      await optionsRepository.deleteRedeemReward(item.id!);
      await load();
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> reorderRedeemRewards(int oldIndex, int newIndex) async {
    final items = [...redeemRewards];
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    await _runBusyAction(() async {
      await optionsRepository.reorderRedeemRewards(items);
      await load();
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> addLifeOption({
    required String name,
    required int points,
    required bool isEnabled,
  }) async {
    await _runBusyAction(() async {
      final now = DateTime.now();
      final sortOrder = await optionsRepository.nextLifeOptionSortOrder();
      await optionsRepository.insertLifeOption(
        LifeOption(
          name: name,
          points: points,
          sortOrder: sortOrder,
          isEnabled: isEnabled,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await load();
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> updateLifeOption(LifeOption item) async {
    await _runBusyAction(() async {
      await optionsRepository.updateLifeOption(
        item.copyWith(updatedAt: DateTime.now()),
      );
      await load();
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> deleteLifeOption(LifeOption item) async {
    if (item.id == null) {
      return;
    }
    await _runBusyAction(() async {
      await optionsRepository.deleteLifeOption(item.id!);
      await load();
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> reorderLifeOptions(int oldIndex, int newIndex) async {
    final items = [...lifeOptions];
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    await _runBusyAction(() async {
      await optionsRepository.reorderLifeOptions(items);
      await load();
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<CsvExportResult> exportAllData() async {
    late CsvExportResult result;
    await _runBusyAction(() async {
      result = await csvService.exportAllData();
      backupDirectoryPath = result.directory.path;
    });
    return result;
  }

  Future<CsvExportResult> exportAllDataToDirectory(String directoryPath) async {
    late CsvExportResult result;
    await _runBusyAction(() async {
      await optionsRepository.setBackupDirectoryPath(directoryPath);
      result = await csvService.exportAllData(
        directoryPath: directoryPath,
        rememberDirectory: true,
      );
      backupDirectoryPath = result.directory.path;
    });
    return result;
  }

  Future<CsvExportResult> exportManualDataToDirectory(
      String directoryPath) async {
    late CsvExportResult result;
    await _runBusyAction(() async {
      await optionsRepository.setLastTransferDirectoryPath(directoryPath);
      result =
          await csvService.exportManualSnapshot(directoryPath: directoryPath);
      lastTransferDirectoryPath = directoryPath;
    });
    return result;
  }

  Future<CsvImportSummary> importCsvFiles(
    List<String> filePaths,
    CsvImportMode mode,
  ) async {
    late CsvImportSummary result;
    await _runBusyAction(() async {
      result = await csvService.importFromPaths(filePaths, mode);
      if (filePaths.isNotEmpty) {
        final normalized = filePaths.first.replaceAll('\\', '/');
        final lastSlash = normalized.lastIndexOf('/');
        if (lastSlash > 0) {
          final directoryPath =
              normalized.substring(0, lastSlash).replaceAll('/', '\\');
          await optionsRepository.setLastTransferDirectoryPath(directoryPath);
          lastTransferDirectoryPath = directoryPath;
        }
      }
      await load();
      dataSyncNotifier.notifyChanged();
    });
    return result;
  }

  Future<void> _runBusyAction(Future<void> Function() action) async {
    try {
      isBusy = true;
      errorMessage = null;
      notifyListeners();
      await action();
    } catch (error) {
      errorMessage = error.toString();
      rethrow;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  List<T> _reorderWithinCategory<T>({
    required List<T> items,
    required int? categoryId,
    required int? Function(T item) categoryIdOf,
    required int oldIndex,
    required int newIndex,
  }) {
    final reordered = [...items];
    final groupPositions = <int>[];
    final groupItems = <T>[];

    for (var index = 0; index < reordered.length; index++) {
      final item = reordered[index];
      if (categoryIdOf(item) == categoryId) {
        groupPositions.add(index);
        groupItems.add(item);
      }
    }

    if (groupItems.isEmpty || oldIndex < 0 || oldIndex >= groupItems.length) {
      return reordered;
    }

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    if (newIndex < 0) {
      newIndex = 0;
    }
    if (newIndex > groupItems.length) {
      newIndex = groupItems.length;
    }

    final movedItem = groupItems.removeAt(oldIndex);
    groupItems.insert(newIndex, movedItem);

    for (var index = 0; index < groupPositions.length; index++) {
      reordered[groupPositions[index]] = groupItems[index];
    }
    return reordered;
  }
}
