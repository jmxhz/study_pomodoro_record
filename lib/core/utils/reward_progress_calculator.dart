import '../../data/models/reward_rule.dart';
import '../../data/models/statistics_models.dart';

class RewardProgressCalculator {
  RewardProgress? build({
    required TimeGranularity granularity,
    required int currentPoints,
    required List<RewardRule> rewardRules,
  }) {
    final periodType = _mapGranularity(granularity);
    if (periodType == null) {
      return null;
    }

    final rules =
        rewardRules
            .where((item) => item.isEnabled && item.periodType == periodType)
            .toList(growable: true)
          ..sort(_compareRules);

    final achievedRules =
        rules.where((item) => item.thresholdPoints <= currentPoints).toList(growable: false);
    RewardRule? nextRule;
    for (final item in rules) {
      if (item.thresholdPoints > currentPoints) {
        nextRule = item;
        break;
      }
    }

    return RewardProgress(
      currentPoints: currentPoints,
      rules: List.unmodifiable(rules),
      achievedRules: achievedRules,
      nextRule: nextRule,
      pointsToNextRule: nextRule == null ? null : nextRule.thresholdPoints - currentPoints,
    );
  }

  RewardRulePeriodType? _mapGranularity(TimeGranularity granularity) {
    switch (granularity) {
      case TimeGranularity.day:
        return RewardRulePeriodType.day;
      case TimeGranularity.week:
        return RewardRulePeriodType.week;
      case TimeGranularity.month:
        return RewardRulePeriodType.month;
      case TimeGranularity.year:
        return null;
    }
  }

  int _compareRules(RewardRule a, RewardRule b) {
    final thresholdCompare = a.thresholdPoints.compareTo(b.thresholdPoints);
    if (thresholdCompare != 0) {
      return thresholdCompare;
    }
    final sortCompare = a.sortOrder.compareTo(b.sortOrder);
    if (sortCompare != 0) {
      return sortCompare;
    }
    return a.name.compareTo(b.name);
  }
}
