import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../app/app_services.dart';
import '../../../data/models/redeem_reward.dart';
import '../../../data/models/reward_redemption_record.dart';
import '../../../data/repositories/options_repository.dart';
import '../../../data/repositories/reward_redemption_repository.dart';
import '../../../data/repositories/study_record_repository.dart';

class RewardsCenterController extends ChangeNotifier {
  RewardsCenterController({
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

  late final VoidCallback _syncListener;
  bool _isLoadingInProgress = false;
  bool _reloadQueued = false;

  bool isLoading = true;
  bool isBusy = false;
  String? errorMessage;
  int totalEarnedPoints = 0;
  int totalRedeemedPoints = 0;
  List<RedeemReward> redeemRewards = const [];
  List<RewardRedemptionRecord> currentWeekRedemptionRecords = const [];
  int historyRedemptionCount = 0;

  int get availablePoints => totalEarnedPoints - totalRedeemedPoints;

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

      final now = DateTime.now();
      final currentWeekStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - DateTime.monday));
      final nextWeekStart = currentWeekStart.add(const Duration(days: 7));
      final results = await Future.wait([
        optionsRepository.getRedeemRewards(includeDisabled: false),
        rewardRedemptionRepository.getRecordsBetween(
          currentWeekStart,
          nextWeekStart,
        ),
        rewardRedemptionRepository.countRecordsBefore(currentWeekStart),
        studyRecordRepository.totalEarnedPoints(),
        rewardRedemptionRepository.totalRedeemedPoints(),
      ]);
      redeemRewards = results[0] as List<RedeemReward>;
      currentWeekRedemptionRecords = results[1] as List<RewardRedemptionRecord>;
      historyRedemptionCount = results[2] as int;
      totalEarnedPoints = results[3] as int;
      totalRedeemedPoints = results[4] as int;
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

  Future<void> redeemReward(RedeemReward reward, {String? note}) async {
    if (availablePoints < reward.costPoints) {
      throw StateError('当前可用积分不足，无法兑换该奖励。');
    }

    try {
      isBusy = true;
      errorMessage = null;
      notifyListeners();

      final now = DateTime.now();
      await rewardRedemptionRepository.insertRecord(
        RewardRedemptionRecord(
          rewardId: reward.id,
          rewardNameSnapshot: reward.name,
          costPoints: reward.costPoints,
          redeemedAt: now,
          note: note,
          createdAt: now,
        ),
      );
      dataSyncNotifier.notifyChanged();
      await load();
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> undoRedemption(RewardRedemptionRecord record) async {
    if (record.id == null) {
      return;
    }

    try {
      isBusy = true;
      errorMessage = null;
      notifyListeners();

      await rewardRedemptionRepository.deleteRecord(record.id!);
      dataSyncNotifier.notifyChanged();
      await load();
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    dataSyncNotifier.removeListener(_syncListener);
    super.dispose();
  }
}
