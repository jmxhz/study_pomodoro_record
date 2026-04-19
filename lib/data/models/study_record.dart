import 'dart:convert';

class StudyRecord {
  StudyRecord({
    this.id,
    required this.occurredAt,
    required this.categoryId,
    required this.categoryNameSnapshot,
    required this.contentOptionId,
    required this.contentNameSnapshot,
    required this.rewardOptionId,
    required this.rewardNameSnapshot,
    this.breakType,
    this.feedbackOptionId,
    this.feedbackNameSnapshot,
    required this.pomodoroCount,
    required this.points,
    this.detailAmountText,
    this.questionCount,
    this.wrongCount,
    this.outputType,
    this.weaknessTags = const [],
    this.improvementTags = const [],
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final DateTime occurredAt;
  final int? categoryId;
  final String categoryNameSnapshot;
  final int? contentOptionId;
  final String contentNameSnapshot;
  final int? rewardOptionId;
  final String rewardNameSnapshot;
  final String? breakType;
  final int? feedbackOptionId;
  final String? feedbackNameSnapshot;
  final int pomodoroCount;
  final int points;
  final String? detailAmountText;
  final int? questionCount;
  final int? wrongCount;
  final String? outputType;
  final List<String> weaknessTags;
  final List<String> improvementTags;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  StudyRecord copyWith({
    int? id,
    DateTime? occurredAt,
    int? categoryId,
    bool clearCategoryId = false,
    String? categoryNameSnapshot,
    int? contentOptionId,
    bool clearContentOptionId = false,
    String? contentNameSnapshot,
    int? rewardOptionId,
    bool clearRewardOptionId = false,
    String? rewardNameSnapshot,
    String? breakType,
    int? feedbackOptionId,
    bool clearFeedbackOptionId = false,
    String? feedbackNameSnapshot,
    int? pomodoroCount,
    int? points,
    String? detailAmountText,
    bool clearDetailAmountText = false,
    int? questionCount,
    bool clearQuestionCount = false,
    int? wrongCount,
    bool clearWrongCount = false,
    String? outputType,
    bool clearOutputType = false,
    List<String>? weaknessTags,
    List<String>? improvementTags,
    String? notes,
    bool clearNotes = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudyRecord(
      id: id ?? this.id,
      occurredAt: occurredAt ?? this.occurredAt,
      categoryId: clearCategoryId ? null : categoryId ?? this.categoryId,
      categoryNameSnapshot: categoryNameSnapshot ?? this.categoryNameSnapshot,
      contentOptionId:
          clearContentOptionId ? null : contentOptionId ?? this.contentOptionId,
      contentNameSnapshot: contentNameSnapshot ?? this.contentNameSnapshot,
      rewardOptionId:
          clearRewardOptionId ? null : rewardOptionId ?? this.rewardOptionId,
      rewardNameSnapshot: rewardNameSnapshot ?? this.rewardNameSnapshot,
      breakType: breakType ?? this.breakType,
      feedbackOptionId:
          clearFeedbackOptionId ? null : feedbackOptionId ?? this.feedbackOptionId,
      feedbackNameSnapshot: feedbackNameSnapshot ?? this.feedbackNameSnapshot,
      pomodoroCount: pomodoroCount ?? this.pomodoroCount,
      points: points ?? this.points,
      detailAmountText: clearDetailAmountText ? null : detailAmountText ?? this.detailAmountText,
      questionCount: clearQuestionCount ? null : questionCount ?? this.questionCount,
      wrongCount: clearWrongCount ? null : wrongCount ?? this.wrongCount,
      outputType: clearOutputType ? null : outputType ?? this.outputType,
      weaknessTags: weaknessTags ?? this.weaknessTags,
      improvementTags: improvementTags ?? this.improvementTags,
      notes: clearNotes ? null : notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap({bool includeId = false}) {
    return {
      if (includeId) 'id': id,
      'occurred_at': occurredAt.toIso8601String(),
      'category_id': categoryId,
      'category_name_snapshot': categoryNameSnapshot,
      'content_option_id': contentOptionId,
      'content_name_snapshot': contentNameSnapshot,
      'reward_option_id': rewardOptionId,
      'reward_name_snapshot': rewardNameSnapshot,
      'break_type': breakType,
      'feedback_option_id': feedbackOptionId ?? rewardOptionId,
      'feedback_name_snapshot': feedbackNameSnapshot ?? rewardNameSnapshot,
      'pomodoro_count': pomodoroCount,
      'points': points,
      'detail_amount_text': detailAmountText,
      'question_count': questionCount,
      'wrong_count': wrongCount,
      'output_type': outputType,
      'weakness_tags': jsonEncode(weaknessTags),
      'improvement_tags': jsonEncode(improvementTags),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory StudyRecord.fromMap(Map<String, Object?> map) {
    final rewardNameSnapshot = map['reward_name_snapshot'] as String;
    return StudyRecord(
      id: map['id'] as int?,
      occurredAt: DateTime.parse(map['occurred_at'] as String),
      categoryId: map['category_id'] as int?,
      categoryNameSnapshot: map['category_name_snapshot'] as String,
      contentOptionId: map['content_option_id'] as int?,
      contentNameSnapshot: map['content_name_snapshot'] as String,
      rewardOptionId: map['reward_option_id'] as int?,
      rewardNameSnapshot: rewardNameSnapshot,
      breakType: map['break_type'] as String?,
      feedbackOptionId: map['feedback_option_id'] as int? ?? map['reward_option_id'] as int?,
      feedbackNameSnapshot:
          map['feedback_name_snapshot'] as String? ?? rewardNameSnapshot,
      pomodoroCount: map['pomodoro_count'] as int,
      points: map['points'] as int,
      detailAmountText: map['detail_amount_text'] as String?,
      questionCount: map['question_count'] as int?,
      wrongCount: map['wrong_count'] as int?,
      outputType: map['output_type'] as String?,
      weaknessTags: _decodeTags(map['weakness_tags'] as String?),
      improvementTags: _decodeTags(map['improvement_tags'] as String?),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  static List<String> _decodeTags(String? value) {
    if (value == null || value.isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) {
        return decoded
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false);
      }
    } catch (_) {
      return value
          .split('\u0001')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }
}
