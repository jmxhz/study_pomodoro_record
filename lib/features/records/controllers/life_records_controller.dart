import 'package:flutter/foundation.dart';

import '../../../app/app_services.dart';
import '../../../core/utils/statistics_calculator.dart';
import '../../../core/utils/study_date_utils.dart';
import '../../../data/models/statistics_models.dart';
import '../../../data/models/study_record.dart';
import '../../../data/repositories/study_record_repository.dart';

class LifeRecordsController extends ChangeNotifier {
  LifeRecordsController({
    required this.studyRecordRepository,
    required this.dataSyncNotifier,
  }) {
    _syncListener = () {
      load();
    };
    dataSyncNotifier.addListener(_syncListener);
    load();
  }

  final StudyRecordRepository studyRecordRepository;
  final DataSyncNotifier dataSyncNotifier;
  final StatisticsCalculator _calculator = StatisticsCalculator();
  late final VoidCallback _syncListener;

  bool isLoading = true;
  String? errorMessage;
  TimeGranularity granularity = TimeGranularity.day;
  DateTime anchorDate = DateTime.now();
  List<StudyRecord> details = const [];
  List<LifeHabitSummary> habitSummaries = const [];
  int totalPoints = 0;
  int totalCount = 0;
  MetricSummary totalCountSummary = const MetricSummary(
    current: 0,
    ring: ComparisonValue(
      current: 0,
      compareValue: 0,
      delta: 0,
      percentText: '0%',
      direction: TrendDirection.flat,
    ),
    yoy: ComparisonValue(
      current: 0,
      compareValue: 0,
      delta: 0,
      percentText: '0%',
      direction: TrendDirection.flat,
    ),
  );
  MetricSummary totalPointsSummary = const MetricSummary(
    current: 0,
    ring: ComparisonValue(
      current: 0,
      compareValue: 0,
      delta: 0,
      percentText: '0%',
      direction: TrendDirection.flat,
    ),
    yoy: ComparisonValue(
      current: 0,
      compareValue: 0,
      delta: 0,
      percentText: '0%',
      direction: TrendDirection.flat,
    ),
  );
  List<SubPeriodSummary> subPeriodSummaries = const [];

  Future<void> load() async {
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
      final records = await studyRecordRepository.getLifeRecordsBetween(
        currentPeriod.start,
        currentPeriod.endExclusive,
      );
      final previousRecords = await studyRecordRepository.getLifeRecordsBetween(
        previousPeriod.start,
        previousPeriod.endExclusive,
      );
      final yoyRecords = await studyRecordRepository.getLifeRecordsBetween(
        yoyPeriod.start,
        yoyPeriod.endExclusive,
      );
      details = records;
      totalCount = records.length;
      totalPoints = records.fold<int>(0, (sum, item) => sum + item.points);
      habitSummaries = _buildHabitSummaries(records);
      final bundle = _calculator.build(
        granularity: granularity,
        anchorDate: anchorDate,
        currentRecords: records,
        breakdownRecords: records,
        previousRecords: previousRecords,
        yoyRecords: yoyRecords,
        configuredCategoryNames: const ['生活'],
      );
      totalCountSummary = bundle.totalPomodoro;
      totalPointsSummary = bundle.totalPoints;
      subPeriodSummaries = bundle.subPeriodSummaries;
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
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

  Future<void> deleteRecord(StudyRecord record) async {
    if (record.id == null) {
      return;
    }
    await studyRecordRepository.deleteRecord(record.id!);
    dataSyncNotifier.notifyChanged();
    await load();
  }

  List<LifeHabitSummary> _buildHabitSummaries(List<StudyRecord> records) {
    final grouped = <String, List<StudyRecord>>{};
    for (final record in records) {
      final key = record.contentNameSnapshot.trim().isEmpty
          ? '未命名习惯'
          : record.contentNameSnapshot;
      grouped.putIfAbsent(key, () => <StudyRecord>[]).add(record);
    }
    final result = grouped.entries
        .map((entry) => LifeHabitSummary(
              name: entry.key,
              count: entry.value.length,
              points:
                  entry.value.fold<int>(0, (sum, item) => sum + item.points),
            ))
        .toList(growable: false);
    result.sort((a, b) {
      final pointsCompare = b.points.compareTo(a.points);
      if (pointsCompare != 0) {
        return pointsCompare;
      }
      return a.name.compareTo(b.name);
    });
    return result;
  }

  @override
  void dispose() {
    dataSyncNotifier.removeListener(_syncListener);
    super.dispose();
  }
}

class LifeHabitSummary {
  const LifeHabitSummary({
    required this.name,
    required this.count,
    required this.points,
  });

  final String name;
  final int count;
  final int points;
}
