import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/question.dart';
import 'ocr_service.dart';
import 'answer_service.dart';
import 'database_service.dart';
import '../utils/notification_helper.dart';

/// Web环境专用的截图处理服务
/// 替代系统级截图监听，使用文件上传方式
class WebScreenshotService {
  static final WebScreenshotService _instance = WebScreenshotService._internal();
  factory WebScreenshotService() => _instance;
  WebScreenshotService._internal();

  final OCRService _ocrService = OCRService();
  final AnswerService _answerService = AnswerService();
  final DatabaseService _databaseService = DatabaseService();
  final NotificationHelper _notificationHelper = NotificationHelper();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isProcessing = false;

  /// 检查是否为Web环境
  bool get isWebEnvironment => kIsWeb;

  /// 显示文件选择器，让用户手动选择图片
  Future<void> selectAndProcessImage() async {
    if (_isProcessing) {
      print('⚠️ 正在处理图片，请稍候...');
      return;
    }

    try {
      _isProcessing = true;
      
      // 使用ImagePicker选择图片
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (image != null) {
        await _processSelectedImage(image);
      } else {
        print('📷 未选择图片');
      }
    } catch (e) {
      print('❌ 选择图片失败: $e');
      await _notificationHelper.showError('选择图片失败: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// 处理拖拽上传的图片
  Future<void> handleDroppedFiles(List<html.File> files) async {
    if (_isProcessing) {
      print('⚠️ 正在处理图片，请稍候...');
      return;
    }

    if (files.isEmpty) return;

    try {
      _isProcessing = true;
      
      final html.File file = files.first;
      
      // 检查文件类型
      if (!_isImageFile(file.type)) {
        await _notificationHelper.showError('请选择图片文件 (PNG, JPG, JPEG)');
        return;
      }

      // 读取文件数据
      final Uint8List imageBytes = await _readFileAsBytes(file);
      
      // 处理图片
      await _processImageBytes(imageBytes, file.name);
      
    } catch (e) {
      print('❌ 处理拖拽文件失败: $e');
      await _notificationHelper.showError('处理文件失败: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// 处理选中的图片文件
  Future<void> _processSelectedImage(XFile imageFile) async {
    try {
      print('📷 开始处理图片: ${imageFile.name}');
      
      // 读取图片数据
      final Uint8List imageBytes = await imageFile.readAsBytes();
      
      // 处理图片
      await _processImageBytes(imageBytes, imageFile.name);
      
    } catch (e) {
      print('❌ 处理图片失败: $e');
      await _notificationHelper.showError('处理图片失败: $e');
    }
  }

  /// 处理图片字节数据
  Future<void> _processImageBytes(Uint8List imageBytes, String fileName) async {
    try {
      print('🔍 开始OCR识别...');
      
      // OCR识别 - 不显示进度通知
      final ocrResult = await _ocrService.recognizeTextFromBytes(imageBytes);
      
      if (ocrResult.fullText.isEmpty) {
        await _notificationHelper.showError('未识别到文字内容，请确保图片清晰');
        return;
      }

      String previewText = ocrResult.fullText.length > 50 
          ? '${ocrResult.fullText.substring(0, 50)}...'
          : ocrResult.fullText;
      print('✅ OCR识别完成: $previewText');

      // 解析题目 - 不显示进度通知
      final parsedQuestion = await _ocrService.parseQuestion(ocrResult);
      
      if (parsedQuestion == null) {
        await _notificationHelper.showError('无法解析题目，请检查图片内容');
        return;
      }

      print('✅ 题目解析完成: ${parsedQuestion.type.toString()}');

      // 不显示题目识别通知，直接查找答案
      final answerResult = await _answerService.queryAnswer(
        parsedQuestion.content,
        parsedQuestion.options,
        parsedQuestion.type,
      );

      // 只在找到答案时显示通知
      if (answerResult.hasAnswers) {
        print('✅ 找到答案: ${answerResult.formattedAnswers}');
        
        // 构建详细的答案显示内容
        String answerContent = _formatAnswerForDisplay(
          parsedQuestion, 
          answerResult,
        );
        
        // 显示最终答案通知
        await _notificationHelper.showAnswer(
          title: '🎯 找到答案！',
          content: answerContent,
          source: _getSourceText(answerResult.source),
        );

        // 保存到数据库
        await _saveToDatabase(parsedQuestion, answerResult);
        
      } else {
        print('❌ 未找到答案');
        await _notificationHelper.showError('未找到相关答案，建议手动查找');
      }

    } catch (e) {
      print('❌ 处理图片失败: $e');
      await _notificationHelper.showError('处理失败: $e');
    }
  }

  /// 格式化答案显示内容
  String _formatAnswerForDisplay(ParsedQuestion parsedQuestion, AnswerResult answerResult) {
    StringBuffer content = StringBuffer();
    
    // 题目类型
    content.writeln('📋 ${_getQuestionTypeText(parsedQuestion.type)}');
    content.writeln('');
    
    // 推荐答案
    content.writeln('🎯 推荐答案:');
    if (answerResult.answers.isEmpty) {
      content.writeln('暂无答案');
    } else {
      for (String answer in answerResult.answers) {
        content.writeln('✅ $answer');
      }
    }
    content.writeln('');
    
    // 置信度
    String confidenceText = (answerResult.confidence * 100).toStringAsFixed(0);
    content.writeln('📊 置信度: $confidenceText%');
    
    // 处理时间
    if (answerResult.queryTime.inMilliseconds > 0) {
      content.writeln('⏱️ 处理时间: ${answerResult.queryTime.inMilliseconds}ms');
    }
    
    return content.toString().trim();
  }

  /// 保存到数据库
  Future<void> _saveToDatabase(ParsedQuestion parsedQuestion, AnswerResult answerResult) async {
    try {
      final question = Question(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: parsedQuestion.type,
        content: parsedQuestion.content,
        options: parsedQuestion.options,
        correctAnswers: answerResult.answers,
        createdAt: DateTime.now(),
        confidence: answerResult.confidence,
        answerSource: answerResult.source,
      );

      await _databaseService.insertQuestion(question);
      print('✅ 题目已保存到数据库');
      
    } catch (e) {
      print('⚠️ 保存到数据库失败: $e');
    }
  }

  /// 读取HTML File为字节数组
  Future<Uint8List> _readFileAsBytes(html.File file) async {
    final html.FileReader reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    
    await reader.onLoad.first;
    
    return Uint8List.fromList(reader.result as List<int>);
  }

  /// 检查是否为图片文件
  bool _isImageFile(String mimeType) {
    return mimeType.startsWith('image/') && 
           (mimeType.contains('png') || 
            mimeType.contains('jpg') || 
            mimeType.contains('jpeg'));
  }

  /// 获取题目类型文本
  String _getQuestionTypeText(QuestionType type) {
    switch (type) {
      case QuestionType.single:
        return '单选题';
      case QuestionType.multiple:
        return '多选题';
      case QuestionType.judge:
        return '判断题';
    }
  }

  /// 获取答案来源文本
  String _getSourceText(AnswerSource source) {
    switch (source) {
      case AnswerSource.database:
        return '本地题库';
      case AnswerSource.search:
        return '网络搜索';
      case AnswerSource.ai:
        return 'AI助手';
    }
  }

  /// 获取处理状态
  bool get isProcessing => _isProcessing;

  /// 清理资源
  void dispose() {
    // Web环境下的清理工作
  }
} 