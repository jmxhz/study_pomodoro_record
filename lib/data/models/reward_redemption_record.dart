class RewardRedemptionRecord {
  RewardRedemptionRecord({
    this.id,
    required this.rewardId,
    required this.rewardNameSnapshot,
    required this.costPoints,
    required this.redeemedAt,
    this.note,
    required this.createdAt,
  });

  final int? id;
  final int? rewardId;
  final String rewardNameSnapshot;
  final int costPoints;
  final DateTime redeemedAt;
  final String? note;
  final DateTime createdAt;

  RewardRedemptionRecord copyWith({
    int? id,
    int? rewardId,
    bool clearRewardId = false,
    String? rewardNameSnapshot,
    int? costPoints,
    DateTime? redeemedAt,
    String? note,
    bool clearNote = false,
    DateTime? createdAt,
  }) {
    return RewardRedemptionRecord(
      id: id ?? this.id,
      rewardId: clearRewardId ? null : rewardId ?? this.rewardId,
      rewardNameSnapshot: rewardNameSnapshot ?? this.rewardNameSnapshot,
      costPoints: costPoints ?? this.costPoints,
      redeemedAt: redeemedAt ?? this.redeemedAt,
      note: clearNote ? null : note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap({bool includeId = false}) {
    return {
      if (includeId) 'id': id,
      'reward_id': rewardId,
      'reward_name_snapshot': rewardNameSnapshot,
      'cost_points': costPoints,
      'redeemed_at': redeemedAt.toIso8601String(),
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory RewardRedemptionRecord.fromMap(Map<String, Object?> map) {
    return RewardRedemptionRecord(
      id: map['id'] as int?,
      rewardId: map['reward_id'] as int?,
      rewardNameSnapshot: map['reward_name_snapshot'] as String,
      costPoints: map['cost_points'] as int,
      redeemedAt: DateTime.parse(map['redeemed_at'] as String),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
