class WeaknessOption {
  WeaknessOption({
    this.id,
    required this.name,
    this.categoryId,
    this.contentOptionId,
    required this.sortOrder,
    required this.isEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final int? categoryId;
  final int? contentOptionId;
  final int sortOrder;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  WeaknessOption copyWith({
    int? id,
    String? name,
    int? categoryId,
    bool clearCategoryId = false,
    int? contentOptionId,
    bool clearContentOptionId = false,
    int? sortOrder,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WeaknessOption(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: clearCategoryId ? null : categoryId ?? this.categoryId,
      contentOptionId:
          clearContentOptionId ? null : contentOptionId ?? this.contentOptionId,
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
      'category_id': categoryId,
      'content_option_id': contentOptionId,
      'sort_order': sortOrder,
      'is_enabled': isEnabled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory WeaknessOption.fromMap(Map<String, Object?> map) {
    return WeaknessOption(
      id: map['id'] as int?,
      name: map['name'] as String,
      categoryId: map['category_id'] as int?,
      contentOptionId: map['content_option_id'] as int?,
      sortOrder: map['sort_order'] as int,
      isEnabled: (map['is_enabled'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
