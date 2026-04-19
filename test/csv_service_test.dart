import 'package:flutter_test/flutter_test.dart';
import 'package:study_pomodoro_record/data/models/category_option.dart';
import 'package:study_pomodoro_record/data/models/content_option.dart';
import 'package:study_pomodoro_record/data/models/improvement_option.dart';
import 'package:study_pomodoro_record/data/models/redeem_reward.dart';
import 'package:study_pomodoro_record/data/models/reward_option.dart';
import 'package:study_pomodoro_record/data/models/reward_redemption_record.dart';
import 'package:study_pomodoro_record/data/models/study_record.dart';
import 'package:study_pomodoro_record/data/models/weakness_option.dart';
import 'package:study_pomodoro_record/data/repositories/csv_service_runtime.dart';

void main() {
  group('CSV 解析与导入', () {
    test('导出后的全部数据可以再次被解析', () {
      final service = CsvService.forImport(importTarget: _FakeImportTarget());
      final now = DateTime(2026, 4, 12, 9, 30);
      final files = service.buildExportFiles(
        categories: [
          CategoryOption(
            id: 1,
            name: '行测',
            sortOrder: 0,
            isEnabled: true,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        contentOptions: [
          ContentOption(
            id: 11,
            name: '资料分析',
            categoryId: 1,
            sortOrder: 0,
            isEnabled: true,
            points: 3,
            defaultPoints: 3,
            allowAdjust: true,
            minPoints: 2,
            maxPoints: 4,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        feedbackOptions: [
          RewardOption(
            id: 21,
            name: '喝水',
            sortOrder: 0,
            isEnabled: true,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        weaknessOptions: [
          WeaknessOption(
            id: 31,
            name: '速度慢',
            categoryId: 1,
            sortOrder: 0,
            isEnabled: true,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        improvementOptions: [
          ImprovementOption(
            id: 41,
            name: '限时训练',
            categoryId: 1,
            sortOrder: 0,
            isEnabled: true,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        redeemRewards: [
          RedeemReward(
            id: 51,
            name: '听歌10分钟',
            costPoints: 6,
            sortOrder: 0,
            isEnabled: true,
            note: '放松一下',
            createdAt: now,
            updatedAt: now,
          ),
        ],
        studyRecords: [
          StudyRecord(
            id: 61,
            occurredAt: now,
            categoryId: 1,
            categoryNameSnapshot: '行测',
            contentOptionId: 11,
            contentNameSnapshot: '资料分析',
            rewardOptionId: 21,
            rewardNameSnapshot: '喝水',
            feedbackOptionId: 21,
            feedbackNameSnapshot: '喝水',
            pomodoroCount: 2,
            points: 3,
            detailAmountText: '20题',
            questionCount: 20,
            wrongCount: 5,
            weaknessTags: const ['速度慢'],
            improvementTags: const ['限时训练'],
            notes: '注意时间分配',
            createdAt: now,
            updatedAt: now,
          ),
        ],
        rewardRedemptionRecords: [
          RewardRedemptionRecord(
            id: 71,
            rewardId: 51,
            rewardNameSnapshot: '听歌10分钟',
            costPoints: 6,
            redeemedAt: now,
            note: '周末使用',
            createdAt: now,
          ),
        ],
      );

      final bundle = service.parseFiles(files);

      expect(bundle.categories.single.name, '行测');
      expect(bundle.contentOptions.single.defaultPoints, 3);
      expect(bundle.contentOptions.single.maxPoints, 3);
      expect(bundle.feedbackOptions.single.name, '喝水');
      expect(bundle.weaknessOptions.single.name, '速度慢');
      expect(bundle.improvementOptions.single.name, '限时训练');
      expect(bundle.redeemRewards.single.costPoints, 6);
      expect(bundle.studyRecords.single.feedbackNameSnapshot, '喝水');
      expect(bundle.studyRecords.single.weaknessTags, ['速度慢']);
      expect(bundle.studyRecords.single.improvementTags, ['限时训练']);
      expect(bundle.rewardRedemptionRecords.single.note, '周末使用');
    });

    test('旧 reward_options.csv 仍会按本轮反馈导入', () {
      final service = CsvService.forImport(importTarget: _FakeImportTarget());
      final bundle = service.parseFiles({
        CsvService.legacyRewardOptionsFileName: '''
id,name,sort_order,is_enabled,created_at,updated_at
1,默认短休息,0,1,2026-04-12T09:30:00.000,2026-04-12T09:30:00.000
''',
      });

      expect(bundle.feedbackOptions.single.name, '默认短休息');
      expect(bundle.includedTypes, contains(CsvDatasetType.feedbackOptions));
    });

    test('追加导入只会调用本次选中文件对应的 append 流程', () async {
      final target = _FakeImportTarget();
      final service = CsvService.forImport(importTarget: target);
      final content = {
        CsvService.rewardRedemptionRecordsFileName: '''
id,reward_id,reward_name_snapshot,cost_points,redeemed_at,note,created_at
1,2,买饮料,15,2026-04-12T10:00:00.000,下午奖励,2026-04-12T10:00:00.000
''',
      };

      final summary =
          await service.importFromFileContents(content, CsvImportMode.append);

      expect(summary.rewardRedemptionRecords, 1);
      expect(target.appendedRewardRedemptionRecords, hasLength(1));
      expect(target.replacedRewardRedemptionRecords, isEmpty);
      expect(target.normalizeCalled, isTrue);
    });

    test('表头不匹配时会抛出清晰错误', () {
      final service = CsvService.forImport(importTarget: _FakeImportTarget());

      expect(
        () => service.parseFiles({
          CsvService.categoriesFileName: '''
bad_header,name
1,行测
''',
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('CSV 表头不匹配'),
          ),
        ),
      );
    });
  });
}

class _FakeImportTarget implements CsvImportTarget {
  final List<CategoryOption> appendedCategories = [];
  final List<ContentOption> appendedContentOptions = [];
  final List<RewardOption> appendedFeedbackOptions = [];
  final List<WeaknessOption> appendedWeaknessOptions = [];
  final List<ImprovementOption> appendedImprovementOptions = [];
  final List<RedeemReward> appendedRedeemRewards = [];
  final List<StudyRecord> appendedStudyRecords = [];
  final List<RewardRedemptionRecord> appendedRewardRedemptionRecords = [];
  final Map<String, String> appendedAppSettings = {};

  final List<CategoryOption> replacedCategories = [];
  final List<ContentOption> replacedContentOptions = [];
  final List<RewardOption> replacedFeedbackOptions = [];
  final List<WeaknessOption> replacedWeaknessOptions = [];
  final List<ImprovementOption> replacedImprovementOptions = [];
  final List<RedeemReward> replacedRedeemRewards = [];
  final List<StudyRecord> replacedStudyRecords = [];
  final List<RewardRedemptionRecord> replacedRewardRedemptionRecords = [];
  final Map<String, String> replacedAppSettings = {};

  bool normalizeCalled = false;

  @override
  Future<void> appendCategories(List<CategoryOption> items) async {
    appendedCategories.addAll(items);
  }

  @override
  Future<void> appendContentOptions(List<ContentOption> items) async {
    appendedContentOptions.addAll(items);
  }

  @override
  Future<void> appendFeedbackOptions(List<RewardOption> items) async {
    appendedFeedbackOptions.addAll(items);
  }

  @override
  Future<void> appendImprovementOptions(List<ImprovementOption> items) async {
    appendedImprovementOptions.addAll(items);
  }

  @override
  Future<void> appendRedeemRewards(List<RedeemReward> items) async {
    appendedRedeemRewards.addAll(items);
  }

  @override
  Future<void> appendRewardRedemptionRecords(
      List<RewardRedemptionRecord> items) async {
    appendedRewardRedemptionRecords.addAll(items);
  }

  @override
  Future<void> appendAppSettings(Map<String, String> items) async {
    appendedAppSettings.addAll(items);
  }

  @override
  Future<void> appendStudyRecords(List<StudyRecord> items) async {
    appendedStudyRecords.addAll(items);
  }


  @override
  Future<void> appendWeaknessOptions(List<WeaknessOption> items) async {
    appendedWeaknessOptions.addAll(items);
  }

  @override
  Future<void> normalizeAfterImport() async {
    normalizeCalled = true;
  }

  @override
  Future<void> replaceCategories(List<CategoryOption> items) async {
    replacedCategories
      ..clear()
      ..addAll(items);
  }

  @override
  Future<void> replaceContentOptions(List<ContentOption> items) async {
    replacedContentOptions
      ..clear()
      ..addAll(items);
  }

  @override
  Future<void> replaceFeedbackOptions(List<RewardOption> items) async {
    replacedFeedbackOptions
      ..clear()
      ..addAll(items);
  }

  @override
  Future<void> replaceImprovementOptions(List<ImprovementOption> items) async {
    replacedImprovementOptions
      ..clear()
      ..addAll(items);
  }

  @override
  Future<void> replaceRedeemRewards(List<RedeemReward> items) async {
    replacedRedeemRewards
      ..clear()
      ..addAll(items);
  }

  @override
  Future<void> replaceRewardRedemptionRecords(
      List<RewardRedemptionRecord> items) async {
    replacedRewardRedemptionRecords
      ..clear()
      ..addAll(items);
  }

  @override
  Future<void> replaceAppSettings(Map<String, String> items) async {
    replacedAppSettings
      ..clear()
      ..addAll(items);
  }

  @override
  Future<void> replaceStudyRecords(List<StudyRecord> items) async {
    replacedStudyRecords
      ..clear()
      ..addAll(items);
  }


  @override
  Future<void> replaceWeaknessOptions(List<WeaknessOption> items) async {
    replacedWeaknessOptions
      ..clear()
      ..addAll(items);
  }
}
