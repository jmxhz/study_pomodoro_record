import 'package:flutter/foundation.dart';

import '../../../app/app_services.dart';
import '../../../data/models/category_option.dart';
import '../../../data/models/content_option.dart';
import '../../../data/models/improvement_option.dart';
import '../../../data/models/reward_rule.dart';
import '../../../data/models/redeem_reward.dart';
import '../../../data/models/reward_option.dart';
import '../../../data/models/weakness_option.dart';
import '../../../data/repositories/csv_service.dart';
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
  List<RewardOption> rewardOptions = const [];
  List<RewardRule> rewardRules = const [];
  List<WeaknessOption> weaknessOptions = const [];
  List<ImprovementOption> improvementOptions = const [];
  List<RedeemReward> redeemRewards = const [];

  Future<void> load() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      categories = await optionsRepository.getCategories();
      contentOptions = await optionsRepository.getContentOptions();
      rewardOptions = await optionsRepository.getRewardOptions();
      rewardRules = await optionsRepository.getRewardRules();
      weaknessOptions = await optionsRepository.getWeaknessOptions();
      improvementOptions = await optionsRepository.getImprovementOptions();
      redeemRewards = await optionsRepository.getRedeemRewards();
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
      await optionsRepository.updateCategory(
        item.copyWith(updatedAt: DateTime.now()),
      );
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
    required int defaultPoints,
    required bool allowAdjust,
    required int minPoints,
    required int maxPoints,
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
          defaultPoints: defaultPoints,
          allowAdjust: allowAdjust,
          minPoints: minPoints,
          maxPoints: maxPoints,
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
      await optionsRepository.updateContentOption(
        item.copyWith(updatedAt: DateTime.now()),
      );
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

  Future<void> addReward({
    required String name,
    required bool isEnabled,
  }) async {
    await _runBusyAction(() async {
      final now = DateTime.now();
      final sortOrder = await optionsRepository.nextRewardSortOrder();
      await optionsRepository.insertRewardOption(
        RewardOption(
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

  Future<void> updateReward(RewardOption item) async {
    await _runBusyAction(() async {
      await optionsRepository.updateRewardOption(
        item.copyWith(updatedAt: DateTime.now()),
      );
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
    final items = [...rewardOptions];
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

  Future<void> addRewardRule({
    required String name,
    required RewardRulePeriodType periodType,
    required int thresholdPoints,
    required String rewardText,
    required bool isEnabled,
  }) async {
    await _runBusyAction(() async {
      final now = DateTime.now();
      final sortOrder = await optionsRepository.nextRewardRuleSortOrder();
      await optionsRepository.insertRewardRule(
        RewardRule(
          name: name,
          periodType: periodType,
          thresholdPoints: thresholdPoints,
          rewardText: rewardText,
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

  Future<void> updateRewardRule(RewardRule item) async {
    await _runBusyAction(() async {
      await optionsRepository.updateRewardRule(
        item.copyWith(updatedAt: DateTime.now()),
      );
      await load();
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> deleteRewardRule(RewardRule item) async {
    if (item.id == null) {
      return;
    }
    await _runBusyAction(() async {
      await optionsRepository.deleteRewardRule(item.id!);
      await load();
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> reorderRewardRules(int oldIndex, int newIndex) async {
    final items = [...rewardRules];
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    await _runBusyAction(() async {
      await optionsRepository.reorderRewardRules(items);
      await load();
      dataSyncNotifier.notifyChanged();
    });
  }

  Future<void> addWeaknessOption({
    required String name,
    required int? categoryId,
    required bool isEnabled,
  }) async {
    await _runBusyAction(() async {
      final now = DateTime.now();
      final sortOrder = await optionsRepository.nextWeaknessSortOrder();
      await optionsRepository.insertWeaknessOption(
        WeaknessOption(
          name: name,
          categoryId: categoryId,
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
      await optionsRepository.updateWeaknessOption(
        item.copyWith(updatedAt: DateTime.now()),
      );
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

  Future<void> addImprovementOption({
    required String name,
    required int? categoryId,
    required bool isEnabled,
  }) async {
    await _runBusyAction(() async {
      final now = DateTime.now();
      final sortOrder = await optionsRepository.nextImprovementSortOrder();
      await optionsRepository.insertImprovementOption(
        ImprovementOption(
          name: name,
          categoryId: categoryId,
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
      await optionsRepository.updateImprovementOption(
        item.copyWith(updatedAt: DateTime.now()),
      );
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
      await optionsRepository.updateRedeemReward(
        item.copyWith(updatedAt: DateTime.now()),
      );
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

  Future<CsvExportResult> exportAllData() async {
    late CsvExportResult result;
    await _runBusyAction(() async {
      result = await csvService.exportAllData();
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
}
