import 'package:flutter_test/flutter_test.dart';
import 'package:study_pomodoro_record/core/utils/statistics_calculator.dart';
import 'package:study_pomodoro_record/data/models/statistics_models.dart';

void main() {
  final calculator = StatisticsCalculator();

  group('环比同比计算', () {
    test('正常百分比变化计算正确', () {
      final comparison = calculator.buildComparison(10, 8);

      expect(comparison.delta, 2);
      expect(comparison.percentText, '+25.0%');
      expect(comparison.direction, TrendDirection.up);
    });

    test('对比周期为 0 且当前也为 0 时显示 0%', () {
      final comparison = calculator.buildComparison(0, 0);

      expect(comparison.delta, 0);
      expect(comparison.percentText, '0%');
      expect(comparison.direction, TrendDirection.flat);
    });

    test('对比周期为 0 且当前大于 0 时显示 --', () {
      final comparison = calculator.buildComparison(3, 0);

      expect(comparison.delta, 3);
      expect(comparison.percentText, '--');
      expect(comparison.direction, TrendDirection.up);
    });
  });
}
