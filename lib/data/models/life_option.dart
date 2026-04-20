class LifeOption {
  LifeOption({
    this.id,
    required this.name,
    required this.points,
    required this.sortOrder,
    required this.isEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final int points;
  final int sortOrder;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  LifeOption copyWith({
    int? id,
    String? name,
    int? points,
    int? sortOrder,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LifeOption(
      id: id ?? this.id,
      name: name ?? this.name,
      points: points ?? this.points,
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
      'points': points,
      'sort_order': sortOrder,
      'is_enabled': isEnabled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory LifeOption.fromMap(Map<String, Object?> map) {
    return LifeOption(
      id: map['id'] as int?,
      name: map['name'] as String,
      points: (map['points'] as int?) ?? 1,
      sortOrder: map['sort_order'] as int,
      isEnabled: (map['is_enabled'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
