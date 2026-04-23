import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../app/app_services.dart';
import '../../../core/utils/study_type_utils.dart';
import '../../../data/models/category_option.dart';
import '../../../data/models/content_option.dart';
import '../../../data/models/improvement_option.dart';
import '../../../data/models/reward_option.dart';
import '../../../data/models/study_record.dart';
import '../../../data/models/weakness_option.dart';
import '../../../data/repositories/options_repository.dart';
import '../../../data/repositories/study_record_repository.dart';

class RecordEntryController extends ChangeNotifier {
  RecordEntryController({
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
  bool _isAutoRefreshingDerivedState = false;

  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;

  List<CategoryOption> _categories = const [];
  List<ContentOption> _contentOptions = const [];
  List<RewardOption> _shortBreakOptions = const [];
  List<RewardOption> _longBreakOptions = const [];
  List<WeaknessOption> _weaknessOptions = const [];
  List<ImprovementOption> _improvementOptions = const [];
  Map<int, int> _contentUsageCounts = const {};
  Map<int, int> _lowPointCategoryCounts = const {};
  Map<int, int> _dailyTypeCounts = const {};

  CategoryOption? selectedCategory;
  ContentOption? selectedContent;
  RewardOption? selectedBreakItem;
  int points = 1;
  int longBreakEvery = 4;
  int sessionGapMinutes = 90;
  int sessionCompletedCount = 0;
  String? detailAmountText;
  int? questionCount;
  int? wrongCount;
  List<String> weaknessTags = const [];
  List<String> improvementTags = const [];
  String? notes;
  DateTime occurredAt = DateTime.now();
  StudyRecord? editingRecord;
  bool _autoTrackCurrentTime = true;

  bool get isEditMode => recordId != null;

  List<CategoryOption> get categories => _visibleCategories();

  List<ContentOption> get contentOptions => _visibleContentOptions();

  List<RewardOption> get breakOptions => _visibleBreakOptions();

  List<WeaknessOption> get weaknessOptions => _visibleWeaknessOptions();

  List<ImprovementOption> get improvementOptions =>
      _visibleImprovementOptions();

  String get primaryAmountValue =>
      detailAmountText ?? questionCount?.toString() ?? '';

  bool get hasEnabledCategories => _categories.any((item) => item.isEnabled);

  bool get hasEnabledContentOptions =>
      _contentOptions.any((item) => item.isEnabled);

  bool get hasLowPointLimitReachedInSelectedCategory {
    final categoryId = selectedCategory?.id;
    if (categoryId == null) {
      return false;
    }
    return (_lowPointCategoryCounts[categoryId] ?? 0) >= 1;
  }

  int dailyCountForPoints(int points) => _dailyTypeCounts[points] ?? 0;

  int dailyCountForType(StudyType type) => dailyCountForPoints(
        StudyTypeUtils.recommendedPointsForType(type),
      );

  bool get hasAnyBreakOptions =>
      _shortBreakOptions.any((item) => item.isEnabled) ||
      _longBreakOptions.any((item) => item.isEnabled);

  bool get showsSecondaryCountField => selectedCategory?.name != '申论';

  bool get isLongBreak {
    if (isEditMode && editingRecord?.breakType != null) {
      return editingRecord!.breakType == 'long';
    }
    if (isEditMode && selectedBreakItem != null) {
      return selectedBreakItem!.type == 'long';
    }
    return ((sessionCompletedCount + 1) % longBreakEvery) == 0;
  }

  String get currentBreakType => isLongBreak ? 'long' : 'short';

  String get currentBreakTypeLabel => isLongBreak ? '长休息' : '短休息';

  String get currentBreakEmptyMessage =>
      '当前没有可用的$currentBreakTypeLabel选项，仍可直接保存记录。';

  Future<void> load({bool preserveSelection = false}) async {
    try {
      if (!preserveSelection) {
        isLoading = true;
      }
      errorMessage = null;
      notifyListeners();

      _categories = await optionsRepository.getCategories();
      _contentOptions = await optionsRepository.getContentOptions();
      _shortBreakOptions =
          await optionsRepository.getRewardOptions(type: 'short');
      _longBreakOptions =
          await optionsRepository.getRewardOptions(type: 'long');
      _weaknessOptions =
          await optionsRepository.getWeaknessOptions(includeDisabled: false);
      _improvementOptions =
          await optionsRepository.getImprovementOptions(includeDisabled: false);
      _contentUsageCounts = await studyRecordRepository.getContentUsageCounts();
      longBreakEvery = await optionsRepository.getLongBreakEvery();
      sessionGapMinutes = await optionsRepository.getSessionGapMinutes();

      if (isEditMode) {
        final record = await studyRecordRepository.getRecordById(recordId!);
        if (record == null) {
          throw StateError('未找到要编辑的记录。');
        }
        editingRecord = record;
        await _refreshDailyLimitsAndPlan();
        await _refreshSessionCompletedCount(
          anchor: record.occurredAt,
          excludingRecordId: record.id,
        );
        _applyRecord(record);
      } else {
        await _refreshDailyLimitsAndPlan();
        await _refreshSessionCompletedCount(anchor: occurredAt);
        if (!preserveSelection) {
          _applyDefaultSelection();
        } else {
          _reconcileSelections();
        }
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
    _applySelectedContentDefaults(resetDetailFields: true);
    _ensureSelectedBreakItem();
    notifyListeners();
  }

  void selectContent(ContentOption? value) {
    if (value != null && !isContentSelectable(value)) {
      return;
    }
    selectedContent = value;
    _applySelectedContentDefaults(resetDetailFields: true);
    _ensureSelectedBreakItem();
    notifyListeners();
  }

  void selectBreakItem(RewardOption? value) {
    selectedBreakItem = value;
    notifyListeners();
  }

  void setDetailAmountText(String value) {
    detailAmountText = value.trim().isEmpty ? null : value.trim();
    questionCount = null;
    notifyListeners();
  }

  void setQuestionCount(String value) {
    questionCount = int.tryParse(value.trim());
    notifyListeners();
  }

  void setWrongCount(String value) {
    wrongCount = int.tryParse(value.trim());
    notifyListeners();
  }

  void setWeaknessTag(String? tag) {
    weaknessTags = tag == null ? const [] : [tag];
    notifyListeners();
  }

  void setImprovementTag(String? tag) {
    improvementTags = tag == null ? const [] : [tag];
    notifyListeners();
  }

  void setNotes(String value) {
    notes = value.trim().isEmpty ? null : value.trim();
    notifyListeners();
  }

  Future<void> setOccurredAt(DateTime value, {bool manual = true}) async {
    occurredAt = value;
    if (manual) {
      _autoTrackCurrentTime = false;
    }
    await _refreshDailyLimitsAndPlan();
    if (!isEditMode && manual) {
      await _refreshSessionCompletedCount(anchor: value);
      _ensureSelectedBreakItem();
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
    return null;
  }

  Future<void> save({required bool continueAdding}) async {
    final validationMessage = validateForm();
    if (validationMessage != null) {
      throw StateError(validationMessage);
    }

    final selected = selectedContent!;
    if (!isContentSelectable(selected)) {
      throw StateError('当前分类下 2 分以下内容每天只能记录 1 次，请选择更高积分内容。');
    }
    if (_effectivePointsForContent(selected) < 2) {
      final categoryId = selected.categoryId ?? selectedCategory?.id;
      if (categoryId != null &&
          (_lowPointCategoryCounts[categoryId] ?? 0) >= 1) {
        throw StateError('当前分类下 2 分以下内容每天只能记录 1 次，请选择更高积分内容。');
      }
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
        rewardOptionId: selectedBreakItem?.id,
        rewardNameSnapshot: selectedBreakItem?.name ?? '',
        breakType: currentBreakType,
        feedbackOptionId: selectedBreakItem?.id,
        feedbackNameSnapshot: selectedBreakItem?.name ?? '',
        pomodoroCount: 1,
        points: _effectivePointsForContent(selected),
        detailAmountText: detailAmountText,
        questionCount: questionCount,
        wrongCount: wrongCount,
        outputType: null,
        weaknessTags: weaknessTags,
        improvementTags: improvementTags,
        notes: notes,
        createdAt: baseRecord?.createdAt ?? now,
        updatedAt: now,
      );

      if (isEditMode) {
        await studyRecordRepository.updateRecord(record);
      } else {
        await studyRecordRepository.insertRecord(record);
        sessionCompletedCount += 1;
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
        _resetDetailFields();
      }
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  void _applyDefaultSelection() {
    selectedCategory = _categories.where((item) => item.isEnabled).firstOrNull;
    selectedContent = _defaultContentForSelectedCategory();
    points = _effectivePointsForContent(selectedContent);
    _resetDetailFields();
    _autoTrackCurrentTime = true;
    occurredAt = DateTime.now();
    _ensureSelectedBreakItem();
  }

  void _resetForNext() {
    _autoTrackCurrentTime = true;
    occurredAt = DateTime.now();
    selectedContent = _defaultContentForSelectedCategory();
    points = _effectivePointsForContent(selectedContent);
    _resetDetailFields();
    _ensureSelectedBreakItem();
  }

  void _applyRecord(StudyRecord record) {
    selectedCategory = _resolveCategory(record);
    selectedContent = _resolveContent(record);
    selectedBreakItem = _resolveBreakItem(record);
    points = _effectivePointsForContent(selectedContent,
        fallbackPoints: record.points);
    detailAmountText = record.detailAmountText;
    questionCount = record.questionCount;
    wrongCount = record.wrongCount;
    weaknessTags =
        record.weaknessTags.isEmpty ? const [] : [record.weaknessTags.first];
    improvementTags = record.improvementTags.isEmpty
        ? const []
        : [record.improvementTags.first];
    notes = record.notes;
    _autoTrackCurrentTime = false;
    occurredAt = record.occurredAt;
    _ensureSelectedBreakItem();
  }

  void _reconcileSelections() {
    if (selectedCategory != null) {
      final matched =
          _categories.where((item) => _sameCategory(item, selectedCategory!));
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
        !availableContents
            .any((item) => _sameContent(item, selectedContent!))) {
      selectedContent = _defaultContentForSelectedCategory();
    }
    if (selectedContent != null && !isContentSelectable(selectedContent!)) {
      selectedContent = availableContents.firstWhere(
        isContentSelectable,
        orElse: () => _defaultContentForSelectedCategory() ?? selectedContent!,
      );
    }

    if (!isEditMode && _autoTrackCurrentTime) {
      occurredAt = DateTime.now();
    }

    points =
        _effectivePointsForContent(selectedContent, fallbackPoints: points);
    _ensureSelectedBreakItem();
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
      points: record.points,
      defaultPoints: record.points,
      allowAdjust: false,
      minPoints: record.points,
      maxPoints: record.points,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    );
  }

  RewardOption? _resolveBreakItem(StudyRecord record) {
    final feedbackId = record.feedbackOptionId ?? record.rewardOptionId;
    final feedbackName =
        record.feedbackNameSnapshot ?? record.rewardNameSnapshot;

    for (final item in [..._shortBreakOptions, ..._longBreakOptions]) {
      if (item.id == feedbackId) {
        return item;
      }
    }
    if (feedbackId == null && feedbackName.trim().isEmpty) {
      return null;
    }
    return RewardOption(
      id: feedbackId,
      name: '${feedbackName.isEmpty ? '未设置休息' : feedbackName}（已删除）',
      type: record.breakType ?? 'short',
      sortOrder: -1,
      isEnabled: false,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    );
  }

  List<CategoryOption> _visibleCategories() {
    final result =
        _categories.where((item) => item.isEnabled).toList(growable: true);
    final selected = selectedCategory;
    if (selected != null &&
        !result.any((item) => _sameCategory(item, selected))) {
      result.insert(0, selected);
    }
    return result;
  }

  List<ContentOption> _visibleContentOptions() {
    final selectedCategoryId = selectedCategory?.id;
    final result = _contentOptions.where((item) {
      final allowedForCategory = item.categoryId == null ||
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

  List<RewardOption> _visibleBreakOptions() {
    final source = isLongBreak ? _longBreakOptions : _shortBreakOptions;
    final result =
        source.where((item) => item.isEnabled).toList(growable: true);
    final selected = selectedBreakItem;
    if (selected != null &&
        selected.type == currentBreakType &&
        !result.any((item) => _sameReward(item, selected))) {
      result.insert(0, selected);
    }
    return result;
  }

  List<WeaknessOption> _visibleWeaknessOptions() {
    final selectedContentId = selectedContent?.id;
    final selectedCategoryId = selectedCategory?.id;
    final contentSpecific = _weaknessOptions.where((item) {
      return item.isEnabled &&
          item.contentOptionId != null &&
          selectedContentId != null &&
          item.contentOptionId == selectedContentId;
    }).toList(growable: false);
    if (contentSpecific.isNotEmpty) {
      return contentSpecific.take(5).toList(growable: false);
    }
    return _weaknessOptions
        .where((item) {
          return item.isEnabled &&
              item.contentOptionId == null &&
              item.categoryId != null &&
              selectedCategoryId != null &&
              item.categoryId == selectedCategoryId;
        })
        .take(5)
        .toList(growable: false);
  }

  List<ImprovementOption> _visibleImprovementOptions() {
    final selectedContentId = selectedContent?.id;
    final selectedCategoryId = selectedCategory?.id;
    final contentSpecific = _improvementOptions.where((item) {
      return item.isEnabled &&
          item.contentOptionId != null &&
          selectedContentId != null &&
          item.contentOptionId == selectedContentId;
    }).toList(growable: false);
    if (contentSpecific.isNotEmpty) {
      return contentSpecific.take(5).toList(growable: false);
    }
    return _improvementOptions
        .where((item) {
          return item.isEnabled &&
              item.contentOptionId == null &&
              item.categoryId != null &&
              selectedCategoryId != null &&
              item.categoryId == selectedCategoryId;
        })
        .take(5)
        .toList(growable: false);
  }

  ContentOption? _defaultContentForSelectedCategory() {
    final selectedCategoryId = selectedCategory?.id;
    final result = _contentOptions.where((item) {
      final allowedForCategory = item.categoryId == null ||
          (selectedCategoryId != null && item.categoryId == selectedCategoryId);
      return item.isEnabled && allowedForCategory;
    }).toList(growable: true);
    result.sort(_compareContentOptions);
    for (final item in result) {
      if (isContentSelectable(item)) {
        return item;
      }
    }
    return result.firstOrNull;
  }

  bool isContentSelectable(ContentOption item) {
    if (isEditMode &&
        selectedContent != null &&
        _sameContent(item, selectedContent!)) {
      return true;
    }
    if (_effectivePointsForContent(item) >= 2) {
      return true;
    }
    final categoryId = item.categoryId ?? selectedCategory?.id;
    if (categoryId == null) {
      return true;
    }
    return (_lowPointCategoryCounts[categoryId] ?? 0) < 1;
  }

  void _applySelectedContentDefaults({required bool resetDetailFields}) {
    final content = selectedContent;
    points = _effectivePointsForContent(content, fallbackPoints: points);
    if (resetDetailFields) {
      _resetDetailFields();
    }
  }

  void _ensureSelectedBreakItem() {
    final options = _visibleBreakOptions();
    if (selectedBreakItem != null &&
        selectedBreakItem!.type == currentBreakType &&
        options.any((item) => _sameReward(item, selectedBreakItem!))) {
      return;
    }
    selectedBreakItem = options.firstOrNull;
  }

  void _resetDetailFields() {
    detailAmountText = null;
    questionCount = null;
    wrongCount = null;
    weaknessTags = const [];
    improvementTags = const [];
    notes = null;
  }

  void _startClockTicker() {
    if (isEditMode) {
      return;
    }

    _clockTimer?.cancel();
    _scheduleNextClockTick();
  }

  void _scheduleNextClockTick() {
    final now = DateTime.now();
    final nextMinute = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute + 1,
    );
    _clockTimer = Timer(nextMinute.difference(now), () {
      if (_autoTrackCurrentTime) {
        final current = DateTime.now();
        occurredAt = current;
        notifyListeners();
        unawaited(_refreshAutoTrackedDerivedState(current));
      }
      if (!isEditMode) {
        _scheduleNextClockTick();
      }
    });
  }

  Future<void> _refreshAutoTrackedDerivedState(DateTime now) async {
    if (_isAutoRefreshingDerivedState || !_autoTrackCurrentTime) {
      return;
    }
    _isAutoRefreshingDerivedState = true;
    occurredAt = now;
    try {
      await _refreshSessionCompletedCount(anchor: now);
      await _refreshDailyLimitsAndPlan();
      _ensureSelectedBreakItem();
      _reconcileSelections();
    } finally {
      _isAutoRefreshingDerivedState = false;
    }
    notifyListeners();
  }

  Future<void> _refreshSessionCompletedCount({
    required DateTime anchor,
    int? excludingRecordId,
  }) async {
    sessionCompletedCount =
        await studyRecordRepository.countSessionRecordsBefore(
      anchor,
      gapMinutes: sessionGapMinutes,
      excludingRecordId: excludingRecordId,
    );
  }

  Future<void> _refreshLowPointCategoryCounts() async {
    _lowPointCategoryCounts =
        await studyRecordRepository.countLowPointRecordsByCategoryOnDay(
      occurredAt,
      excludingRecordId: editingRecord?.id,
    );
  }

  Future<void> _refreshDailyTypeCounts() async {
    _dailyTypeCounts = await studyRecordRepository.countRecordsByPointsOnDay(
      occurredAt,
      excludingRecordId: editingRecord?.id,
    );
  }

  Future<void> _refreshDailyLimitsAndPlan() async {
    await Future.wait([
      _refreshLowPointCategoryCounts(),
      _refreshDailyTypeCounts(),
    ]);
  }

  bool _sameCategory(CategoryOption a, CategoryOption b) =>
      a.id == b.id && a.name == b.name;

  bool _sameContent(ContentOption a, ContentOption b) =>
      a.id == b.id && a.name == b.name;

  bool _sameReward(RewardOption a, RewardOption b) =>
      a.id == b.id && a.name == b.name;

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

  int _effectivePointsForContent(
    ContentOption? content, {
    int? fallbackPoints,
  }) {
    if (content == null) {
      return fallbackPoints ?? 1;
    }
    return StudyTypeUtils.recommendedPointsForContent(
      categoryName: _categoryNameForContent(content),
      contentName: content.name,
      fallbackPoints: fallbackPoints ?? content.points,
    );
  }

  String? _categoryNameForContent(ContentOption content) {
    final categoryId = content.categoryId ?? selectedCategory?.id;
    if (categoryId == null) {
      return selectedCategory?.name;
    }
    final match =
        _categories.where((item) => item.id == categoryId).firstOrNull;
    return match?.name ?? selectedCategory?.name;
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

