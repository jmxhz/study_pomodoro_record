import 'package:intl/intl.dart';

import '../../data/models/statistics_models.dart';
import '../../data/models/study_record.dart';
import 'study_date_utils.dart';

class StatisticsCalculator {
  StatisticsBundle build({
    required TimeGranularity granularity,
    required DateTime anchorDate,
    required List<StudyRecord> currentRecords,
    required List<StudyRecord> breakdownRecords,
    required List<StudyRecord> previousRecords,
    required List<StudyRecord> yoyRecords,
    required List<String> configuredCategoryNames,
  }) {
    final currentPeriod = StudyDateUtils.buildPeriodRange(granularity, anchorDate);
    final previousPeriod = StudyDateUtils.previousPeriod(granularity, anchorDate);
    final yoyPeriod = StudyDateUtils.yearOverYearPeriod(granularity, anchorDate);

    final currentPomodoro = _sumPomodoro(currentRecords);
    final previousPomodoro = _sumPomodoro(previousRecords);
    final yoyPomodoro = _sumPomodoro(yoyRecords);

    final currentPoints = _sumPoints(currentRecords);
    final previousPoints = _sumPoints(previousRecords);
    final yoyPoints = _sumPoints(yoyRecords);

    final categoryNames = _buildCategoryNames(
      configuredCategoryNames: configuredCategoryNames,
      currentRecords: currentRecords,
      previousRecords: previousRecords,
      yoyRecords: yoyRecords,
    );

    final currentByCategory = _groupByCategory(currentRecords);
    final previousByCategory = _groupByCategory(previousRecords);
    final yoyByCategory = _groupByCategory(yoyRecords);

    final categorySummaries = categoryNames.map((name) {
      final currentItems = currentByCategory[name] ?? const <StudyRecord>[];
      final previousItems = previousByCategory[name] ?? const <StudyRecord>[];
      final yoyItems = yoyByCategory[name] ?? const <StudyRecord>[];

      final currentPomodoroValue = _sumPomodoro(currentItems);
      final previousPomodoroValue = _sumPomodoro(previousItems);
      final yoyPomodoroValue = _sumPomodoro(yoyItems);

      final currentPointsValue = _sumPoints(currentItems);
      final previousPointsValue = _sumPoints(previousItems);
      final yoyPointsValue = _sumPoints(yoyItems);

      return CategorySummary(
        categoryName: name,
        pomodoro: MetricSummary(
          current: currentPomodoroValue,
          ring: buildComparison(currentPomodoroValue, previousPomodoroValue),
          yoy: buildComparison(currentPomodoroValue, yoyPomodoroValue),
        ),
        points: MetricSummary(
          current: currentPointsValue,
          ring: buildComparison(currentPointsValue, previousPointsValue),
          yoy: buildComparison(currentPointsValue, yoyPointsValue),
        ),
      );
    }).toList(growable: false);

    final details = [...currentRecords]
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    return StatisticsBundle(
      granularity: granularity,
      anchorDate: anchorDate,
      currentPeriod: currentPeriod,
      previousPeriod: previousPeriod,
      yoyPeriod: yoyPeriod,
      totalPomodoro: MetricSummary(
        current: currentPomodoro,
        ring: buildComparison(currentPomodoro, previousPomodoro),
        yoy: buildComparison(currentPomodoro, yoyPomodoro),
      ),
      totalPoints: MetricSummary(
        current: currentPoints,
        ring: buildComparison(currentPoints, previousPoints),
        yoy: buildComparison(currentPoints, yoyPoints),
      ),
      categorySummaries: categorySummaries,
      subPeriodSummaries: _buildSubPeriodSummaries(
        granularity: granularity,
        currentPeriod: currentPeriod,
        records: breakdownRecords,
      ),
      details: details,
    );
  }

  ComparisonValue buildComparison(int current, int compareValue) {
    final delta = current - compareValue;
    final direction =
        delta > 0 ? TrendDirection.up : delta < 0 ? TrendDirection.down : TrendDirection.flat;

    final percentText = compareValue == 0
        ? current == 0
            ? '0%'
            : '--'
        : '${delta > 0 ? '+' : ''}${(delta / compareValue * 100).toStringAsFixed(1)}%';

    return ComparisonValue(
      current: current,
      compareValue: compareValue,
      delta: delta,
      percentText: percentText,
      direction: direction,
    );
  }

  int _sumPomodoro(List<StudyRecord> records) =>
      records.fold<int>(0, (sum, item) => sum + item.pomodoroCount);

  int _sumPoints(List<StudyRecord> records) =>
      records.fold<int>(0, (sum, item) => sum + item.points);

  List<SubPeriodSummary> _buildSubPeriodSummaries({
    required TimeGranularity granularity,
    required PeriodRange currentPeriod,
    required List<StudyRecord> records,
  }) {
    switch (granularity) {
      case TimeGranularity.day:
        return const [];
      case TimeGranularity.week:
        return List<SubPeriodSummary>.generate(7, (index) {
          final start = currentPeriod.start.add(Duration(days: index));
          final endExclusive = start.add(const Duration(days: 1));
          return _buildSubPeriodSummary(
            granularity: TimeGranularity.day,
            anchorDate: start,
            title: DateFormat('M/d').format(start),
            subtitle: _weekdayLabel(start.weekday),
            records: _filterRecords(records, start, endExclusive),
          );
        }, growable: false);
      case TimeGranularity.month:
        final dayCount = currentPeriod.endExclusive.difference(currentPeriod.start).inDays;
        return List<SubPeriodSummary>.generate(dayCount, (index) {
          final start = currentPeriod.start.add(Duration(days: index));
          final endExclusive = start.add(const Duration(days: 1));
          return _buildSubPeriodSummary(
            granularity: TimeGranularity.day,
            anchorDate: start,
            title: '${start.day}',
            subtitle: '',
            records: _filterRecords(records, start, endExclusive),
          );
        }, growable: false);
      case TimeGranularity.year:
        return List<SubPeriodSummary>.generate(12, (index) {
          final start = DateTime(currentPeriod.start.year, index + 1);
          final endExclusive = DateTime(currentPeriod.start.year, index + 2);
          return _buildSubPeriodSummary(
            granularity: TimeGranularity.month,
            anchorDate: start,
            title: '${index + 1}月',
            subtitle: DateFormat('yyyy年M月').format(start),
            records: _filterRecords(records, start, endExclusive),
          );
        }, growable: false);
    }
  }

  SubPeriodSummary _buildSubPeriodSummary({
    required TimeGranularity granularity,
    required DateTime anchorDate,
    required String title,
    required String subtitle,
    required List<StudyRecord> records,
  }) {
    return SubPeriodSummary(
      granularity: granularity,
      anchorDate: anchorDate,
      title: title,
      subtitle: subtitle,
      pomodoroCount: _sumPomodoro(records),
      points: _sumPoints(records),
      recordCount: records.length,
    );
  }

  List<StudyRecord> _filterRecords(
    List<StudyRecord> records,
    DateTime start,
    DateTime endExclusive,
  ) {
    return records
        .where(
          (record) =>
              !record.occurredAt.isBefore(start) && record.occurredAt.isBefore(endExclusive),
        )
        .toList(growable: false);
  }

  Map<String, List<StudyRecord>> _groupByCategory(List<StudyRecord> records) {
    final grouped = <String, List<StudyRecord>>{};
    for (final record in records) {
      grouped.putIfAbsent(record.categoryNameSnapshot, () => <StudyRecord>[]).add(record);
    }
    return grouped;
  }

  List<String> _buildCategoryNames({
    required List<String> configuredCategoryNames,
    required List<StudyRecord> currentRecords,
    required List<StudyRecord> previousRecords,
    required List<StudyRecord> yoyRecords,
  }) {
    final names = <String>{}..addAll(configuredCategoryNames);
    for (final record in [...currentRecords, ...previousRecords, ...yoyRecords]) {
      names.add(record.categoryNameSnapshot);
    }
    return names.toList(growable: false);
  }

  String _weekdayLabel(int weekday) {
    const labels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return labels[weekday - 1];
  }
}
