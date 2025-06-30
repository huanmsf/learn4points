import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'question.g.dart';

/// 题目类型枚举
enum QuestionType {
  @JsonValue('single')
  single, // 单选题
  
  @JsonValue('multiple') 
  multiple, // 多选题
  
  @JsonValue('judge')
  judge, // 判断题
}

/// 答案来源
enum AnswerSource {
  @JsonValue('database')
  database, // 本地题库
  
  @JsonValue('search')
  search, // 网络搜索
  
  @JsonValue('ai')
  ai, // AI辅助
}

@JsonSerializable()
@HiveType(typeId: 0)
class Question extends HiveObject {
  @HiveField(0)
  String id; // 题目唯一ID
  
  @HiveField(1)
  int? number; // 题目编号 (1,2,3...)
  
  @HiveField(2)
  QuestionType type; // 题目类型
  
  @HiveField(3)
  String content; // 题目描述
  
  @HiveField(4)
  List<String> options; // 选项列表(完整格式，如"A：选项内容")
  
  @HiveField(5)
  List<String> correctAnswers; // 正确答案(完整格式，如"B：雪天路滑，制动距离比干燥柏油路更长")
  
  @HiveField(6)
  String? imageUrl; // 题目图片URL(如果有)
  
  @HiveField(7)
  DateTime createdAt; // 创建时间
  
  @HiveField(8)
  DateTime? lastUsedAt; // 最后使用时间
  
  @HiveField(9)
  int usageCount; // 使用次数
  
  @HiveField(10)
  double confidence; // 识别置信度
  
  @HiveField(11)
  AnswerSource answerSource; // 答案来源

  Question({
    required this.id,
    this.number,
    required this.type,
    required this.content,
    required this.options,
    required this.correctAnswers,
    this.imageUrl,
    required this.createdAt,
    this.lastUsedAt,
    this.usageCount = 0,
    this.confidence = 0.0,
    required this.answerSource,
  });

  /// 从JSON创建
  factory Question.fromJson(Map<String, dynamic> json) => _$QuestionFromJson(json);
  
  /// 转换为JSON
  Map<String, dynamic> toJson() => _$QuestionToJson(this);
  
  /// 获取题目类型的中文描述
  String get typeDescription {
    switch (type) {
      case QuestionType.single:
        return '单选题';
      case QuestionType.multiple:
        return '多选题';
      case QuestionType.judge:
        return '判断题';
    }
  }
  
  /// 获取答案来源的中文描述
  String get sourceDescription {
    switch (answerSource) {
      case AnswerSource.database:
        return '题库';
      case AnswerSource.search:
        return '网络';
      case AnswerSource.ai:
        return 'AI';
    }
  }
  
  /// 判断是否为单选题
  bool get isSingleChoice => type == QuestionType.single;
  
  /// 判断是否为多选题
  bool get isMultipleChoice => type == QuestionType.multiple;
  
  /// 判断是否为判断题
  bool get isJudgeQuestion => type == QuestionType.judge;
  
  /// 获取格式化的正确答案
  String get formattedCorrectAnswers {
    if (isJudgeQuestion) {
      return correctAnswers.first;
    }
    return correctAnswers.join('、');
  }
  
  /// 获取选项字母到内容的映射
  Map<String, String> get optionsMap {
    Map<String, String> map = {};
    for (String option in options) {
      final match = RegExp(r'^([A-D])：(.+)$').firstMatch(option);
      if (match != null) {
        String letter = match.group(1)!;
        String content = match.group(2)!;
        map[letter] = content;
      }
    }
    return map;
  }
  
  /// 根据选项字母获取选项内容
  String getAnswerContent(String letter) {
    final map = optionsMap;
    return map[letter] ?? letter;
  }
  
  /// 根据选项内容获取选项字母
  String getAnswerLetter(String content) {
    final map = optionsMap;
    for (final entry in map.entries) {
      if (entry.value == content) {
        return entry.key;
      }
    }
    return content;
  }
  
  /// 从完整答案格式中提取字母部分
  static String extractLetterFromFullAnswer(String fullAnswer) {
    final match = RegExp(r'^([A-D])：').firstMatch(fullAnswer);
    return match?.group(1) ?? '';
  }
  
  /// 从完整答案格式中提取内容部分
  static String extractContentFromFullAnswer(String fullAnswer) {
    final match = RegExp(r'^[A-D]：(.+)$').firstMatch(fullAnswer);
    return match?.group(1) ?? fullAnswer;
  }
  
  /// 获取正确答案的字母列表（用于快速比较）
  List<String> get correctAnswerLetters {
    return correctAnswers.map((answer) => extractLetterFromFullAnswer(answer)).toList();
  }
  
  /// 获取带字母标识的选项列表
  List<String> get formattedOptions {
    return options; // 现在options已经是完整格式
  }
  
  /// 获取纯选项内容列表（不带字母标识）
  List<String> get pureOptionsContent {
    List<String> contents = [];
    for (String option in options) {
      String content = extractContentFromFullAnswer(option);
      if (content.isNotEmpty) {
        contents.add(content);
      }
    }
    return contents;
  }
  
  /// 从AI响应文本中提取完整答案格式
  static List<String> extractAnswersFromAI(String aiResponse, List<String> options) {
    List<String> answers = [];
    
    // 匹配选项字母模式 (A, B, C, D)
    final letterPattern = RegExp(r'[A-D]', caseSensitive: false);
    final matches = letterPattern.allMatches(aiResponse.toUpperCase());
    
    Set<String> uniqueAnswers = {};
    for (final match in matches) {
      String letter = match.group(0)!;
      
      // 在选项中查找对应字母的完整选项
      for (String option in options) {
        if (option.startsWith('$letter：')) {
          uniqueAnswers.add(option);
          break;
        }
      }
    }
    
    answers = uniqueAnswers.toList();
    answers.sort(); // 按字母顺序排序
    
    print('🤖 从AI响应提取完整答案: $answers');
    return answers;
  }
  
  /// 从选项内容列表转换为完整答案格式
  static List<String> convertContentToFullFormat(List<String> contents, List<String> options) {
    List<String> fullAnswers = [];
    
    for (String content in contents) {
      // 在完整格式的选项中查找匹配的内容
      for (String option in options) {
        String optionContent = extractContentFromFullAnswer(option);
        if (optionContent == content) {
          fullAnswers.add(option);
          break;
        }
      }
    }
    
    return fullAnswers;
  }
  
  /// 复制题目并更新某些字段
  Question copyWith({
    String? id,
    int? number,
    QuestionType? type,
    String? content,
    List<String>? options,
    List<String>? correctAnswers,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    int? usageCount,
    double? confidence,
    AnswerSource? answerSource,
  }) {
    return Question(
      id: id ?? this.id,
      number: number ?? this.number,
      type: type ?? this.type,
      content: content ?? this.content,
      options: options ?? this.options,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      usageCount: usageCount ?? this.usageCount,
      confidence: confidence ?? this.confidence,
      answerSource: answerSource ?? this.answerSource,
    );
  }

  @override
  String toString() {
    return 'Question(id: $id, type: $typeDescription, content: $content, answers: $formattedCorrectAnswers)';
  }
} 