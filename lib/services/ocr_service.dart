import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/question.dart';
import '../utils/text_parser.dart';
import '../utils/config.dart';
import 'alicloud_market_ocr_service.dart';

/// OCR服务提供商
enum OCRProvider {
  alicloudMarket,  // 阿里云市场OCR (唯一支持的OCR服务)
}

/// OCR识别结果
class OCRResult {
  final String fullText; // 完整识别文本
  final double confidence; // 识别置信度
  final List<String> lines; // 按行分割的文本
  
  OCRResult({
    required this.fullText,
    required this.confidence,
    required this.lines,
  });
}

/// 题目解析结果
class ParsedQuestion {
  final int? number; // 题目编号
  final QuestionType type; // 题目类型
  final String content; // 题目内容
  final List<String> options; // 选项列表
  final bool hasImage; // 是否包含图片
  final double confidence; // 解析置信度
  
  ParsedQuestion({
    this.number,
    required this.type,
    required this.content,
    required this.options,
    this.hasImage = false,
    required this.confidence,
  });
}

class OCRService {
  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;
  OCRService._internal();

  final TextParser _textParser = TextParser();
  final AlicloudMarketOcrService _alicloudMarketOcr = AlicloudMarketOcrService();
  
  /// 当前使用的OCR提供商
  OCRProvider _currentProvider = OCRProvider.alicloudMarket;
  
  /// 设置OCR提供商
  void setProvider(OCRProvider provider) {
    _currentProvider = provider;
    print('🔄 切换OCR提供商至: ${provider.name}');
  }
  
  /// 获取当前OCR提供商
  OCRProvider get currentProvider => _currentProvider;
  
  /// 检查OCR服务配置
  void autoSelectProvider() {
    // 检查阿里云市场OCR配置
    print('🔍 OCR配置检查:');
    print('  阿里云市场OCR AppCode: ${AppConfig.alicloudMarketAppCode}');
    print('  阿里云市场OCR已配置: ${AppConfig.isAlicloudMarketOcrConfigured}');
    
    if (AppConfig.isAlicloudMarketOcrConfigured) {
      _currentProvider = OCRProvider.alicloudMarket;
      print('🌐 使用阿里云市场OCR服务');
    } else {
      throw Exception('❌ 阿里云市场OCR未配置！请在config.dart中设置alicloudMarketAppCode');
    }
  }

  /// 初始化OCR服务
  Future<void> initialize() async {
    try {
      // 检查配置
      autoSelectProvider();
      
      // 初始化阿里云市场OCR
      _alicloudMarketOcr.initialize();
      
      print('✅ OCR服务初始化成功，当前提供商: ${_currentProvider.name}');
    } catch (e) {
      print('❌ OCR服务初始化失败: $e');
      rethrow;
    }
  }



  /// 从Uint8List识别文字
  Future<OCRResult> recognizeTextFromBytes(Uint8List imageBytes) async {
    try {
      print('🌐 使用阿里云市场OCR识别...');
      
      final result = await _alicloudMarketOcr.recognizeText(
        imageBytes,
        prob: true,
        charInfo: true,
        rotate: true,
        table: false,
      );
      
      if (!result.success) {
        print('❌ 阿里云市场OCR识别失败: ${result.error}');
        throw Exception('OCR识别失败: ${result.error}');
      }
      
      return OCRResult(
        fullText: result.fullText,
        confidence: result.confidence,
        lines: result.lines,
      );
      
    } catch (e) {
      print('❌ OCR识别失败: $e');
      rethrow;
    }
  }



  /// 解析识别出的文字为题目结构
  Future<ParsedQuestion?> parseQuestion(OCRResult ocrResult) async {
    if (ocrResult.fullText.isEmpty) {
      return null;
    }

    try {
      // 使用文本解析器解析题目
      final parsedData = _textParser.parseQuestionText(ocrResult.fullText);
      
      if (parsedData == null) {
        return null;
      }

      return ParsedQuestion(
        number: parsedData['number'],
        type: parsedData['type'],
        content: parsedData['content'],
        options: parsedData['options'],
        hasImage: _detectImageInText(ocrResult.fullText),
        confidence: ocrResult.confidence,
      );
    } catch (e) {
      print('解析题目失败: $e');
      return null;
    }
  }

  /// 完整的识别和解析流程
  Future<ParsedQuestion?> recognizeAndParseQuestion(Uint8List imageBytes) async {
    final ocrResult = await recognizeTextFromBytes(imageBytes);
    final parsedQuestion = await parseQuestion(ocrResult);
    
    // 打印完整的题目解析信息
    if (parsedQuestion != null) {
      print('📋 === 题目解析结果 ===');
      print('📌 题目编号: ${parsedQuestion.number ?? "未识别"}');
             print('📝 题目类型: ${_getTypeDisplayName(parsedQuestion.type)}');
      print('📄 题目内容: ${parsedQuestion.content}');
      print('📋 选项列表:');
      for (int i = 0; i < parsedQuestion.options.length; i++) {
        print('   ${String.fromCharCode(65 + i)}. ${parsedQuestion.options[i]}');
      }
      print('🎯 识别置信度: ${(parsedQuestion.confidence * 100).toStringAsFixed(1)}%');
      print('🖼️ 包含图片: ${parsedQuestion.hasImage ? "是" : "否"}');
      print('========================');
    } else {
      print('❌ 题目解析失败');
    }
    
    return parsedQuestion;
  }

  /// 检测文本中是否提到图片
  bool _detectImageInText(String text) {
    final imageKeywords = ['图', '图片', '如图', '下图', '上图', '图中', '图示'];
    return imageKeywords.any((keyword) => text.contains(keyword));
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



  /// 获取可用的OCR提供商
  List<OCRProvider> getAvailableProviders() {
    return [OCRProvider.alicloudMarket];
  }
  
  /// 检查当前提供商配置状态
  Map<String, dynamic> getProviderStatus() {
    return {
      'current': _currentProvider.name,
      'available': ['alicloudMarket'],
      'alicloudMarket': AppConfig.isAlicloudMarketOcrConfigured,
    };
  }
  
  /// 获取提供商描述
  String getProviderDescription(OCRProvider provider) {
    switch (provider) {
      case OCRProvider.alicloudMarket:
        return '阿里云市场OCR - 高性价比云端识别，配置简单，支持中英文混合识别';
    }
  }

  /// 清理资源
  void dispose() {
    _alicloudMarketOcr.dispose();
  }
} 