import 'dart:convert';
import '../models/question.dart';
import 'dart:math' as math;

class TextParser {
  static final TextParser _instance = TextParser._internal();
  factory TextParser() => _instance;
  TextParser._internal();

  /// 解析题目文本
  Map<String, dynamic>? parseQuestionText(String text) {
    if (text.trim().isEmpty) return null;

    try {
      print('\n🔍 开始解析OCR文本:');
      print('原始OCR结果: $text');
      
      // 清理文本
      String cleanText = _cleanText(text);
      print('✅ 清理后文本: $cleanText');
      
      // 提取题目编号
      int? number = _extractQuestionNumber(cleanText);
      print('📝 题目编号: $number');
      
      // 判断题目类型
      QuestionType type = _determineQuestionType(cleanText);
      print('📋 题目类型: ${type.toString().split('.').last}');
      
      // 提取题目内容和选项
      final contentAndOptions = _extractContentAndOptions(cleanText, type);
      
      if (contentAndOptions == null) {
        print('❌ 提取题目内容和选项失败');
        return null;
      }

      print('📄 题目内容: ${contentAndOptions['content']}');
      print('📜 选项列表: ${contentAndOptions['options']}');

      final result = {
        'number': number,
        'type': type,
        'content': contentAndOptions['content'],
        'options': contentAndOptions['options'],
      };
      
      print('✅ 解析完成: $result\n');
      return result;
    } catch (e) {
      print('❌ 解析题目文本失败: $e');
      return null;
    }
  }

  /// 清理文本
  String _cleanText(String text) {
    // 1. 移除网页界面元素
    text = _removeWebInterfaceElements(text);
    
    // 2. 基础文本清理
    text = text
        .replaceAll(RegExp(r'\s+'), ' ') // 多个空白字符替换为单个空格
        .replaceAll(RegExp(r'[""''`]'), '"') // 统一引号
        .replaceAll('（', '(')
        .replaceAll('）', ')')
        .trim();
    
    return text;
  }

  /// 移除网页界面元素
  String _removeWebInterfaceElements(String text) {
    // 移除常见的网页界面干扰文本
    final interfacePatterns = [
      // 考试界面元素
      RegExp(r'返回\s+网上考试.*?剩余\s+\d+s', multiLine: true),
      RegExp(r'^\s*\d+\s+\d+\s+\d+.*?剩余\s+\d+s', multiLine: true),
      RegExp(r'剩余\s+\d+s', multiLine: true),
      RegExp(r'下一题.*$', multiLine: true),
      RegExp(r'上一题.*$', multiLine: true),
      RegExp(r'知乎\(.*$', multiLine: true),
      RegExp(r'@\w+.*$', multiLine: true),
      // 导航和控制元素
      RegExp(r'^\s*\d+\s+\d+\s+\d+\s+\d+\s+\d+.*?剩余', multiLine: true),
      RegExp(r'(上一题|下一题|提交|确定|取消)', multiLine: true),
      // 题目编号序列（如 1 2 3 4 5 6 7 8 9 10...）
      RegExp(r'^\s*[1-9]\d*\s+[1-9]\d*\s+[1-9]\d*\s+[1-9]\d*\s+[1-9]\d*', multiLine: true),
      // JSON 格式元素
      RegExp(r'"content":\s*"<', multiLine: true),
      RegExp(r'","algo_version".*$', multiLine: true),
      RegExp(r'"[^"]*"\s*:\s*"[^"]*"', multiLine: true),
      // 网页结构元素
      RegExp(r'<[^>]*>', multiLine: true), // HTML标签
      RegExp(r'网上考试', multiLine: true),
    ];

    for (final pattern in interfacePatterns) {
      text = text.replaceAll(pattern, ' ');
    }

    // 清理多余的空格和特殊字符
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return text;
  }

  /// 提取题目编号
  int? _extractQuestionNumber(String text) {
    // 匹配模式: "1.", "1、", "第1题", "题目1", "(1)", "(多选题) 19、"
    final patterns = [
      RegExp(r'(\d+)[.、]'), // 匹配任何位置的数字+句号/顿号
      RegExp(r'第(\d+)题'),
      RegExp(r'题目(\d+)'), 
      RegExp(r'\((\d+)\)'),
      RegExp(r'(\d+)\s'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return int.tryParse(match.group(1)!);
      }
    }

    return null;
  }

  /// 判断题目类型
  QuestionType _determineQuestionType(String text) {
    // 首先检查明确的题型标记
    if (RegExp(r'\(多选题?\)|\（多选题?\）|多选题').hasMatch(text)) {
      return QuestionType.multiple;
    }
    if (RegExp(r'\(单选题?\)|\（单选题?\）|单选题').hasMatch(text)) {
      return QuestionType.single;
    }
    if (RegExp(r'\(判断题?\)|\（判断题?\）|判断题').hasMatch(text)) {
      return QuestionType.judge;
    }

    // 判断题关键词
    final judgeKeywords = [
      '正确', '错误', '对', '错', '是否', '判断', '对错',
      '√', '×', '✓', '✗', 'true', 'false', 'T', 'F'
    ];

    // 多选题关键词
    final multipleKeywords = [
      '多选', '不正确的是', '错误的是', '以下哪些', '包括', '有哪些',
      '选择所有', '全部正确', '多项', '下列哪几', '可能'
    ];

    String lowerText = text.toLowerCase();
    
    // 检查是否为判断题
    for (String keyword in judgeKeywords) {
      if (text.contains(keyword) || lowerText.contains(keyword.toLowerCase())) {
        return QuestionType.judge;
      }
    }

    // 检查是否为多选题
    for (String keyword in multipleKeywords) {
      if (text.contains(keyword)) {
        return QuestionType.multiple;
      }
    }

    // 通过选项数量判断
    List<String> options = _extractOptions(text);
    if (options.length == 2) {
      return QuestionType.judge;
    } else if (options.length >= 4) {
      // 检查选项中是否有多选的暗示
      String optionsText = options.join(' ');
      if (multipleKeywords.any((keyword) => optionsText.contains(keyword))) {
        return QuestionType.multiple;
      }
    }

    // 默认为单选题
    return QuestionType.single;
  }

  /// 提取题目内容和选项
  Map<String, dynamic>? _extractContentAndOptions(String text, QuestionType type) {
    try {
      // 移除题目编号
      String cleanText = _removeQuestionNumber(text);
      
      // 提取选项
      List<String> options = _extractOptions(cleanText);
      
      // 提取题目内容（选项之前的部分）
      String content = _extractQuestionContent(cleanText, options);
      
      if (content.isEmpty) return null;

      // 根据题目类型调整选项
      options = _adjustOptionsForType(options, type);

      return {
        'content': content.trim(),
        'options': options,
      };
    } catch (e) {
      print('提取内容和选项失败: $e');
      return null;
    }
  }

  /// 移除题目编号
  String _removeQuestionNumber(String text) {
    final patterns = [
      // 题型标记+编号组合，如 "(多选题) 19、"
      RegExp(r'^\s*\([^)]*\)\s*\d+[.、，,]\s*'),
      // 单独的题型标记，如 "(多选题)"
      RegExp(r'^\s*\([^)]*\)\s*'),
      // 行首编号，支持多种分隔符
      RegExp(r'^\s*\d+[.、，,．]\s*'),
      // 其他格式的题目编号
      RegExp(r'^第\d+题[.、]?\s*'),
      RegExp(r'^题目\d+[.、]?\s*'),
      RegExp(r'^\(\d+\)\s*'),
      // 处理可能残留的数字
      RegExp(r'^\s*\d+\s+'),
    ];

    for (final pattern in patterns) {
      text = text.replaceFirst(pattern, '');
    }

    return text.trim();
  }

  /// 提取选项
  List<String> _extractOptions(String text) {
    List<String> options = [];

    // 选项模式: A. B. C. D. 或 A、B、C、D、或 A：B：C：D：或 (A) (B) (C) (D)
    final patterns = [
      RegExp(r'[A-Z][：]\s*([^A-Z]*?)(?=[A-Z][：]|$)', multiLine: true), // 中文冒号格式 A：
      RegExp(r'[A-Z][.、]\s*([^A-Z]*?)(?=[A-Z][.、]|$)', multiLine: true), // 句号/顿号格式
      RegExp(r'\([A-Z]\)\s*([^(]*?)(?=\([A-Z]\)|$)', multiLine: true), // 括号格式
      RegExp(r'[①②③④⑤⑥]\s*([^①②③④⑤⑥]*?)(?=[①②③④⑤⑥]|$)', multiLine: true), // 圆圈数字
    ];

    for (final pattern in patterns) {
      final matches = pattern.allMatches(text);
      if (matches.isNotEmpty) {
        options.clear();
        int letterIndex = 0;
        for (final match in matches) {
          String option = match.group(1)?.trim() ?? '';
          if (option.isNotEmpty) {
            // 清理选项内容
            option = _cleanOptionContent(option);
            if (option.isNotEmpty && letterIndex < 26) {
              // 构建完整的选项格式：字母：内容
              String letter = String.fromCharCode(65 + letterIndex);
              String fullOption = '$letter：$option';
              options.add(fullOption);
              letterIndex++;
            }
          }
        }
        break;
      }
    }

    // 如果没有找到标准格式的选项，尝试其他方法
    if (options.isEmpty) {
      options = _extractOptionsAlternative(text);
    }

    return options;
  }

  /// 备选选项提取方法
  List<String> _extractOptionsAlternative(String text) {
    List<String> options = [];

    // 查找常见的选项关键词
    if (text.contains('正确') && text.contains('错误')) {
      options = ['A：正确', 'B：错误'];
    } else if (text.contains('对') && text.contains('错')) {
      options = ['A：对', 'B：错'];
    } else if (text.contains('是') && text.contains('否')) {
      options = ['A：是', 'B：否'];
    }

    return options;
  }

  /// 提取题目内容
  String _extractQuestionContent(String text, List<String> options) {
    if (options.isEmpty) {
      return _cleanQuestionContent(text);
    }

    // 查找第一个选项标识符的位置
    final optionPatterns = [
      RegExp(r'[A-Z][：]'), // 中文冒号格式 A：
      RegExp(r'[A-Z][.、]'), // 句号/顿号格式
      RegExp(r'\([A-Z]\)'), // 括号格式
      RegExp(r'[①②③④⑤⑥]'), // 圆圈数字
    ];

    int optionStartIndex = -1;
    for (final pattern in optionPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        optionStartIndex = match.start;
        break;
      }
    }

    String questionContent;
    if (optionStartIndex > 0) {
      questionContent = text.substring(0, optionStartIndex).trim();
    } else {
      // 如果找不到选项标识符，尝试通过第一个选项内容分割
      String firstOption = options.first;
      int contentEndIndex = text.indexOf(firstOption);
      if (contentEndIndex > 0) {
        // 向前查找选项标识符
        String beforeOption = text.substring(0, contentEndIndex);
        int lastIdentifierIndex = -1;
        
        for (int i = beforeOption.length - 1; i >= 0; i--) {
          String char = beforeOption[i];
          if (RegExp(r'[A-Z：.、()①②③④⑤⑥]').hasMatch(char)) {
            lastIdentifierIndex = i;
            break;
          }
        }
        
        if (lastIdentifierIndex > 0) {
          questionContent = beforeOption.substring(0, lastIdentifierIndex).trim();
        } else {
          questionContent = beforeOption.trim();
        }
      } else {
        questionContent = text;
      }
    }

    return _cleanQuestionContent(questionContent);
  }

  /// 清理题目内容
  String _cleanQuestionContent(String content) {
    // 移除题目编号和题型标记后的内容
    content = _removeQuestionNumber(content);
    
    // 清理题目内容中的多余空格和特殊字符
    content = content
        .replaceAll(RegExp(r'\s+'), ' ') // 多个空格合并为一个
        .replaceAll(RegExp(r'\s*([，。？！：；])\s*'), r'$1') // 标点符号前后去空格
        .trim();
    
    return content;
  }

  /// 清理选项内容
  String _cleanOptionContent(String option) {
    // 移除多余的空格
    option = option.replaceAll(RegExp(r'\s+'), ' ');
    
    // 移除标点符号前后的多余空格
    option = option.replaceAll(RegExp(r'\s*([，。？！：；])\s*'), r'$1');
    
    // 移除可能的后续选项标识符（如果解析不够精确）
    option = option.replaceAll(RegExp(r'\s+[A-Z][：.、].*$'), '');
    
    return option.trim();
  }

  /// 根据题目类型调整选项
  List<String> _adjustOptionsForType(List<String> options, QuestionType type) {
    switch (type) {
      case QuestionType.judge:
        if (options.length != 2) {
          // 如果不是2个选项，使用默认的判断题选项
          return ['A：正确', 'B：错误'];
        }
        break;
      case QuestionType.single:
      case QuestionType.multiple:
        // 确保至少有2个选项
        if (options.length < 2) {
          return [];
        }
        break;
    }
    return options;
  }

  /// 从答案文本中提取正确答案
  List<String> extractCorrectAnswers(String answerText, List<String> options) {
    List<String> correctAnswers = [];
    
    // 处理选项标识符 (A, B, C, D)
    final optionPattern = RegExp(r'[A-D]', caseSensitive: false);
    final matches = optionPattern.allMatches(answerText.toUpperCase());
    
    for (final match in matches) {
      String letter = match.group(0)!;
      // 在选项中查找对应字母的完整选项
      for (String option in options) {
        if (option.startsWith('$letter：')) {
          correctAnswers.add(option);
          break;
        }
      }
    }

    // 如果没有找到选项标识符，尝试直接匹配选项内容
    if (correctAnswers.isEmpty) {
      for (String option in options) {
        // 提取选项的纯内容部分进行匹配
        String optionContent = option.contains('：') 
            ? option.substring(option.indexOf('：') + 1)
            : option;
        if (answerText.contains(optionContent)) {
          correctAnswers.add(option);
        }
      }
    }

    return correctAnswers;
  }

  /// 计算文本相似度
  double calculateSimilarity(String text1, String text2) {
    if (text1.isEmpty || text2.isEmpty) return 0.0;
    
    // 简单的相似度算法
    String t1 = text1.toLowerCase().trim();
    String t2 = text2.toLowerCase().trim();
    
    if (t1 == t2) return 1.0;
    
    // 计算最长公共子序列长度
    int lcs = _longestCommonSubsequence(t1, t2);
    int maxLength = math.max(t1.length, t2.length);
    
    return lcs / maxLength;
  }

  /// 计算最长公共子序列长度
  int _longestCommonSubsequence(String text1, String text2) {
    int m = text1.length;
    int n = text2.length;
    
    List<List<int>> dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));
    
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        if (text1[i - 1] == text2[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1] + 1;
        } else {
          dp[i][j] = math.max(dp[i - 1][j], dp[i][j - 1]);
        }
      }
    }
    
    return dp[m][n];
  }
} 