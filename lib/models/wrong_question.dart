import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';
import 'question.dart';

part 'wrong_question.g.dart';

@JsonSerializable()
@HiveType(typeId: 1)
class WrongQuestion extends HiveObject {
  @HiveField(0)
  String id; // 错题记录ID
  
  @HiveField(1)
  Question question; // 题目信息
  
  @HiveField(2)
  List<String> userAnswers; // 用户错误答案(完整格式，如"A：选项内容")
  
  @HiveField(3)
  DateTime wrongTime; // 答错时间
  
  @HiveField(4)  
  int wrongCount; // 答错次数
  
  @HiveField(5)
  DateTime? lastWrongTime; // 最后一次答错时间
  
  @HiveField(6)
  String? note; // 错题笔记
  
  WrongQuestion({
    required this.id,
    required this.question,
    required this.userAnswers,
    required this.wrongTime,
    this.wrongCount = 1,
    this.lastWrongTime,
    this.note,
  });

  /// 从JSON创建
  factory WrongQuestion.fromJson(Map<String, dynamic> json) => _$WrongQuestionFromJson(json);
  
  /// 转换为JSON
  Map<String, dynamic> toJson() => _$WrongQuestionToJson(this);
  
  /// 获取用户答案的格式化字符串
  String get formattedUserAnswers {
    return userAnswers.join('、');
  }
  
  /// 复制错题记录并更新某些字段
  WrongQuestion copyWith({
    String? id,
    Question? question,
    List<String>? userAnswers,
    DateTime? wrongTime,
    int? wrongCount,
    DateTime? lastWrongTime,
    String? note,
  }) {
    return WrongQuestion(
      id: id ?? this.id,
      question: question ?? this.question,
      userAnswers: userAnswers ?? this.userAnswers,
      wrongTime: wrongTime ?? this.wrongTime,
      wrongCount: wrongCount ?? this.wrongCount,
      lastWrongTime: lastWrongTime ?? this.lastWrongTime,
      note: note ?? this.note,
    );
  }

  @override
  String toString() {
    return 'WrongQuestion(id: $id, question: ${question.content}, userAnswer: $formattedUserAnswers, wrongCount: $wrongCount)';
  }
} 