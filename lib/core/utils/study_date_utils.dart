import 'package:intl/intl.dart';

import '../../data/models/statistics_models.dart';

class StudyDateUtils {
  static DateTime startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

  static DateTime startOfMonth(DateTime date) => DateTime(date.year, date.month);

  static DateTime startOfYear(DateTime date) => DateTime(date.year);

  static DateTime startOfIsoWeek(DateTime date) {
    final normalized = startOfDay(date);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  static int isoWeekYear(DateTime date) {
    final thursday = startOfDay(date).add(Duration(days: 4 - date.weekday));
    return thursday.year;
  }

  static int isoWeekNumber(DateTime date) {
    final thursday = startOfDay(date).add(Duration(days: 4 - date.weekday));
    final firstThursday = DateTime(thursday.year, 1, 4);
    final firstWeekStart = startOfIsoWeek(firstThursday);
    return thursday.difference(firstWeekStart).inDays ~/ 7 + 1;
  }

  static int weeksInIsoYear(int year) {
    return isoWeekNumber(DateTime(year, 12, 28));
  }

  static DateTime startOfIsoWeekByYearAndWeek(int isoYear, int isoWeek) {
    final firstThursday = DateTime(isoYear, 1, 4);
    final firstWeekStart = startOfIsoWeek(firstThursday);
    return firstWeekStart.add(Duration(days: (isoWeek - 1) * 7));
  }

  static PeriodRange buildPeriodRange(
    TimeGranularity granularity,
    DateTime anchor,
  ) {
    switch (granularity) {
      case TimeGranularity.day:
        final start = startOfDay(anchor);
        return PeriodRange(
          start: start,
          endExclusive: start.add(const Duration(days: 1)),
          label: DateFormat('yyyy年M月d日').format(start),
        );
      case TimeGranularity.week:
        final start = startOfIsoWeek(anchor);
        final isoYear = isoWeekYear(anchor);
        final isoWeek = isoWeekNumber(anchor);
        return PeriodRange(
          start: start,
          endExclusive: start.add(const Duration(days: 7)),
          label:
              '$isoYear 年第 ${isoWeek.toString().padLeft(2, '0')} 周 '
              '(${DateFormat('MM/dd').format(start)}-${DateFormat('MM/dd').format(start.add(const Duration(days: 6)))})',
        );
      case TimeGranularity.month:
        final start = startOfMonth(anchor);
        return PeriodRange(
          start: start,
          endExclusive: DateTime(start.year, start.month + 1),
          label: DateFormat('yyyy年M月').format(start),
        );
      case TimeGranularity.year:
        final start = startOfYear(anchor);
        return PeriodRange(
          start: start,
          endExclusive: DateTime(start.year + 1),
          label: DateFormat('yyyy年').format(start),
        );
    }
  }

  static PeriodRange previousPeriod(
    TimeGranularity granularity,
    DateTime anchor,
  ) {
    switch (granularity) {
      case TimeGranularity.day:
        return buildPeriodRange(granularity, anchor.subtract(const Duration(days: 1)));
      case TimeGranularity.week:
        return buildPeriodRange(granularity, anchor.subtract(const Duration(days: 7)));
      case TimeGranularity.month:
        return buildPeriodRange(granularity, _shiftMonth(anchor, -1));
      case TimeGranularity.year:
        return buildPeriodRange(granularity, _copyWithClamped(anchor.year - 1, anchor.month, anchor.day));
    }
  }

  static PeriodRange yearOverYearPeriod(
    TimeGranularity granularity,
    DateTime anchor,
  ) {
    switch (granularity) {
      case TimeGranularity.day:
        return buildPeriodRange(
          granularity,
          _copyWithClamped(anchor.year - 1, anchor.month, anchor.day),
        );
      case TimeGranularity.week:
        final currentIsoYear = isoWeekYear(anchor);
        final currentIsoWeek = isoWeekNumber(anchor);
        final targetIsoYear = currentIsoYear - 1;
        final targetIsoWeek = currentIsoWeek > weeksInIsoYear(targetIsoYear)
            ? weeksInIsoYear(targetIsoYear)
            : currentIsoWeek;
        final start = startOfIsoWeekByYearAndWeek(targetIsoYear, targetIsoWeek);
        return PeriodRange(
          start: start,
          endExclusive: start.add(const Duration(days: 7)),
          label:
              '$targetIsoYear 年第 ${targetIsoWeek.toString().padLeft(2, '0')} 周 '
              '(${DateFormat('MM/dd').format(start)}-${DateFormat('MM/dd').format(start.add(const Duration(days: 6)))})',
        );
      case TimeGranularity.month:
        return buildPeriodRange(
          granularity,
          _copyWithClamped(anchor.year - 1, anchor.month, anchor.day),
        );
      case TimeGranularity.year:
        return buildPeriodRange(
          granularity,
          _copyWithClamped(anchor.year - 1, anchor.month, anchor.day),
        );
    }
  }

  static DateTime shiftAnchor(
    TimeGranularity granularity,
    DateTime anchor,
    int offset,
  ) {
    switch (granularity) {
      case TimeGranularity.day:
        return anchor.add(Duration(days: offset));
      case TimeGranularity.week:
        return anchor.add(Duration(days: 7 * offset));
      case TimeGranularity.month:
        return _shiftMonth(anchor, offset);
      case TimeGranularity.year:
        return _copyWithClamped(anchor.year + offset, anchor.month, anchor.day, anchor);
    }
  }

  static DateTime _shiftMonth(DateTime anchor, int offset) {
    final totalMonths = anchor.year * 12 + anchor.month - 1 + offset;
    final year = totalMonths ~/ 12;
    final month = totalMonths % 12 + 1;
    return _copyWithClamped(year, month, anchor.day, anchor);
  }

  static DateTime _copyWithClamped(
    int year,
    int month,
    int day, [
    DateTime? source,
  ]) {
    final clampedDay = day > _daysInMonth(year, month) ? _daysInMonth(year, month) : day;
    final reference = source ?? DateTime(year, month, clampedDay);
    return DateTime(
      year,
      month,
      clampedDay,
      reference.hour,
      reference.minute,
      reference.second,
      reference.millisecond,
      reference.microsecond,
    );
  }

  static int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }
}
