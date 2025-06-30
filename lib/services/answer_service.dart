import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/question.dart';
import '../services/database_service.dart';
import '../utils/text_parser.dart';
import '../utils/config.dart';

/// 答案查询结果
class AnswerResult {
  final List<String> answers; // 答案列表
  final AnswerSource source; // 答案来源
  final double confidence; // 置信度
  final String? explanation; // 解释说明
  final Duration queryTime; // 查询耗时
  
  AnswerResult({
    required this.answers,
    required this.source,
    required this.confidence,
    this.explanation,
    required this.queryTime,
  });
  
  bool get hasAnswers => answers.isNotEmpty;
  
  String get primaryAnswer => answers.isNotEmpty ? answers.first : '';
  
  String get formattedAnswers => answers.join('、');
  
  /// 获取详细的答案显示格式
  String get detailedAnswers {
    if (answers.isEmpty) return '暂无答案';
    
    // 如果答案包含完整格式（字母：内容），直接显示
    if (answers.first.contains('：')) {
      return answers.join('\n');
    }
    
    // 否则使用简单格式
    return answers.join('、');
  }
  
  /// 复制对象并更新部分字段
  AnswerResult copyWith({
    List<String>? answers,
    AnswerSource? source,
    double? confidence,
    String? explanation,
    Duration? queryTime,
  }) {
    return AnswerResult(
      answers: answers ?? this.answers,
      source: source ?? this.source,
      confidence: confidence ?? this.confidence,
      explanation: explanation ?? this.explanation,
      queryTime: queryTime ?? this.queryTime,
    );
  }
}

/// 答案查询服务
class AnswerService {
  static final AnswerService _instance = AnswerService._internal();
  factory AnswerService() => _instance;
  AnswerService._internal();

  final Dio _dio = Dio();
  final DatabaseService _database = DatabaseService();
  final TextParser _textParser = TextParser();

  /// 简化的答案查询主入口
  /// 根据配置决定是否查询数据库，支持直接AI查询
  Future<AnswerResult> queryAnswer(String questionContent, List<String> options, QuestionType type) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      print('');
      print('🔍 ==========================================');
      print('🚀 开始智能答题查询...');
      print('📝 题干: $questionContent');
      print('📋 题型: ${_getTypeDisplayName(type)}');
      print('⚙️ 数据库查询: ${AppConfig.enableDatabaseQuery ? "启用" : "禁用"}');
      print('🔍 ==========================================');
      print('');
      
      // 1. 数据库查询（可配置是否启用）
      if (AppConfig.enableDatabaseQuery) {
        print('🗄️ 查询本地题库...');
        final localResult = await _queryLocalDatabase(questionContent, type);
        if (localResult.hasAnswers) {
          print('✅ 题库中找到答案: ${localResult.formattedAnswers}');
          return localResult.copyWith(queryTime: stopwatch.elapsed);
        }
        print('❌ 题库中未找到答案');
      } else {
        print('⏭️ 跳过数据库查询（配置已禁用），直接使用AI查询');
      }

      // 2. 豆包AI查询
      print('🤖 调用豆包AI查询...');
      final aiResult = await _queryDoubaoAI(questionContent, options, type);
      if (aiResult.hasAnswers) {
        print('✅ 豆包AI找到答案: ${aiResult.formattedAnswers}');
        return aiResult.copyWith(queryTime: stopwatch.elapsed);
      }
      print('❌ 豆包AI未找到答案');

      // 3. 没有找到答案
      print('❌ === 未找到答案 ===');
      print('🔍 已尝试所有查询方式');
      print('📋 题目类型: ${_getTypeDisplayName(type)}');
      print('💡 建议: 请手动查找答案或检查题目格式');
      print('========================');
      print('');
      
      return AnswerResult(
        answers: [],
        source: AnswerSource.ai,
        confidence: 0.0,
        explanation: '未找到相关答案',
        queryTime: stopwatch.elapsed,
      );
      
    } catch (e) {
      print('❌ 答案查询失败: $e');
      return AnswerResult(
        answers: [],
        source: AnswerSource.database,
        confidence: 0.0,
        explanation: '查询过程出错: $e',
        queryTime: stopwatch.elapsed,
      );
    } finally {
      stopwatch.stop();
    }
  }

  /// 获取题目类型的显示名称
  String _getTypeDisplayName(QuestionType type) {
    switch (type) {
      case QuestionType.single:
        return '单选题';
      case QuestionType.multiple:
        return '多选题';
      case QuestionType.judge:
        return '判断题';
    }
  }

  /// 1. 本地题库查询 - 基于题干和题型
  Future<AnswerResult> _queryLocalDatabase(String questionContent, QuestionType type) async {
    try {
      // 精确匹配：题干和题型都匹配
      Question? exactMatch = await _database.findQuestionByContentAndType(questionContent, type);
      if (exactMatch != null) {
        print('📍 题库精确匹配成功');
        print('');
        print('🔔 === 用户答案提示 ===');
        print('📢 题目类型: ${_getTypeDisplayName(type)}');
        print('🎯 推荐答案:');
        for (String answer in exactMatch.correctAnswers) {
          print('   ✅ $answer');
        }
        print('📊 置信度: 95%');
        print('📍 来源: 本地题库（精确匹配）');
        print('========================');
        print('');
        
        return AnswerResult(
          answers: exactMatch.correctAnswers,
          source: AnswerSource.database,
          confidence: 0.95,
          explanation: '题库精确匹配',
          queryTime: Duration.zero,
        );
      }

      // 模糊匹配：在相同题型中找相似题目
      List<Question> similarQuestions = await _database.findSimilarQuestionsByType(questionContent, type, limit: 5);
      
      for (Question question in similarQuestions) {
        double similarity = _textParser.calculateSimilarity(questionContent, question.content);
        if (similarity > 0.8) {
          print('📍 题库模糊匹配成功 (相似度: ${(similarity * 100).toStringAsFixed(1)}%)');
          print('');
          print('🔔 === 用户答案提示 ===');
          print('📢 题目类型: ${_getTypeDisplayName(type)}');
          print('🎯 推荐答案:');
          for (String answer in question.correctAnswers) {
            print('   ✅ $answer');
          }
          print('📊 置信度: ${(similarity * 100).toStringAsFixed(0)}%');
          print('📍 来源: 本地题库（模糊匹配）');
          print('========================');
          print('');
          
          return AnswerResult(
            answers: question.correctAnswers,
            source: AnswerSource.database,
            confidence: similarity,
            explanation: '题库模糊匹配 (相似度: ${(similarity * 100).toStringAsFixed(1)}%)',
            queryTime: Duration.zero,
          );
        }
      }

      return AnswerResult(
        answers: [],
        source: AnswerSource.database,
        confidence: 0.0,
        queryTime: Duration.zero,
      );
    } catch (e) {
      print('❌ 本地题库查询失败: $e');
      return AnswerResult(
        answers: [],
        source: AnswerSource.database,
        confidence: 0.0,
        queryTime: Duration.zero,
      );
    }
  }

  /// 2. 豆包AI查询
  Future<AnswerResult> _queryDoubaoAI(String questionContent, List<String> options, QuestionType type) async {
    try {
      // 检查豆包AI配置
      print('🔍 === 豆包AI配置检查 ===');
      print('🔑 API Key: ${AppConfig.doubaoApiKey}');
      print('🌐 Base URL: ${AppConfig.doubaoBaseUrl}');
      print('🤖 Model: ${AppConfig.doubaoModel}');
      print('✅ 配置状态: ${AppConfig.isDoubaoAiConfigured}');
      print('========================');
      
      if (!AppConfig.isDoubaoAiConfigured) {
        print('⚠️ 豆包AI未配置，请在lib/utils/config.dart中设置doubaoApiKey');
        return AnswerResult(
          answers: [],
          source: AnswerSource.ai,
          confidence: 0.0,
          explanation: '豆包AI未配置',
          queryTime: Duration.zero,
        );
      }

      // 构建AI查询请求
      String prompt = _buildAIPrompt(questionContent, options, type);
      
      // 构建请求数据
      final requestData = {
        'model': AppConfig.doubaoModel,
        'messages': [
          {
            'role': 'system',
            'content': '你是一个专业的考试答题助手。请仔细分析题目，并直接给出正确答案。对于选择题，请回答选项字母；对于判断题，请回答"正确"或"错误"。'
          },
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'max_tokens': 150,
        'temperature': 0.1,
      };

      // 打印详细的请求信息
      print('🤖 === 豆包AI请求信息 ===');
      print('📝 题型: ${_getTypeDisplayName(type)}');
      print('📄 题目: $questionContent');
      print('📋 选项:');
      for (String option in options) {
        if (option.contains('：') && RegExp(r'^[A-D]：').hasMatch(option)) {
          // 选项已经是完整格式
          print('   $option');
        } else {
          // 选项是纯内容格式，添加序号显示
          int index = options.indexOf(option);
          if (index < 26) {
            print('   ${String.fromCharCode(65 + index)}. $option');
          }
        }
      }
      print('🔗 API端点: ${AppConfig.doubaoBaseUrl}/chat/completions');
      print('🎯 使用模型: ${AppConfig.doubaoModel}');
      print('💬 完整提示词:');
      print('   $prompt');
      print('📤 请求数据: ${jsonEncode(requestData)}');
      print('========================');
      
      print('🤖 向豆包AI发送请求...');
      
      // 调用豆包AI API
      final response = await _dio.post(
        '${AppConfig.doubaoBaseUrl}/chat/completions',
        data: requestData,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${AppConfig.doubaoApiKey}',
            'Content-Type': 'application/json',
          },
          sendTimeout: Duration(seconds: AppConfig.aiTimeout),
          receiveTimeout: Duration(seconds: AppConfig.aiTimeout),
        ),
      );

      // 打印详细的响应信息
      print('📥 === 豆包AI响应信息 ===');
      print('📊 状态码: ${response.statusCode}');
      print('📋 响应头: ${response.headers}');
      print('📄 响应数据: ${jsonEncode(response.data)}');
      print('========================');

      // 解析AI响应
      if (response.data != null && response.data['choices'] != null && response.data['choices'].isNotEmpty) {
        String aiResponse = response.data['choices'][0]['message']['content'];
        print('🧠 AI原始回答: $aiResponse');
        
        List<String> answers = _parseAIResponse(aiResponse, options, type);
        
        if (answers.isNotEmpty) {
          print('🎯 === 豆包AI解析结果 ===');
          print('✅ 成功解析答案:');
          for (String answer in answers) {
            print('   ✅ $answer');
          }
          print('📊 答案数量: ${answers.length}');
          print('🎯 题型匹配: ${answers.length == 1 && type == QuestionType.single ? "单选✓" : answers.length > 1 && type == QuestionType.multiple ? "多选✓" : type == QuestionType.judge ? "判断✓" : "⚠️"}');
          print('========================');
          print('');
          print('🔔 === 用户答案提示 ===');
          print('📢 题目类型: ${_getTypeDisplayName(type)}');
          print('🎯 推荐答案:');
          for (String answer in answers) {
            print('   ✅ $answer');
          }
          print('📊 置信度: 85%');
          print('📍 来源: 豆包AI');
          print('========================');
          print('');
          
          return AnswerResult(
            answers: answers,
            source: AnswerSource.ai,
            confidence: 0.85,
            explanation: '豆包AI分析结果',
            queryTime: Duration.zero,
          );
        } else {
          print('❌ === 豆包AI解析失败 ===');
          print('💬 AI回答: $aiResponse');
          print('🔍 未能从回答中提取有效答案');
          print('========================');
        }
      } else {
        print('❌ === 豆包AI响应异常 ===');
        print('📄 响应数据结构异常或为空');
        print('========================');
      }

      return AnswerResult(
        answers: [],
        source: AnswerSource.ai,
        confidence: 0.0,
        explanation: '豆包AI未能解析出答案',
        queryTime: Duration.zero,
      );
      
    } catch (e) {
      print('❌ === 豆包AI请求异常 ===');
      print('🚫 异常类型: ${e.runtimeType}');
      print('📄 错误详情: $e');
      
      // 如果是DioException，打印更详细的错误信息
      if (e is DioException) {
        print('📊 状态码: ${e.response?.statusCode}');
        print('📋 响应头: ${e.response?.headers}');
        print('📄 响应数据: ${e.response?.data}');
        print('🔗 请求URL: ${e.requestOptions.uri}');
        print('📤 请求头: ${e.requestOptions.headers}');
        print('📝 请求数据: ${e.requestOptions.data}');
      }
      print('========================');
      
      return AnswerResult(
        answers: [],
        source: AnswerSource.ai,
        confidence: 0.0,
        explanation: '豆包AI查询失败: $e',
        queryTime: Duration.zero,
      );
    }
  }

  /// 构建AI查询的提示词
  String _buildAIPrompt(String questionContent, List<String> options, QuestionType type) {
    StringBuffer prompt = StringBuffer();
    
    // 使用标准化的题目格式
    prompt.writeln('(${_getTypeDisplayName(type)}) $questionContent');
    
    if (options.isNotEmpty) {
      // 如果选项已经是完整格式（带字母），直接使用
      // 如果是纯内容，则添加字母
      for (String option in options) {
        if (option.contains('：') && RegExp(r'^[A-D]：').hasMatch(option)) {
          // 已经是完整格式
          prompt.writeln(option);
        } else {
          // 纯内容格式，需要添加字母
          int index = options.indexOf(option);
          if (index < 26) {
            prompt.writeln('${String.fromCharCode(65 + index)}：$option');
          }
        }
      }
    }
    
    prompt.writeln();
    
    // 根据题型给出明确的答题要求
    switch (type) {
      case QuestionType.single:
        prompt.writeln('这是单选题，请选择唯一正确答案，只回答选项字母（如：A）。');
        break;
      case QuestionType.multiple:
        prompt.writeln('这是多选题，请选择所有正确答案，用逗号分隔选项字母（如：A,C）。');
        break;
      case QuestionType.judge:
        prompt.writeln('这是判断题，请判断题目说法是否正确，回答"正确"或"错误"。');
        break;
    }
    
    return prompt.toString();
  }

  /// 解析AI响应
  List<String> _parseAIResponse(String response, List<String> options, QuestionType type) {
    List<String> answers = [];
    
    print('🔍 === AI响应解析过程 ===');
    print('📝 原始回答: $response');
    print('📋 题目类型: ${_getTypeDisplayName(type)}');
    print('📊 可选选项: ${options.length}个');
    print('📋 选项格式: ${options.isNotEmpty && options.first.contains('：') ? '完整格式' : '纯内容格式'}');
    
    try {
      // 清理响应文本
      String cleanResponse = response.trim().toUpperCase();
      print('🧹 清理后文本: $cleanResponse');
      
      // 根据题目类型解析
      switch (type) {
        case QuestionType.judge:
          // 判断题：查找"正确"、"错误"等关键词
          print('🔍 判断题解析...');
          if (cleanResponse.contains('正确') || cleanResponse.contains('TRUE') || cleanResponse.contains('对')) {
            answers.add('正确');
            print('✅ 识别为：正确');
          } else if (cleanResponse.contains('错误') || cleanResponse.contains('FALSE') || cleanResponse.contains('错')) {
            answers.add('错误');
            print('✅ 识别为：错误');
          } else {
            print('❌ 未识别出判断结果');
          }
          break;
          
        case QuestionType.single:
        case QuestionType.multiple:
          // 选择题：查找选项字母
          print('🔍 选择题解析...');
          final pattern = RegExp(r'[A-D]');
          final matches = pattern.allMatches(cleanResponse);
          print('🔤 找到字母: ${matches.map((m) => m.group(0)).join(", ")}');
          
          Set<String> foundAnswers = {};
          for (final match in matches) {
            String letter = match.group(0)!;
            
            // 在选项中查找对应字母的完整选项
            for (String option in options) {
              if (option.contains('：') && RegExp(r'^[A-D]：').hasMatch(option)) {
                // 选项已经是完整格式，直接匹配字母
                if (option.startsWith('$letter：')) {
                  foundAnswers.add(option);
                  print('✅ 选择选项: $option');
                  break;
                }
              } else {
                // 选项是纯内容格式，需要构建完整格式
                int index = letter.codeUnitAt(0) - 'A'.codeUnitAt(0);
                if (index >= 0 && index < options.length) {
                  String fullAnswer = '$letter：${options[index]}';
                  foundAnswers.add(fullAnswer);
                  print('✅ 选择选项: $fullAnswer');
                  break;
                }
              }
            }
            
            // 单选题只要第一个答案
            if (type == QuestionType.single && foundAnswers.isNotEmpty) break;
          }
          answers.addAll(foundAnswers);
          
          // 如果没找到字母，尝试直接匹配选项内容
          if (answers.isEmpty) {
            print('🔍 尝试直接匹配选项内容...');
            for (String option in options) {
              if (response.contains(option)) {
                answers.add(option);
                print('✅ 内容匹配: ${option}');
                if (type == QuestionType.single) break;
              }
            }
          }
          
          if (answers.isEmpty) {
            print('❌ 未识别出任何选项');
          }
          break;
      }
      
      print('🎯 === 最终解析结果 ===');
      print('📊 解析出${answers.length}个答案: ${answers.join(", ")}');
      print('✨ 解析成功: ${answers.isNotEmpty ? "是" : "否"}');
      print('========================');
      
    } catch (e) {
      print('❌ === AI响应解析异常 ===');
      print('🚫 错误信息: $e');
      print('========================');
    }
    
    return answers;
  }

  /// 清理资源
  void dispose() {
    _dio.close();
  }
} 