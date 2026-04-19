enum RewardRulePeriodType { day, week, month }

extension RewardRulePeriodTypeX on RewardRulePeriodType {
  String get dbValue {
    switch (this) {
      case RewardRulePeriodType.day:
        return 'day';
      case RewardRulePeriodType.week:
        return 'week';
      case RewardRulePeriodType.month:
        return 'month';
    }
  }

  String get label {
    switch (this) {
      case RewardRulePeriodType.day:
        return '每日';
      case RewardRulePeriodType.week:
        return '每周';
      case RewardRulePeriodType.month:
        return '每月';
    }
  }

  static RewardRulePeriodType fromDbValue(String value) {
    switch (value) {
      case 'day':
        return RewardRulePeriodType.day;
      case 'week':
        return RewardRulePeriodType.week;
      case 'month':
        return RewardRulePeriodType.month;
      default:
        throw ArgumentError.value(value, 'value', 'Unsupported reward rule period type');
    }
  }
}

class RewardRule {
  RewardRule({
    this.id,
    required this.name,
    required this.periodType,
    required this.thresholdPoints,
    required this.rewardText,
    required this.sortOrder,
    required this.isEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final RewardRulePeriodType periodType;
  final int thresholdPoints;
  final String rewardText;
  final int sortOrder;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  RewardRule copyWith({
    int? id,
    String? name,
    RewardRulePeriodType? periodType,
    int? thresholdPoints,
    String? rewardText,
    int? sortOrder,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RewardRule(
      id: id ?? this.id,
      name: name ?? this.name,
      periodType: periodType ?? this.periodType,
      thresholdPoints: thresholdPoints ?? this.thresholdPoints,
      rewardText: rewardText ?? this.rewardText,
      sortOrder: sortOrder ?? this.sortOrder,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap({bool includeId = false}) {
    return {
      if (includeId) 'id': id,
      'name': name,
      'period_type': periodType.dbValue,
      'threshold_points': thresholdPoints,
      'reward_text': rewardText,
      'sort_order': sortOrder,
      'is_enabled': isEnabled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory RewardRule.fromMap(Map<String, Object?> map) {
    return RewardRule(
      id: map['id'] as int?,
      name: map['name'] as String,
      periodType: RewardRulePeriodTypeX.fromDbValue(map['period_type'] as String),
      thresholdPoints: map['threshold_points'] as int,
      rewardText: map['reward_text'] as String,
      sortOrder: map['sort_order'] as int,
      isEnabled: (map['is_enabled'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
