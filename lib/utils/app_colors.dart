import 'package:flutter/material.dart';

/// 应用颜色配置
class AppColors {
  AppColors._();

  // 主色调
  static const Color primary = Color(0xFF6C5CE7);
  static const Color secondary = Color(0xFFA29BFE);
  static const Color accent = Color(0xFF00B894);

  // 背景色
  static const Color background = Color(0xFFFAFBFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8F9FA);

  // 文本色
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color textTertiary = Color(0xFF95A5A6);
  static const Color textHint = Color(0xFFBDC3C7);

  // 状态色
  static const Color success = Color(0xFF00B894);
  static const Color warning = Color(0xFFE17055);
  static const Color error = Color(0xFFD63031);
  static const Color info = Color(0xFF74B9FF);

  // 边框色
  static const Color border = Color(0xFFE0E6ED);
  static const Color borderLight = Color(0xFFF1F3F4);
  static const Color borderDark = Color(0xFFDFE6E9);

  // 阴影色
  static const Color shadow = Color(0x1A000000);
  static const Color shadowLight = Color(0x0D000000);

  // 渐变色
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF00B894), Color(0xFF00CEC9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFE17055), Color(0xFFE84393)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 题目类型色
  static const Color singleChoiceColor = Color(0xFF74B9FF);
  static const Color multipleChoiceColor = Color(0xFFE17055);
  static const Color judgeQuestionColor = Color(0xFF00B894);

  // 答案来源色
  static const Color databaseSourceColor = Color(0xFF6C5CE7);
  static const Color searchSourceColor = Color(0xFF00B894);
  static const Color aiSourceColor = Color(0xFFE17055);

  /// 根据题目类型获取颜色
  static Color getQuestionTypeColor(String type) {
    switch (type) {
      case '单选题':
        return singleChoiceColor;
      case '多选题':
        return multipleChoiceColor;
      case '判断题':
        return judgeQuestionColor;
      default:
        return primary;
    }
  }

  /// 根据答案来源获取颜色
  static Color getAnswerSourceColor(String source) {
    switch (source) {
      case '题库':
        return databaseSourceColor;
      case '网络':
        return searchSourceColor;
      case 'AI':
        return aiSourceColor;
      default:
        return primary;
    }
  }

  /// 获取监听状态颜色
  static Color getMonitorStatusColor(String status) {
    switch (status) {
      case 'running':
        return success;
      case 'starting':
        return warning;
      case 'error':
        return error;
      case 'stopped':
      default:
        return textSecondary;
    }
  }

  /// 获取置信度颜色
  static Color getConfidenceColor(double confidence) {
    if (confidence >= 0.8) {
      return success;
    } else if (confidence >= 0.6) {
      return warning;
    } else {
      return error;
    }
  }
} 