import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
// import 'package:system_tray/system_tray.dart'; // 暂时注释
import '../utils/logger.dart';

/// 桌面平台窗口管理服务
class DesktopWindowService with WindowListener {
  static final DesktopWindowService _instance = DesktopWindowService._internal();
  factory DesktopWindowService() => _instance;
  DesktopWindowService._internal();

  // final SystemTray _systemTray = SystemTray(); // 暂时注释
  bool _isInitialized = false;
  bool _isMinimizedToTray = false;

  /// 初始化桌面窗口服务
  Future<void> initialize() async {
    if (_isInitialized) {
      Logger.warning('桌面窗口服务已经初始化');
      return;
    }

    try {
      await _initializeWindow();
      await _initializeSystemTray();
      _isInitialized = true;
      Logger.info('桌面窗口服务初始化成功');
    } catch (e) {
      Logger.error('桌面窗口服务初始化失败: $e');
      // 不要rethrow，让应用继续运行
    }
  }

  /// 初始化窗口配置
  Future<void> _initializeWindow() async {
    // 确保WindowManager已初始化
    await windowManager.ensureInitialized();

    // 添加窗口监听器
    windowManager.addListener(this);

    // 设置窗口选项
    const windowOptions = WindowOptions(
      size: Size(1200, 800),
      minimumSize: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      windowButtonVisibility: true,
      alwaysOnTop: false,
    );

    await windowManager.waitUntilReadyToShow(windowOptions);
    await windowManager.show();
    await windowManager.focus();
  }

  /// 初始化系统托盘
  Future<void> _initializeSystemTray() async {
    // 暂时禁用系统托盘功能
    Logger.warning('系统托盘功能暂时不可用');
    return;
    
    /* 原实现暂时注释
    try {
      // 简化的系统托盘初始化
      String iconPath = await _getTrayIconPath();
      
      // 基础托盘初始化
      await _systemTray.initSystemTray(
        title: "智能答题助手",
        iconPath: iconPath,
      );

      // 设置简单的托盘点击事件
      _systemTray.registerSystemTrayEventHandler((eventName) {
        Logger.info('系统托盘事件: $eventName');
        // 简单的点击切换窗口显示
        toggleWindow();
      });

      Logger.info('系统托盘初始化成功');
    } catch (e) {
      Logger.warning('系统托盘初始化失败，将跳过托盘功能: $e');
      // 托盘初始化失败不影响主要功能
    }
    */
  }

  /// 获取托盘图标路径
  Future<String> _getTrayIconPath() async {
    if (Platform.isWindows) {
      return 'assets/icons/tray_icon.ico';
    } else if (Platform.isMacOS) {
      return 'assets/icons/tray_icon.png';
    } else {
      return 'assets/icons/tray_icon.png';
    }
  }

  /// 显示窗口
  Future<void> showWindow() async {
    try {
      await windowManager.show();
      await windowManager.focus();
      _isMinimizedToTray = false;
      Logger.info('窗口已显示');
    } catch (e) {
      Logger.error('显示窗口失败: $e');
    }
  }

  /// 隐藏窗口
  Future<void> hideWindow() async {
    try {
      await windowManager.hide();
      _isMinimizedToTray = true;
      Logger.info('窗口已隐藏到托盘');
    } catch (e) {
      Logger.error('隐藏窗口失败: $e');
    }
  }

  /// 切换窗口显示状态
  Future<void> toggleWindow() async {
    try {
      final isVisible = await windowManager.isVisible();
      if (isVisible) {
        await hideWindow();
      } else {
        await showWindow();
      }
    } catch (e) {
      Logger.error('切换窗口状态失败: $e');
    }
  }

  /// 最小化到托盘
  Future<void> minimizeToTray() async {
    await hideWindow();
  }

  /// 设置窗口置顶
  Future<void> setAlwaysOnTop(bool alwaysOnTop) async {
    try {
      await windowManager.setAlwaysOnTop(alwaysOnTop);
      Logger.info('窗口置顶状态: $alwaysOnTop');
    } catch (e) {
      Logger.error('设置窗口置顶失败: $e');
    }
  }

  /// 设置窗口透明度
  Future<void> setOpacity(double opacity) async {
    try {
      await windowManager.setOpacity(opacity.clamp(0.0, 1.0));
      Logger.info('窗口透明度: $opacity');
    } catch (e) {
      Logger.error('设置窗口透明度失败: $e');
    }
  }

  /// 快速截图
  Future<void> quickScreenshot() async {
    Logger.info('系统托盘触发快速截图');
    // TODO: 调用截图服务
  }

  /// 区域截图
  Future<void> regionScreenshot() async {
    Logger.info('系统托盘触发区域截图');
    // TODO: 调用区域截图服务
  }

  /// 打开设置
  Future<void> openSettings() async {
    await showWindow();
    Logger.info('打开设置页面');
    // TODO: 导航到设置页面
  }

  /// 显示关于信息
  Future<void> showAbout() async {
    await showWindow();
    Logger.info('显示关于信息');
    // TODO: 显示关于对话框
  }

  /// 退出应用
  Future<void> exitApp() async {
    Logger.info('退出应用');
    await windowManager.destroy();
    exit(0);
  }

  /// 窗口监听器 - 窗口关闭事件
  @override
  void onWindowClose() {
    // 关闭窗口时最小化到托盘而不是退出
    minimizeToTray();
  }

  /// 窗口监听器 - 窗口最小化事件
  @override
  void onWindowMinimize() {
    minimizeToTray();
  }

  /// 清理资源
  Future<void> dispose() async {
    if (_isInitialized) {
      windowManager.removeListener(this);
      try {
        // 简化的托盘清理，避免调用不存在的方法
        // SystemTray清理在应用退出时自动进行
      } catch (e) {
        Logger.warning('清理系统托盘时出错: $e');
      }
      _isInitialized = false;
      Logger.info('桌面窗口服务已清理');
    }
  }
} 