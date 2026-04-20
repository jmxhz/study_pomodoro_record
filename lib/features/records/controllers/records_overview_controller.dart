import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../app/app_services.dart';
import '../../../core/utils/statistics_calculator.dart';
import '../../../core/utils/study_date_utils.dart';
import '../../../data/models/category_option.dart';
import '../../../data/models/statistics_models.dart';
import '../../../data/models/study_record.dart';
import '../../../data/repositories/options_repository.dart';
import '../../../data/repositories/reward_redemption_repository.dart';
import '../../../data/repositories/study_record_repository.dart';

class RecordsOverviewController extends ChangeNotifier {
  RecordsOverviewController({
    required this.optionsRepository,
    required this.studyRecordRepository,
    required this.rewardRedemptionRepository,
    required this.dataSyncNotifier,
  }) {
    _syncListener = () {
      load();
    };
    dataSyncNotifier.addListener(_syncListener);
    load();
  }

  final OptionsRepository optionsRepository;
  final StudyRecordRepository studyRecordRepository;
  final RewardRedemptionRepository rewardRedemptionRepository;
  final DataSyncNotifier dataSyncNotifier;
  final StatisticsCalculator _calculator = StatisticsCalculator();

  late final VoidCallback _syncListener;
  bool _isLoadingInProgress = false;
  bool _reloadQueued = false;

  bool isLoading = true;
  String? errorMessage;
  TimeGranularity granularity = TimeGranularity.day;
  DateTime anchorDate = DateTime.now();
  StatisticsBundle? statistics;
  List<ContentSummary> contentSummaries = const [];
  List<TagSummary> topWeaknesses = const [];
  List<TagSummary> topImprovements = const [];

  Future<void> load() async {
    if (_isLoadingInProgress) {
      _reloadQueued = true;
      return;
    }
    _isLoadingInProgress = true;
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final currentPeriod =
          StudyDateUtils.buildPeriodRange(granularity, anchorDate);
      final previousPeriod =
          StudyDateUtils.previousPeriod(granularity, anchorDate);
      final yoyPeriod =
          StudyDateUtils.yearOverYearPeriod(granularity, anchorDate);
      final breakdownCoverage = _buildBreakdownCoverageRange(currentPeriod);

      final results = await Future.wait([
        studyRecordRepository.getRecordsBetween(
          currentPeriod.start,
          currentPeriod.endExclusive,
          recordKind: 'study',
        ),
        studyRecordRepository.getRecordsBetween(
          previousPeriod.start,
          previousPeriod.endExclusive,
          recordKind: 'study',
        ),
        studyRecordRepository.getRecordsBetween(
          yoyPeriod.start,
          yoyPeriod.endExclusive,
          recordKind: 'study',
        ),
        studyRecordRepository.getRecordsBetween(
          breakdownCoverage.start,
          breakdownCoverage.endExclusive,
          recordKind: 'study',
        ),
        optionsRepository.getCategories(),
      ]);

      final currentRecords = results[0] as List<StudyRecord>;
      final previousRecords = results[1] as List<StudyRecord>;
      final yoyRecords = results[2] as List<StudyRecord>;
      final breakdownRecords = results[3] as List<StudyRecord>;
      final categories = results[4] as List<CategoryOption>;
      contentSummaries = _buildContentSummaries(currentRecords);
      topWeaknesses =
          _buildTagSummaries(currentRecords, (item) => item.weaknessTags);
      topImprovements =
          _buildTagSummaries(currentRecords, (item) => item.improvementTags);

      statistics = _calculator.build(
        granularity: granularity,
        anchorDate: anchorDate,
        currentRecords: currentRecords,
        breakdownRecords: breakdownRecords,
        previousRecords: previousRecords,
        yoyRecords: yoyRecords,
        configuredCategoryNames:
            categories.map((item) => item.name).toList(growable: false),
      );
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      _isLoadingInProgress = false;
      isLoading = false;
      notifyListeners();
    }
    if (_reloadQueued) {
      _reloadQueued = false;
      unawaited(load());
    }
  }

  Future<void> setGranularity(TimeGranularity value) async {
    if (granularity == value) {
      return;
    }
    granularity = value;
    await load();
  }

  Future<void> setAnchorDate(DateTime value) async {
    anchorDate = value;
    await load();
  }

  Future<void> shiftPeriod(int offset) async {
    anchorDate = StudyDateUtils.shiftAnchor(granularity, anchorDate, offset);
    await load();
  }

  Future<void> drillDownTo(
      TimeGranularity value, DateTime valueAnchorDate) async {
    granularity = value;
    anchorDate = valueAnchorDate;
    await load();
  }

  Future<void> deleteRecord(StudyRecord record) async {
    if (record.id == null) {
      return;
    }
    await studyRecordRepository.deleteRecord(record.id!);
    dataSyncNotifier.notifyChanged();
    await load();
  }

  List<ContentSummary> _buildContentSummaries(List<StudyRecord> records) {
    final grouped = <String, List<StudyRecord>>{};
    for (final record in records) {
      grouped
          .putIfAbsent(record.contentNameSnapshot, () => <StudyRecord>[])
          .add(record);
    }

    final result = grouped.entries
        .map(
          (entry) => ContentSummary(
            contentName: entry.key,
            recordCount: entry.value.length,
            pomodoroCount: entry.value
                .fold<int>(0, (sum, item) => sum + item.pomodoroCount),
            points: entry.value.fold<int>(0, (sum, item) => sum + item.points),
          ),
        )
        .toList(growable: false);
    result.sort((a, b) {
      final pointsCompare = b.points.compareTo(a.points);
      if (pointsCompare != 0) {
        return pointsCompare;
      }
      return a.contentName.compareTo(b.contentName);
    });
    return result;
  }

  List<TagSummary> _buildTagSummaries(
    List<StudyRecord> records,
    List<String> Function(StudyRecord record) selector,
  ) {
    final counts = <String, int>{};
    for (final record in records) {
      for (final tag in selector(record)) {
        counts.update(tag, (value) => value + 1, ifAbsent: () => 1);
      }
    }

    final result = counts.entries
        .map((entry) => TagSummary(name: entry.key, count: entry.value))
        .toList(growable: false);
    result.sort((a, b) {
      final countCompare = b.count.compareTo(a.count);
      if (countCompare != 0) {
        return countCompare;
      }
      return a.name.compareTo(b.name);
    });
    return result.take(5).toList(growable: false);
  }

  @override
  void dispose() {
    dataSyncNotifier.removeListener(_syncListener);
    super.dispose();
  }

  ({DateTime start, DateTime endExclusive}) _buildBreakdownCoverageRange(
      PeriodRange currentPeriod) {
    return (
      start: currentPeriod.start,
      endExclusive: currentPeriod.endExclusive
    );
  }
}
