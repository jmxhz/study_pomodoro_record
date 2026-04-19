enum StudyType {
  pureInput,
  standardPractice,
  output,
  reviewLoop,
}

class StudyTypeDescriptor {
  const StudyTypeDescriptor({
    required this.type,
    required this.label,
    required this.shortLabel,
    required this.description,
    required this.encouragement,
  });

  final StudyType type;
  final String label;
  final String shortLabel;
  final String description;
  final String encouragement;
}

class StudyTypeUtils {
  static const _pureInputContents = {
    '常识判断',
    '练字',
    '摘抄',
    '单词',
    '泛听',
  };

  static const _standardPracticeContents = {
    '判断推理',
    '资料分析',
    '语言理解',
    '数量关系',
    '精听',
    '跟读',
    '阅读',
  };

  static const _outputContents = {
    '概括题',
    '对策题',
    '公文题',
    '大作文',
    '口语',
    '写作',
  };

  static const orderedTypes = [
    StudyType.pureInput,
    StudyType.standardPractice,
    StudyType.output,
    StudyType.reviewLoop,
  ];

  static StudyType resolveForContent({
    String? categoryName,
    required String contentName,
    int? fallbackPoints,
  }) {
    if (_pureInputContents.contains(contentName)) {
      return StudyType.pureInput;
    }
    if (_standardPracticeContents.contains(contentName)) {
      return StudyType.standardPractice;
    }
    if (_outputContents.contains(contentName)) {
      return StudyType.output;
    }
    if (_looksLikeReview(contentName, categoryName)) {
      return StudyType.reviewLoop;
    }
    return fromPoints(fallbackPoints ?? 1);
  }

  static StudyType fromPoints(int points) {
    switch (points) {
      case 1:
        return StudyType.pureInput;
      case 2:
        return StudyType.standardPractice;
      case 3:
        return StudyType.output;
      default:
        return StudyType.reviewLoop;
    }
  }

  static StudyTypeDescriptor describeByPoints(int points) => describe(fromPoints(points));

  static StudyTypeDescriptor describeForContent({
    String? categoryName,
    required String contentName,
    int? fallbackPoints,
  }) {
    return describe(
      resolveForContent(
        categoryName: categoryName,
        contentName: contentName,
        fallbackPoints: fallbackPoints,
      ),
    );
  }

  static int recommendedPointsForType(StudyType type) {
    switch (type) {
      case StudyType.pureInput:
        return 1;
      case StudyType.standardPractice:
        return 2;
      case StudyType.output:
        return 3;
      case StudyType.reviewLoop:
        return 4;
    }
  }

  static int recommendedPointsForContent({
    String? categoryName,
    required String contentName,
    int? fallbackPoints,
  }) {
    return recommendedPointsForType(
      resolveForContent(
        categoryName: categoryName,
        contentName: contentName,
        fallbackPoints: fallbackPoints,
      ),
    );
  }

  static bool _looksLikeReview(String contentName, String? categoryName) {
    const keywords = ['复盘', '纠错', '错题', '改错', '总结', '闭环'];
    if (keywords.any(contentName.contains)) {
      return true;
    }
    return categoryName != null && keywords.any(categoryName.contains);
  }

  static StudyTypeDescriptor describe(StudyType type) {
    switch (type) {
      case StudyType.pureInput:
        return const StudyTypeDescriptor(
          type: StudyType.pureInput,
          label: '1 分 · 纯输入',
          shortLabel: '纯输入',
          description: '进入门槛低，适合热身和补充，但不适合作为今天的主力学习。',
          encouragement: '建议点到为止，把时间留给练习、输出和复盘。',
        );
      case StudyType.standardPractice:
        return const StudyTypeDescriptor(
          type: StudyType.standardPractice,
          label: '2 分 · 标准练习',
          shortLabel: '标准练习',
          description: '已经开始动脑，是主力训练区，但还没形成完整输出闭环。',
          encouragement: '适合作为主力训练，后面最好接一次输出或复盘。',
        );
      case StudyType.output:
        return const StudyTypeDescriptor(
          type: StudyType.output,
          label: '3 分 · 输出',
          shortLabel: '输出',
          description: '需要自己组织内容，更容易暴露真实水平。',
          encouragement: '建议每天至少做一次输出，避免只停留在输入和刷题。',
        );
      case StudyType.reviewLoop:
        return const StudyTypeDescriptor(
          type: StudyType.reviewLoop,
          label: '4 分 · 复盘 / 纠错 / 闭环',
          shortLabel: '复盘闭环',
          description: '最不舒服，但最值钱，真正决定后面会不会进步。',
          encouragement: '建议每天至少留一条记录给复盘或纠错，形成闭环。',
        );
    }
  }
}
