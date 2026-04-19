import 'package:flutter_test/flutter_test.dart';
import 'package:study_pomodoro_record/core/utils/study_date_utils.dart';
import 'package:study_pomodoro_record/data/models/statistics_models.dart';

void main() {
  group('统计周期计算', () {
    test('日汇总范围正确', () {
      final anchor = DateTime(2026, 4, 11, 15, 30);
      final range = StudyDateUtils.buildPeriodRange(TimeGranularity.day, anchor);

      expect(range.start, DateTime(2026, 4, 11));
      expect(range.endExclusive, DateTime(2026, 4, 12));
    });

    test('周汇总按 ISO 周一到周日计算', () {
      final anchor = DateTime(2026, 4, 11);
      final range = StudyDateUtils.buildPeriodRange(TimeGranularity.week, anchor);

      expect(range.start, DateTime(2026, 4, 6));
      expect(range.endExclusive, DateTime(2026, 4, 13));
    });

    test('月汇总的环比在月末日期下也不会跑偏', () {
      final anchor = DateTime(2026, 3, 31);
      final previous = StudyDateUtils.previousPeriod(TimeGranularity.month, anchor);

      expect(previous.start, DateTime(2026, 2, 1));
      expect(previous.endExclusive, DateTime(2026, 3, 1));
    });

    test('闰年 2 月 29 日的同比会钳制到去年 2 月 28 日', () {
      final anchor = DateTime(2024, 2, 29);
      final yoy = StudyDateUtils.yearOverYearPeriod(TimeGranularity.day, anchor);

      expect(yoy.start, DateTime(2023, 2, 28));
      expect(yoy.endExclusive, DateTime(2023, 3, 1));
    });

    test('年度维度向前切换一年时保留月份并处理闰年', () {
      final shifted = StudyDateUtils.shiftAnchor(
        TimeGranularity.year,
        DateTime(2024, 2, 29, 10, 0),
        -1,
      );

      expect(shifted, DateTime(2023, 2, 28, 10, 0));
    });
  });
}
