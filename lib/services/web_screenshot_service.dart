import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../services/ocr_service.dart';
import '../services/answer_service.dart';
import '../services/database_service.dart';
import '../models/question.dart';
import '../utils/notification_helper.dart';

/// Web平台专用截图处理服务
class WebScreenshotService {
  static final WebScreenshotService _instance = WebScreenshotService._internal();
  factory WebScreenshotService() => _instance;
  WebScreenshotService._internal();

  // 服务依赖
  final OCRService _ocrService = OCRService();
  final AnswerService _answerService = AnswerService();
  final DatabaseService _database = DatabaseService();
  final NotificationHelper _notification = NotificationHelper();

  // 状态管理
  bool _isProcessing = false;
  StreamController<bool> _processingController = StreamController<bool>.broadcast();

  // 支持的图片格式
  static const List<String> _supportedImageTypes = [
    'image/png',
    'image/jpeg', 
    'image/jpg',
    'image/gif',
    'image/bmp',
    'image/webp'
  ];

  /// 是否正在处理
  bool get isProcessing => _isProcessing;
  
  /// 处理状态流
  Stream<bool> get processingStream => _processingController.stream;

  /// 初始化服务
  void initialize() {
    _setupDragAndDrop();
    print('📱 Web截图服务已初始化');
  }

  /// 设置拖拽和放置功能
  void _setupDragAndDrop() {
    if (!kIsWeb) return;

    // 阻止默认的拖拽行为
    html.document.addEventListener('dragover', (event) {
      event.preventDefault();
    });

    html.document.addEventListener('dragenter', (event) {
      event.preventDefault();
    });

    // 处理文件放置
    html.document.addEventListener('drop', (event) {
      event.preventDefault();
      final dragEvent = event as html.MouseEvent;
      final files = (dragEvent as dynamic).dataTransfer?.files;
      if (files != null && files.isNotEmpty) {
        handleDroppedFiles(files);
      }
    });

    print('📱 Web拖拽功能已设置');
  }

  /// 选择并处理图片
  Future<void> selectAndProcessImage() async {
    if (_isProcessing) {
      print('⚠️ 正在处理中，请稍候...');
      return;
    }

    try {
      final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.multiple = false;

      uploadInput.onChange.listen((event) async {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          await _processFile(files.first);
        }
      });

      uploadInput.click();
    } catch (e) {
      print('❌ 选择图片失败: $e');
      await _notification.showError('选择图片失败: $e');
    }
  }

  /// 处理拖拽的文件
  Future<void> handleDroppedFiles(List<html.File> files) async {
    if (_isProcessing) {
      print('⚠️ 正在处理中，请稍候...');
      return;
    }

    if (files.isEmpty) {
      return;
    }

    // 只处理第一个文件
    await _processFile(files.first);
  }

  /// 处理单个文件
  Future<void> _processFile(html.File file) async {
    try {
      // 检查文件类型
      if (!_supportedImageTypes.contains(file.type)) {
        throw Exception('不支持的文件格式: ${file.type}');
      }

      // 检查文件大小（限制10MB）
      const maxSize = 10 * 1024 * 1024;
      if (file.size > maxSize) {
        throw Exception('文件太大，请选择小于10MB的图片');
      }

      print('📤 开始处理图片: ${file.name} (${file.type}, ${(file.size / 1024).toStringAsFixed(1)}KB)');

      _updateProcessingState(true);

      // 读取文件字节
      final reader = html.FileReader();
      final completer = Completer<Uint8List>();

      reader.onLoad.listen((event) {
        final result = reader.result as List<int>;
        completer.complete(Uint8List.fromList(result));
      });

      reader.onError.listen((event) {
        completer.completeError(Exception('文件读取失败'));
      });

      reader.readAsArrayBuffer(file);
      final imageBytes = await completer.future;

      // 处理图片
      await _processImageBytes(imageBytes, file.name);

    } catch (e) {
      print('❌ 处理文件失败: $e');
      await _notification.showError('处理文件失败: $e');
    } finally {
      _updateProcessingState(false);
    }
  }

  /// 处理图片字节数据
  Future<void> _processImageBytes(Uint8List imageBytes, String fileName) async {
    try {
      print('🔍 开始处理图片数据...');

      // 1. 图片预处理
      final processedBytes = await _preprocessImage(imageBytes);

      // 2. OCR识别
      final parsedQuestion = await _ocrService.recognizeAndParseQuestion(processedBytes);
      if (parsedQuestion == null) {
        throw Exception('无法识别题目内容');
      }

      print('✅ 识别到题目: ${parsedQuestion.content}');

      // 3. 查询答案
      final answerResult = await _answerService.queryAnswer(
        parsedQuestion.content,
        parsedQuestion.options,
        parsedQuestion.type,
      );

      if (!answerResult.hasAnswers) {
        throw Exception('未找到答案');
      }

      print('✅ 找到答案: ${answerResult.formattedAnswers} (来源: ${answerResult.source.name})');

      // 4. 创建题目对象
      final question = Question(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        number: parsedQuestion.number,
        type: parsedQuestion.type,
        content: parsedQuestion.content,
        options: parsedQuestion.options,
        correctAnswers: answerResult.answers,
        createdAt: DateTime.now(),
        usageCount: 1,
        confidence: answerResult.confidence,
        answerSource: answerResult.source,
      );

      // 5. 显示结果
      await _showResult(question, answerResult, fileName);

      // 6. 保存到题库（如果来源不是本地题库）
      if (answerResult.source != AnswerSource.database) {
        await _database.insertQuestion(question);
      } else {
        await _database.updateQuestionUsage(question.id);
      }

    } catch (e) {
      print('❌ 处理图片失败: $e');
      rethrow;
    }
  }

  /// 图片预处理
  Future<Uint8List> _preprocessImage(Uint8List imageBytes) async {
    try {
      // 解码图片
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('无法解码图片');
      }

      // 调整图片大小（如果太大）
      img.Image processedImage = image;
      const maxWidth = 1920;
      const maxHeight = 1080;

      if (image.width > maxWidth || image.height > maxHeight) {
        final double scale = math.min(maxWidth / image.width, maxHeight / image.height);
        final newWidth = (image.width * scale).round();
        final newHeight = (image.height * scale).round();
        processedImage = img.copyResize(image, width: newWidth, height: newHeight);
        print('📏 图片尺寸调整: ${image.width}x${image.height} -> ${newWidth}x${newHeight}');
      }

      // 增强对比度
      processedImage = img.adjustColor(
        processedImage,
        contrast: 1.2,
        brightness: 1.1,
      );

      // 编码为PNG格式
      final pngBytes = img.encodePng(processedImage);
      return Uint8List.fromList(pngBytes);

    } catch (e) {
      print('⚠️ 图片预处理失败，使用原图: $e');
      return imageBytes;
    }
  }

  /// 显示处理结果
  Future<void> _showResult(Question question, AnswerResult answerResult, String fileName) async {
    try {
      // 构建详细的答案显示内容
      String answerContent = _formatAnswerForDisplay(question, answerResult);
      
      // 显示系统通知
      await _notification.showAnswer(
        title: '🎯 图片识别成功！',
        content: answerContent,
        source: '文件: $fileName',
      );

      // 在控制台显示完整结果
      print('🎯 === 识别结果 ===');
      print('📁 文件名: $fileName');
      print('📋 题目类型: ${question.typeDescription}');
      print('📄 题目内容: ${question.content}');
      print('📋 选项列表:');
      for (int i = 0; i < question.options.length; i++) {
        print('   ${String.fromCharCode(65 + i)}. ${question.options[i]}');
      }
      print('🎯 推荐答案: ${answerResult.formattedAnswers}');
      print('📊 置信度: ${(answerResult.confidence * 100).toStringAsFixed(0)}%');
      print('🔍 答案来源: ${answerResult.source.name}');
      print('==================');

    } catch (e) {
      print('❌ 显示结果失败: $e');
    }
  }

  /// 格式化答案显示内容
  String _formatAnswerForDisplay(Question question, AnswerResult answerResult) {
    StringBuffer content = StringBuffer();
    
    // 题目类型
    content.writeln('📋 ${question.typeDescription}');
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

  /// 更新处理状态
  void _updateProcessingState(bool processing) {
    if (_isProcessing != processing) {
      _isProcessing = processing;
      _processingController.add(_isProcessing);
    }
  }

  /// 获取使用统计
  Map<String, dynamic> getStatistics() {
    return {
      'supportedFormats': _supportedImageTypes,
      'maxFileSize': '10MB',
      'features': [
        '文件选择上传',
        '拖拽上传',
        '图片预处理',
        '自动识别',
        '答案查询',
      ],
    };
  }

  /// 清理资源
  void dispose() {
    _processingController.close();
    _ocrService.dispose();
    _answerService.dispose();
  }
} 