class RewardOption {
  RewardOption({
    this.id,
    required this.name,
    this.type = 'short',
    required this.sortOrder,
    required this.isEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final String type;
  final int sortOrder;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  RewardOption copyWith({
    int? id,
    String? name,
    String? type,
    int? sortOrder,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RewardOption(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
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
      'break_type': type,
      'sort_order': sortOrder,
      'is_enabled': isEnabled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory RewardOption.fromMap(Map<String, Object?> map) {
    return RewardOption(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: (map['break_type'] as String?) ?? 'short',
      sortOrder: map['sort_order'] as int,
      isEnabled: (map['is_enabled'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
