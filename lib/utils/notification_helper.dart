import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import '../widgets/web_notification_overlay.dart';

class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;
  NotificationHelper._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// 初始化通知
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Web平台不支持本地通知，直接返回
    if (kIsWeb) {
      _isInitialized = true;
      print('✅ Web平台通知服务初始化成功（使用页面覆盖层通知）');
      return;
    }

    // Android初始化设置
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS初始化设置
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 请求通知权限
    await _requestPermissions();
    
    _isInitialized = true;
    print('✅ 通知服务初始化成功');
  }

  /// 请求通知权限
  Future<void> _requestPermissions() async {
    if (kIsWeb) {
      // Web平台使用浏览器通知权限
      return;
    }
    
    // 对于移动平台，使用flutter_local_notifications的权限请求
    try {
      await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } catch (e) {
      print('⚠️ 通知权限请求失败: $e');
    }
  }

  /// 通知点击回调
  void _onNotificationTapped(NotificationResponse response) {
    print('通知被点击: ${response.payload}');
    // 这里可以添加导航逻辑
  }

  /// 显示监听开始通知
  Future<void> showMonitoringStarted() async {
    await _ensureInitialized();
    
    if (kIsWeb) {
      _showWebNotification('智能答题助手', '正在监听截图，准备为您提供答案...');
      return;
    }
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'monitoring_channel',
      '监听状态',
      channelDescription: '截图监听状态通知',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF6C5CE7),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      1001,
      '智能答题助手',
      '正在监听截图，准备为您提供答案...',
      details,
      payload: 'monitoring_started',
    );
  }

  /// 显示监听停止通知
  Future<void> showMonitoringStopped() async {
    await _ensureInitialized();
    
    if (kIsWeb) {
      _showWebNotification('智能答题助手', '已停止监听截图');
      return;
    }
    
    // 取消监听状态通知
    await _notifications.cancel(1001);
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'status_channel',
      '状态通知',
      channelDescription: '应用状态变化通知',
      importance: Importance.low,
      priority: Priority.low,
      autoCancel: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      1002,
      '智能答题助手',
      '已停止监听截图',
      details,
      payload: 'monitoring_stopped',
    );
  }

  /// 显示答案通知
  Future<void> showAnswer({
    required String title,
    required String content,
    required String source,
  }) async {
    await _ensureInitialized();
    
    if (kIsWeb) {
      String fullContent = '$content\n\n来源: $source';
      _showWebNotification(title, fullContent);
      return;
    }
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'answer_channel',
      '答案通知',
      channelDescription: '题目答案提醒',
      importance: Importance.high,
      priority: Priority.high,
      autoCancel: true,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF00B894),
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        '',
        contentTitle: '',
        summaryText: '',
      ),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // 生成唯一ID
    int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _notifications.show(
      notificationId,
      title,
      '$content\n来源: $source',
      details,
      payload: 'answer_found',
    );
  }

  /// 显示错误通知
  Future<void> showError(String message) async {
    await _ensureInitialized();
    
    if (kIsWeb) {
      _showWebNotification('错误', message);
      return;
    }
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'error_channel',
      '错误通知',
      channelDescription: '错误和警告信息',
      importance: Importance.high,
      priority: Priority.high,
      autoCancel: true,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFE17055),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      9999,
      '错误',
      message,
      details,
      payload: 'error',
    );
  }

  /// Web平台显示通知 - 简化版本
  void _showWebNotification(String title, String body) {
    try {
      // 在控制台显示消息（保留用于调试）
      print('');
      print('🔔 ========================');
      print('📢 $title');
      print('📝 $body');
      print('🔔 ========================');
      print('');
      
      // 使用Flutter覆盖层通知
      WebNotificationManager().showNotification(
        title: title,
        content: body,
        duration: const Duration(seconds: 10),
      );
      
    } catch (e) {
      print('Web通知显示失败: $e');
    }
  }

  /// 显示题目识别通知
  Future<void> showQuestionDetected(String questionType, String questionContent) async {
    await _ensureInitialized();
    
    String shortContent = questionContent.length > 50 
        ? '${questionContent.substring(0, 50)}...'
        : questionContent;
    
    if (kIsWeb) {
      _showWebNotification('识别到$questionType', shortContent);
      return;
    }
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'detection_channel',
      '题目识别',
      channelDescription: '题目识别结果通知',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      autoCancel: true,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF74B9FF),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _notifications.show(
      notificationId,
      '识别到$questionType',
      shortContent,
      details,
      payload: 'question_detected',
    );
  }

  /// 显示进度通知
  Future<void> showProgress({
    required String title,
    required String content,
    required int progress,
    required int maxProgress,
  }) async {
    await _ensureInitialized();
    
    if (kIsWeb) {
      _showWebNotification(title, '$content ($progress/$maxProgress)');
      return;
    }
    
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'progress_channel',
      '处理进度',
      channelDescription: '题目处理进度',
      importance: Importance.low,
      priority: Priority.low,
      autoCancel: false,
      ongoing: true,
      showProgress: true,
      maxProgress: maxProgress,
      progress: progress,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      2001,
      title,
      content,
      details,
      payload: 'progress_update',
    );
  }

  /// 取消进度通知
  Future<void> cancelProgress() async {
    if (kIsWeb) {
      print('Web平台：取消进度通知');
      return;
    }
    
    await _notifications.cancel(2001);
  }

  /// 显示定时提醒
  Future<void> scheduleReminder({
    required DateTime scheduledTime,
    required String title,
    required String body,
  }) async {
    // Web版本暂不支持定时通知
    print('定时提醒功能在Web版本中暂不可用');
    return;
    
    // TODO: 在移动端版本中实现定时通知
    /*
    await _ensureInitialized();
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      '定时提醒',
      channelDescription: '学习提醒和复习通知',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    int notificationId = scheduledTime.millisecondsSinceEpoch ~/ 1000;

    await _notifications.zonedSchedule(
      notificationId,
      title,
      body,
      scheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
    */
  }

  /// 取消所有通知
  Future<void> cancelAll() async {
    if (kIsWeb) {
      print('Web平台：取消所有通知');
      return;
    }
    
    await _notifications.cancelAll();
  }

  /// 取消特定通知
  Future<void> cancel(int id) async {
    if (kIsWeb) {
      print('Web平台：取消通知 $id');
      return;
    }
    
    await _notifications.cancel(id);
  }

  /// 获取待处理的通知
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (kIsWeb) {
      return [];
    }
    
    return await _notifications.pendingNotificationRequests();
  }

  /// 确保初始化
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// 清理资源
  void dispose() {
    // Flutter Local Notifications 不需要手动清理
  }

  /// 显示答题统计通知
  Future<void> showStatistics({
    required int totalQuestions,
    required int correctAnswers,
    required double accuracy,
  }) async {
    await _ensureInitialized();
    
    final content = '总题数: $totalQuestions | 正确: $correctAnswers | 准确率: ${(accuracy * 100).toStringAsFixed(1)}%';
    
    if (kIsWeb) {
      _showWebNotification('答题统计', content);
      return;
    }
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'stats_channel',
      '统计通知',
      channelDescription: '答题统计信息',
      importance: Importance.low,
      priority: Priority.low,
      autoCancel: true,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF74B9FF),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      2001,
      '答题统计',
      content,
      details,
      payload: 'statistics',
    );
  }

  /// 显示每日提醒
  Future<void> showDailyReminder() async {
    await _ensureInitialized();
    
    if (kIsWeb) {
      _showWebNotification('每日提醒', '别忘了复习错题哦！');
      return;
    }
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      '提醒通知',
      channelDescription: '学习提醒',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      autoCancel: true,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFFFB8B8),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      3001,
      '每日提醒',
      '别忘了复习错题哦！',
      details,
      payload: 'daily_reminder',
    );
  }
} 