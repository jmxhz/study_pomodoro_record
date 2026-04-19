class ContentOption {
  ContentOption({
    this.id,
    required this.name,
    required this.categoryId,
    required this.sortOrder,
    required this.isEnabled,
    this.points = 1,
    this.defaultPoints,
    this.allowAdjust = false,
    this.minPoints,
    this.maxPoints,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final int? categoryId;
  final int sortOrder;
  final bool isEnabled;
  final int points;
  final int? defaultPoints;
  final bool allowAdjust;
  final int? minPoints;
  final int? maxPoints;
  final DateTime createdAt;
  final DateTime updatedAt;

  ContentOption copyWith({
    int? id,
    String? name,
    int? categoryId,
    bool clearCategoryId = false,
    int? sortOrder,
    bool? isEnabled,
    int? points,
    int? defaultPoints,
    bool? allowAdjust,
    int? minPoints,
    int? maxPoints,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ContentOption(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: clearCategoryId ? null : categoryId ?? this.categoryId,
      sortOrder: sortOrder ?? this.sortOrder,
      isEnabled: isEnabled ?? this.isEnabled,
      points: points ?? this.points,
      defaultPoints: defaultPoints ?? this.defaultPoints,
      allowAdjust: allowAdjust ?? this.allowAdjust,
      minPoints: minPoints ?? this.minPoints,
      maxPoints: maxPoints ?? this.maxPoints,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap({bool includeId = false}) {
    return {
      if (includeId) 'id': id,
      'name': name,
      'category_id': categoryId,
      'sort_order': sortOrder,
      'is_enabled': isEnabled ? 1 : 0,
      'points': points,
      'default_points': defaultPoints ?? points,
      'allow_adjust': allowAdjust ? 1 : 0,
      'min_points': minPoints ?? points,
      'max_points': maxPoints ?? points,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ContentOption.fromMap(Map<String, Object?> map) {
    return ContentOption(
      id: map['id'] as int?,
      name: map['name'] as String,
      categoryId: map['category_id'] as int?,
      sortOrder: map['sort_order'] as int,
      isEnabled: (map['is_enabled'] as int) == 1,
      points: (map['points'] as int?) ?? (map['default_points'] as int?) ?? 1,
      defaultPoints: map['default_points'] as int?,
      allowAdjust: ((map['allow_adjust'] as int?) ?? 0) == 1,
      minPoints: map['min_points'] as int?,
      maxPoints: map['max_points'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
