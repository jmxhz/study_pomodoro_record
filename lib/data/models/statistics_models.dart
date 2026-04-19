import 'study_record.dart';

enum TimeGranularity { day, week, month, year }

enum TrendDirection { up, down, flat }

class PeriodRange {
  const PeriodRange({
    required this.start,
    required this.endExclusive,
    required this.label,
  });

  final DateTime start;
  final DateTime endExclusive;
  final String label;
}

class ComparisonValue {
  const ComparisonValue({
    required this.current,
    required this.compareValue,
    required this.delta,
    required this.percentText,
    required this.direction,
  });

  final int current;
  final int compareValue;
  final int delta;
  final String percentText;
  final TrendDirection direction;

  bool get isPositive => delta > 0;

  bool get isNegative => delta < 0;
}

class MetricSummary {
  const MetricSummary({
    required this.current,
    required this.ring,
    required this.yoy,
  });

  final int current;
  final ComparisonValue ring;
  final ComparisonValue yoy;
}

class CategorySummary {
  const CategorySummary({
    required this.categoryName,
    required this.pomodoro,
    required this.points,
  });

  final String categoryName;
  final MetricSummary pomodoro;
  final MetricSummary points;
}

class StatisticsBundle {
  const StatisticsBundle({
    required this.granularity,
    required this.anchorDate,
    required this.currentPeriod,
    required this.previousPeriod,
    required this.yoyPeriod,
    required this.totalPomodoro,
    required this.totalPoints,
    required this.categorySummaries,
    required this.subPeriodSummaries,
    required this.details,
  });

  final TimeGranularity granularity;
  final DateTime anchorDate;
  final PeriodRange currentPeriod;
  final PeriodRange previousPeriod;
  final PeriodRange yoyPeriod;
  final MetricSummary totalPomodoro;
  final MetricSummary totalPoints;
  final List<CategorySummary> categorySummaries;
  final List<SubPeriodSummary> subPeriodSummaries;
  final List<StudyRecord> details;
}

class SubPeriodSummary {
  const SubPeriodSummary({
    required this.granularity,
    required this.anchorDate,
    required this.title,
    required this.subtitle,
    required this.pomodoroCount,
    required this.points,
    required this.recordCount,
  });

  final TimeGranularity granularity;
  final DateTime anchorDate;
  final String title;
  final String subtitle;
  final int pomodoroCount;
  final int points;
  final int recordCount;
}

class ContentSummary {
  const ContentSummary({
    required this.contentName,
    required this.recordCount,
    required this.pomodoroCount,
    required this.points,
  });

  final String contentName;
  final int recordCount;
  final int pomodoroCount;
  final int points;
}

class TagSummary {
  const TagSummary({
    required this.name,
    required this.count,
  });

  final String name;
  final int count;
}
