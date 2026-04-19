class RedeemReward {
  RedeemReward({
    this.id,
    required this.name,
    required this.costPoints,
    required this.sortOrder,
    required this.isEnabled,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final int costPoints;
  final int sortOrder;
  final bool isEnabled;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  RedeemReward copyWith({
    int? id,
    String? name,
    int? costPoints,
    int? sortOrder,
    bool? isEnabled,
    String? note,
    bool clearNote = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RedeemReward(
      id: id ?? this.id,
      name: name ?? this.name,
      costPoints: costPoints ?? this.costPoints,
      sortOrder: sortOrder ?? this.sortOrder,
      isEnabled: isEnabled ?? this.isEnabled,
      note: clearNote ? null : note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap({bool includeId = false}) {
    return {
      if (includeId) 'id': id,
      'name': name,
      'cost_points': costPoints,
      'sort_order': sortOrder,
      'is_enabled': isEnabled ? 1 : 0,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory RedeemReward.fromMap(Map<String, Object?> map) {
    return RedeemReward(
      id: map['id'] as int?,
      name: map['name'] as String,
      costPoints: map['cost_points'] as int,
      sortOrder: map['sort_order'] as int,
      isEnabled: (map['is_enabled'] as int) == 1,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
