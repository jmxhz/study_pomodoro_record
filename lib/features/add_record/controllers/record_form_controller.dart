import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../app/app_services.dart';
import '../../../data/models/category_option.dart';
import '../../../data/models/content_option.dart';
import '../../../data/models/reward_option.dart';
import '../../../data/models/study_record.dart';
import '../../../data/repositories/options_repository.dart';
import '../../../data/repositories/study_record_repository.dart';

class RecordFormController extends ChangeNotifier {
  RecordFormController({
    required this.optionsRepository,
    required this.studyRecordRepository,
    required this.dataSyncNotifier,
    this.recordId,
  }) {
    _syncListener = () {
      load(preserveSelection: true);
    };
    dataSyncNotifier.addListener(_syncListener);
    _startClockTicker();
    load();
  }

  final OptionsRepository optionsRepository;
  final StudyRecordRepository studyRecordRepository;
  final DataSyncNotifier dataSyncNotifier;
  final int? recordId;

  late final VoidCallback _syncListener;
  Timer? _clockTimer;

  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;

  List<CategoryOption> _categories = const [];
  List<ContentOption> _contentOptions = const [];
  List<RewardOption> _rewardOptions = const [];
  Map<int, int> _contentUsageCounts = const {};

  CategoryOption? selectedCategory;
  ContentOption? selectedContent;
  RewardOption? selectedReward;
  int pomodoroCount = 1;
  int points = 1;
  DateTime occurredAt = DateTime.now();
  StudyRecord? editingRecord;
  bool _autoTrackCurrentTime = true;

  bool get isEditMode => recordId != null;

  List<CategoryOption> get categories => _visibleCategories();

  List<ContentOption> get contentOptions => _visibleContentOptions();

  List<RewardOption> get rewardOptions => _visibleRewardOptions();

  bool get hasEnabledCategories => _categories.any((item) => item.isEnabled);

  bool get hasEnabledContentOptions => _contentOptions.any((item) => item.isEnabled);

  bool get hasEnabledRewardOptions => _rewardOptions.any((item) => item.isEnabled);

  Future<void> load({bool preserveSelection = false}) async {
    try {
      if (!preserveSelection) {
        isLoading = true;
      }
      errorMessage = null;
      notifyListeners();

      final categories = await optionsRepository.getCategories();
      final contentOptions = await optionsRepository.getContentOptions();
      final rewards = await optionsRepository.getRewardOptions();
      final contentUsageCounts = await studyRecordRepository.getContentUsageCounts();

      _categories = categories;
      _contentOptions = contentOptions;
      _rewardOptions = rewards;
      _contentUsageCounts = contentUsageCounts;

      if (isEditMode) {
        final record = await studyRecordRepository.getRecordById(recordId!);
        if (record == null) {
          throw StateError('未找到要编辑的记录。');
        }
        editingRecord = record;
        _applyRecord(record);
      } else if (!preserveSelection) {
        _applyDefaultSelection();
      } else {
        _reconcileSelections();
      }
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void selectCategory(CategoryOption? value) {
    selectedCategory = value;
    selectedContent = _defaultContentForSelectedCategory();
    notifyListeners();
  }

  void selectContent(ContentOption? value) {
    selectedContent = value;
    notifyListeners();
  }

  void selectReward(RewardOption? value) {
    selectedReward = value;
    notifyListeners();
  }

  void setPomodoroCount(int value) {
    pomodoroCount = value;
    notifyListeners();
  }

  void setPoints(int value) {
    points = value;
    notifyListeners();
  }

  void setOccurredAt(DateTime value, {bool manual = true}) {
    occurredAt = value;
    if (!isEditMode && manual) {
      _autoTrackCurrentTime = false;
    }
    notifyListeners();
  }

  String? validateForm() {
    if (selectedCategory == null) {
      return '请选择分类。';
    }
    if (selectedContent == null) {
      return '请选择内容。';
    }
    if (selectedReward == null) {
      return '请选择奖励内容。';
    }
    if (pomodoroCount < 1 || pomodoroCount > 4) {
      return '番茄钟数必须在 1 到 4 之间。';
    }
    if (points < 1 || points > 4) {
      return '积分数必须在 1 到 4 之间。';
    }
    return null;
  }

  Future<void> save({required bool continueAdding}) async {
    final validationMessage = validateForm();
    if (validationMessage != null) {
      throw StateError(validationMessage);
    }

    try {
      isSaving = true;
      notifyListeners();

      final now = DateTime.now();
      final baseRecord = editingRecord;
      final record = StudyRecord(
        id: baseRecord?.id,
        occurredAt: occurredAt,
        categoryId: selectedCategory?.id,
        categoryNameSnapshot: selectedCategory!.name,
        contentOptionId: selectedContent?.id,
        contentNameSnapshot: selectedContent!.name,
        rewardOptionId: selectedReward?.id,
        rewardNameSnapshot: selectedReward!.name,
        pomodoroCount: pomodoroCount,
        points: points,
        createdAt: baseRecord?.createdAt ?? now,
        updatedAt: now,
      );

      if (isEditMode) {
        await studyRecordRepository.updateRecord(record);
      } else {
        await studyRecordRepository.insertRecord(record);
      }

      dataSyncNotifier.notifyChanged();

      if (isEditMode) {
        editingRecord = record;
      } else if (continueAdding) {
        editingRecord = null;
        _resetForNext();
      } else {
        editingRecord = null;
        _autoTrackCurrentTime = true;
        occurredAt = DateTime.now();
      }
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  void _applyDefaultSelection() {
    selectedCategory = _categories.where((item) => item.isEnabled).firstOrNull;
    selectedContent = _defaultContentForSelectedCategory();
    selectedReward = _visibleRewardOptions().firstOrNull;
    pomodoroCount = 1;
    points = 1;
    _autoTrackCurrentTime = true;
    occurredAt = DateTime.now();
  }

  void _resetForNext() {
    _autoTrackCurrentTime = true;
    occurredAt = DateTime.now();
    final availableRewards = _visibleRewardOptions();
    selectedContent = _defaultContentForSelectedCategory();
    selectedReward = availableRewards.isEmpty ? null : availableRewards.first;
    pomodoroCount = 1;
    points = 1;
  }

  void _applyRecord(StudyRecord record) {
    selectedCategory = _resolveCategory(record);
    selectedContent = _resolveContent(record);
    selectedReward = _resolveReward(record);
    pomodoroCount = record.pomodoroCount;
    points = record.points;
    _autoTrackCurrentTime = false;
    occurredAt = record.occurredAt;
  }

  void _reconcileSelections() {
    if (selectedCategory != null) {
      final matched = _categories.where((item) => _sameCategory(item, selectedCategory!));
      if (matched.isNotEmpty) {
        selectedCategory = matched.first;
      }
    }

    if (selectedContent != null) {
      final matched =
          _contentOptions.where((item) => _sameContent(item, selectedContent!));
      if (matched.isNotEmpty) {
        selectedContent = matched.first;
      }
    }

    final availableContents = _visibleContentOptions();
    if (selectedContent == null ||
        !availableContents.any((item) => _sameContent(item, selectedContent!))) {
      selectedContent = _defaultContentForSelectedCategory();
    }

    if (selectedReward != null) {
      final matched =
          _rewardOptions.where((item) => _sameReward(item, selectedReward!));
      if (matched.isNotEmpty) {
        selectedReward = matched.first;
      }
    }

    final availableRewards = _visibleRewardOptions();
    if (selectedReward == null ||
        !availableRewards.any((item) => _sameReward(item, selectedReward!))) {
      selectedReward = availableRewards.firstOrNull;
    }

    if (!isEditMode && _autoTrackCurrentTime) {
      occurredAt = DateTime.now();
    }
  }

  CategoryOption _resolveCategory(StudyRecord record) {
    for (final item in _categories) {
      if (item.id == record.categoryId) {
        return item;
      }
    }
    return CategoryOption(
      id: record.categoryId,
      name: '${record.categoryNameSnapshot}（已删除）',
      sortOrder: -1,
      isEnabled: false,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    );
  }

  ContentOption _resolveContent(StudyRecord record) {
    for (final item in _contentOptions) {
      if (item.id == record.contentOptionId) {
        return item;
      }
    }
    return ContentOption(
      id: record.contentOptionId,
      name: '${record.contentNameSnapshot}（已删除）',
      categoryId: record.categoryId,
      sortOrder: -1,
      isEnabled: false,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    );
  }

  RewardOption _resolveReward(StudyRecord record) {
    for (final item in _rewardOptions) {
      if (item.id == record.rewardOptionId) {
        return item;
      }
    }
    return RewardOption(
      id: record.rewardOptionId,
      name: '${record.rewardNameSnapshot}（已删除）',
      sortOrder: -1,
      isEnabled: false,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    );
  }

  List<CategoryOption> _visibleCategories() {
    final result = _categories.where((item) => item.isEnabled).toList(growable: true);
    final selected = selectedCategory;
    if (selected != null && !result.any((item) => _sameCategory(item, selected))) {
      result.insert(0, selected);
    }
    return result;
  }

  List<ContentOption> _visibleContentOptions() {
    final selectedCategoryId = selectedCategory?.id;
    final result =
        _contentOptions.where((item) {
          final allowedForCategory =
              item.categoryId == null ||
              (selectedCategoryId != null && item.categoryId == selectedCategoryId);
          return item.isEnabled && allowedForCategory;
        }).toList(growable: true);

    final selected = selectedContent;
    if (isEditMode &&
        selected != null &&
        !result.any((item) => _sameContent(item, selected))) {
      result.insert(0, selected);
    }
    result.sort(_compareContentOptions);
    return result;
  }

  List<RewardOption> _visibleRewardOptions() {
    final result = _rewardOptions.where((item) => item.isEnabled).toList(growable: true);
    final selected = selectedReward;
    if (selected != null && !result.any((item) => _sameReward(item, selected))) {
      result.insert(0, selected);
    }
    return result;
  }

  ContentOption? _defaultContentForSelectedCategory() {
    final selectedCategoryId = selectedCategory?.id;
    final result =
        _contentOptions.where((item) {
          final allowedForCategory =
              item.categoryId == null ||
              (selectedCategoryId != null && item.categoryId == selectedCategoryId);
          return item.isEnabled && allowedForCategory;
        }).toList(growable: true);
    result.sort(_compareContentOptions);
    return result.firstOrNull;
  }

  void _startClockTicker() {
    if (isEditMode) {
      return;
    }

    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_autoTrackCurrentTime) {
        return;
      }

      final now = DateTime.now();
      if (!_sameSecond(occurredAt, now)) {
        occurredAt = now;
        notifyListeners();
      }
    });
  }

  bool _sameSecond(DateTime a, DateTime b) =>
      a.year == b.year &&
      a.month == b.month &&
      a.day == b.day &&
      a.hour == b.hour &&
      a.minute == b.minute &&
      a.second == b.second;

  bool _sameCategory(CategoryOption a, CategoryOption b) =>
      a.id == b.id && a.name == b.name;

  bool _sameContent(ContentOption a, ContentOption b) => a.id == b.id && a.name == b.name;

  bool _sameReward(RewardOption a, RewardOption b) => a.id == b.id && a.name == b.name;

  int _compareContentOptions(ContentOption a, ContentOption b) {
    final usageCompare = _contentUsageOf(b).compareTo(_contentUsageOf(a));
    if (usageCompare != 0) {
      return usageCompare;
    }

    final sortCompare = a.sortOrder.compareTo(b.sortOrder);
    if (sortCompare != 0) {
      return sortCompare;
    }

    return a.name.compareTo(b.name);
  }

  int _contentUsageOf(ContentOption item) {
    final id = item.id;
    if (id == null) {
      return 0;
    }
    return _contentUsageCounts[id] ?? 0;
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    dataSyncNotifier.removeListener(_syncListener);
    super.dispose();
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
