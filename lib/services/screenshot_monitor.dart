import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../services/ocr_service.dart';
import '../services/answer_service.dart';
import '../services/database_service.dart';
import '../widgets/answer_overlay.dart';
import '../models/question.dart';
import '../utils/notification_helper.dart';

// Web平台权限处理存根
import 'web_permission_stub.dart';

/// 截图监听状态
enum MonitorStatus {
  stopped,    // 已停止
  starting,   // 启动中
  running,    // 运行中
  error,      // 错误状态
}

/// 截图监听服务
class ScreenshotMonitor {
  static final ScreenshotMonitor _instance = ScreenshotMonitor._internal();
  factory ScreenshotMonitor() => _instance;
  ScreenshotMonitor._internal();

  // 平台通道
  static const MethodChannel _channel = MethodChannel('screenshot_monitor');
  
  // 服务依赖
  final OCRService _ocrService = OCRService();
  final AnswerService _answerService = AnswerService();
  final DatabaseService _database = DatabaseService();
  final NotificationHelper _notification = NotificationHelper();

  // 状态管理
  MonitorStatus _status = MonitorStatus.stopped;
  StreamController<MonitorStatus> _statusController = StreamController<MonitorStatus>.broadcast();
  
  // 监听配置
  Timer? _checkTimer;
  String? _lastScreenshotPath;
  DateTime? _lastProcessTime;
  
  // 统计数据
  int _totalQuestions = 0;
  int _successfulAnswers = 0;
  
  /// 获取当前状态
  MonitorStatus get status => _status;
  
  /// 状态变化流
  Stream<MonitorStatus> get statusStream => _statusController.stream;
  
  /// 统计数据
  Map<String, int> get statistics => {
    'total': _totalQuestions,
    'successful': _successfulAnswers,
    'accuracy': _totalQuestions > 0 ? ((_successfulAnswers / _totalQuestions) * 100).round() : 0,
  };

  /// 开始监听
  Future<bool> startMonitoring() async {
    if (_status == MonitorStatus.running) {
      return true;
    }

    // Web平台专用版本
    if (!kIsWeb) {
      print('当前版本仅支持Web平台');
      _updateStatus(MonitorStatus.stopped);
      return false;
    }

    try {
      _updateStatus(MonitorStatus.starting);
      
      // 1. 检查权限
      bool hasPermissions = await _checkPermissions();
      if (!hasPermissions) {
        _updateStatus(MonitorStatus.error);
        return false;
      }

      // 2. 初始化平台通道
      await _initializePlatformChannel();
      
      // 3. 启动监听（仅移动平台）
      bool started = await _startPlatformMonitoring();
      if (!started) {
        _updateStatus(MonitorStatus.error);
        return false;
      }

      // 4. 启动定时检查
      _startPeriodicCheck();
      
      _updateStatus(MonitorStatus.running);
      
      // 显示开始监听通知
      await _notification.showMonitoringStarted();
      
      return true;
    } catch (e) {
      print('启动监听失败: $e');
      _updateStatus(MonitorStatus.error);
      return false;
    }
  }

  /// 停止监听
  Future<void> stopMonitoring() async {
    if (_status == MonitorStatus.stopped) {
      return;
    }

    try {
      // 停止定时检查
      _checkTimer?.cancel();
      _checkTimer = null;
      
      // 停止平台监听
      await _stopPlatformMonitoring();
      
      _updateStatus(MonitorStatus.stopped);
      
      // 显示停止监听通知
      await _notification.showMonitoringStopped();
      
    } catch (e) {
      print('停止监听失败: $e');
    }
  }

  /// 检查权限
  Future<bool> _checkPermissions() async {
    // Web平台不需要权限检查
    if (kIsWeb) {
      return true;
    }
    
    try {
      // 检查存储权限
      PermissionStatus storageStatus = await Permission.storage.status;
      if (storageStatus != PermissionStatus.granted) {
        storageStatus = await Permission.storage.request();
        if (storageStatus != PermissionStatus.granted) {
          print('存储权限被拒绝');
          return false;
        }
      }

      // 检查通知权限
      PermissionStatus notificationStatus = await Permission.notification.status;
      if (notificationStatus != PermissionStatus.granted) {
        notificationStatus = await Permission.notification.request();
        if (notificationStatus != PermissionStatus.granted) {
          print('通知权限被拒绝，但继续运行');
        }
      }

      // 检查悬浮窗权限（移动平台）
      try {
        PermissionStatus systemAlertStatus = await Permission.systemAlertWindow.status;
        if (systemAlertStatus != PermissionStatus.granted) {
          systemAlertStatus = await Permission.systemAlertWindow.request();
          if (systemAlertStatus != PermissionStatus.granted) {
            print('悬浮窗权限被拒绝，但继续运行');
          }
        }
      } catch (e) {
        print('悬浮窗权限检查失败: $e');
      }

      return true;
    } catch (e) {
      print('权限检查失败: $e');
      return false;
    }
  }

  /// 初始化平台通道
  Future<void> _initializePlatformChannel() async {
    _channel.setMethodCallHandler(_handlePlatformCall);
  }

  /// 处理平台调用
  Future<void> _handlePlatformCall(MethodCall call) async {
    switch (call.method) {
      case 'onNewScreenshot':
        String imagePath = call.arguments['imagePath'];
        await _processNewScreenshot(imagePath);
        break;
      case 'onMonitorError':
        String error = call.arguments['error'];
        print('监听错误: $error');
        _updateStatus(MonitorStatus.error);
        break;
    }
  }

  /// 启动平台监听
  Future<bool> _startPlatformMonitoring() async {
    try {
      final result = await _channel.invokeMethod('startMonitoring');
      return result == true;
    } catch (e) {
      print('启动平台监听失败: $e');
      return false;
    }
  }

  /// 停止平台监听
  Future<void> _stopPlatformMonitoring() async {
    try {
      await _channel.invokeMethod('stopMonitoring');
    } catch (e) {
      print('停止平台监听失败: $e');
    }
  }

  /// 启动定时检查（备用机制）
  void _startPeriodicCheck() {
    _checkTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      try {
        await _checkForNewScreenshots();
      } catch (e) {
        print('定时检查失败: $e');
      }
    });
  }

  /// 检查新截图（备用机制）
  Future<void> _checkForNewScreenshots() async {
    try {
      // 调用平台方法检查截图
      final result = await _channel.invokeMethod('checkNewScreenshots');
      if (result != null && result['hasNew'] == true) {
        String imagePath = result['imagePath'];
        await _processNewScreenshot(imagePath);
      }
    } catch (e) {
      // 静默处理错误
    }
  }

  /// 处理新截图
  Future<void> _processNewScreenshot(String imagePath) async {
    try {
      // 防止重复处理
      if (_lastScreenshotPath == imagePath) {
        return;
      }
      
      // 防止处理过于频繁
      DateTime now = DateTime.now();
      if (_lastProcessTime != null && 
          now.difference(_lastProcessTime!).inSeconds < 2) {
        return;
      }

      _lastScreenshotPath = imagePath;
      _lastProcessTime = now;
      _totalQuestions++;

      print('🎯 检测到新截图: $imagePath');

      // 当前Web版本暂不支持自动截图监控
      print('⚠️ Web版本暂不支持自动截图监控功能');
      await _notification.showError('Web版本暂不支持自动截图监控功能');
      return;

    } catch (e) {
      print('处理截图失败: $e');
      await _notification.showError('处理截图时出错');
    }
  }

  /// 显示答案浮窗
  Future<void> _showAnswerOverlay(Question question, AnswerResult answerResult) async {
    try {
      // 构建详细的答案显示内容
      String answerContent = _formatAnswerForDisplay(question, answerResult);
      
      // 显示系统通知
      await _notification.showAnswer(
        title: '🎯 找到答案！',
        content: answerContent,
        source: answerResult.source.name,
      );

      // 显示浮窗（仅移动平台支持）
      if (!kIsWeb) {
        try {
          await _channel.invokeMethod('showAnswerOverlay', {
            'question': question.content,
            'type': question.typeDescription,
            'answers': answerResult.answers,
            'source': answerResult.source.name,
            'confidence': answerResult.confidence,
          });
        } catch (e) {
          print('移动平台浮窗显示失败: $e');
        }
      }
    } catch (e) {
      print('显示答案浮窗失败: $e');
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

  /// 清理截图文件
  Future<void> _cleanupScreenshot(String imagePath) async {
    // Web平台不需要清理本地文件
    return;
  }

  /// 记录答题结果
  Future<void> recordAnswer(Question question, List<String> userAnswers, bool isCorrect) async {
    try {
      if (isCorrect) {
        // 答对了，更新题库
        question.usageCount++;
        question.lastUsedAt = DateTime.now();
        await _database.updateQuestion(question);
      } else {
        // 答错了，添加到错题库
        await _database.addWrongQuestion(question, userAnswers);
      }
    } catch (e) {
      print('记录答题结果失败: $e');
    }
  }

  /// 更新状态
  void _updateStatus(MonitorStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _statusController.add(_status);
    }
  }

  /// 重置统计数据
  void resetStatistics() {
    _totalQuestions = 0;
    _successfulAnswers = 0;
  }

  /// 获取监听配置
  Map<String, dynamic> getConfiguration() {
    return {
      'autoCleanup': true,
      'notificationEnabled': true,
      'overlayEnabled': !kIsWeb, // 非Web平台支持浮窗
      'processingTimeout': 30,
    };
  }

  /// 更新配置
  Future<void> updateConfiguration(Map<String, dynamic> config) async {
    try {
      await _channel.invokeMethod('updateConfiguration', config);
    } catch (e) {
      print('更新配置失败: $e');
    }
  }

  /// 清理资源
  void dispose() {
    _checkTimer?.cancel();
    _statusController.close();
    _ocrService.dispose();
    _answerService.dispose();
  }
} 