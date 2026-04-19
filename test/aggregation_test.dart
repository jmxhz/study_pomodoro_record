import 'package:flutter_test/flutter_test.dart';
import 'package:study_pomodoro_record/core/utils/statistics_calculator.dart';
import 'package:study_pomodoro_record/data/models/statistics_models.dart';
import 'package:study_pomodoro_record/data/models/study_record.dart';

void main() {
  final calculator = StatisticsCalculator();

  StudyRecord record({
    required int id,
    required DateTime occurredAt,
    required String category,
    required String content,
    required String reward,
    required int pomodoro,
    required int points,
  }) {
    return StudyRecord(
      id: id,
      occurredAt: occurredAt,
      categoryId: id,
      categoryNameSnapshot: category,
      contentOptionId: id,
      contentNameSnapshot: content,
      rewardOptionId: id,
      rewardNameSnapshot: reward,
      pomodoroCount: pomodoro,
      points: points,
      createdAt: occurredAt,
      updatedAt: occurredAt,
    );
  }

  test('分类汇总和总汇总会按当前周期数据正确聚合', () {
    final statistics = calculator.build(
      granularity: TimeGranularity.day,
      anchorDate: DateTime(2026, 4, 11),
      currentRecords: [
        record(
          id: 1,
          occurredAt: DateTime(2026, 4, 11, 9),
          category: '行测',
          content: '判断推理',
          reward: '喝水',
          pomodoro: 2,
          points: 3,
        ),
        record(
          id: 2,
          occurredAt: DateTime(2026, 4, 11, 21),
          category: '英语',
          content: '阅读',
          reward: '散步',
          pomodoro: 1,
          points: 2,
        ),
      ],
      breakdownRecords: [
        record(
          id: 1,
          occurredAt: DateTime(2026, 4, 11, 9),
          category: '琛屾祴',
          content: '鍒ゆ柇鎺ㄧ悊',
          reward: '鍠濇按',
          pomodoro: 2,
          points: 3,
        ),
        record(
          id: 2,
          occurredAt: DateTime(2026, 4, 11, 21),
          category: '鑻辫',
          content: '闃呰',
          reward: '鏁ｆ',
          pomodoro: 1,
          points: 2,
        ),
      ],
      previousRecords: [
        record(
          id: 3,
          occurredAt: DateTime(2026, 4, 10, 20),
          category: '行测',
          content: '判断推理',
          reward: '听歌',
          pomodoro: 1,
          points: 1,
        ),
      ],
      yoyRecords: [
        record(
          id: 4,
          occurredAt: DateTime(2025, 4, 11, 20),
          category: '行测',
          content: '判断推理',
          reward: '听歌',
          pomodoro: 1,
          points: 2,
        ),
      ],
      configuredCategoryNames: const ['行测', '申论', '英语'],
    );

    expect(statistics.totalPomodoro.current, 3);
    expect(statistics.totalPoints.current, 5);
    expect(statistics.details.first.id, 2);

    final judgment = statistics.categorySummaries.firstWhere(
      (item) => item.categoryName == '行测',
    );
    expect(judgment.pomodoro.current, 2);
    expect(judgment.pomodoro.ring.delta, 1);
    expect(judgment.pomodoro.ring.percentText, '+100.0%');
    expect(judgment.points.yoy.delta, 1);

    final shenlun = statistics.categorySummaries.firstWhere(
      (item) => item.categoryName == '申论',
    );
    expect(shenlun.pomodoro.current, 0);
    expect(shenlun.points.ring.percentText, '0%');
  });
}
