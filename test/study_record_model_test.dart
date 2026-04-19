import 'package:flutter_test/flutter_test.dart';
import 'package:study_pomodoro_record/data/models/study_record.dart';

void main() {
  group('StudyRecord 新字段兼容', () {
    test('toMap 会自动回填 feedback 字段并序列化标签', () {
      final now = DateTime(2026, 4, 12, 11, 0);
      final record = StudyRecord(
        id: 1,
        occurredAt: now,
        categoryId: 1,
        categoryNameSnapshot: '英语',
        contentOptionId: 2,
        contentNameSnapshot: '单词',
        rewardOptionId: 3,
        rewardNameSnapshot: '默认短休息',
        pomodoroCount: 1,
        points: 1,
        detailAmountText: '20个单词',
        wrongCount: 4,
        weaknessTags: const ['词义不熟'],
        improvementTags: const ['复习单词'],
        notes: '晚上再复习一轮',
        createdAt: now,
        updatedAt: now,
      );

      final map = record.toMap(includeId: true);

      expect(map['feedback_option_id'], 3);
      expect(map['feedback_name_snapshot'], '默认短休息');
      expect(map['weakness_tags'], '["词义不熟"]');
      expect(map['improvement_tags'], '["复习单词"]');
      expect(map['notes'], '晚上再复习一轮');
    });

    test('fromMap 在 feedback 字段缺失时会回退到 reward 字段', () {
      final record = StudyRecord.fromMap({
        'id': 1,
        'occurred_at': '2026-04-12T11:00:00.000',
        'category_id': 1,
        'category_name_snapshot': '行测',
        'content_option_id': 2,
        'content_name_snapshot': '判断推理',
        'reward_option_id': 3,
        'reward_name_snapshot': '喝水',
        'pomodoro_count': 2,
        'points': 2,
        'detail_amount_text': '20题',
        'question_count': 20,
        'wrong_count': 6,
        'output_type': null,
        'weakness_tags': '["速度慢","粗心"]',
        'improvement_tags': '["重做错题"]',
        'notes': '复盘错题',
        'created_at': '2026-04-12T11:00:00.000',
        'updated_at': '2026-04-12T11:00:00.000',
      });

      expect(record.feedbackOptionId, 3);
      expect(record.feedbackNameSnapshot, '喝水');
      expect(record.weaknessTags, ['速度慢', '粗心']);
      expect(record.improvementTags, ['重做错题']);
    });
  });
}
