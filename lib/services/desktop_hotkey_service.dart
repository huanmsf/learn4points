import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import '../utils/logger.dart';

/// 桌面热键管理服务
class DesktopHotkeyService {
  static final DesktopHotkeyService _instance = DesktopHotkeyService._internal();
  factory DesktopHotkeyService() => _instance;
  DesktopHotkeyService._internal();

  final Map<String, HotKey> _registeredHotkeys = {};
  bool _isInitialized = false;

  /// 初始化热键服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      Logger.info('初始化桌面热键服务');
      
      // 注册默认热键
      await _registerDefaultHotkeys();
      
      _isInitialized = true;
      Logger.info('桌面热键服务初始化成功');
    } catch (e) {
      Logger.error('初始化桌面热键服务失败: $e');
    }
  }

  /// 注册默认热键
  Future<void> _registerDefaultHotkeys() async {
    // 快速截图：Ctrl + Shift + S
    await registerHotkey(
      'quick_screenshot',
      HotKey(
        key: LogicalKeyboardKey.keyS,
        modifiers: [HotKeyModifier.control, HotKeyModifier.shift],
        scope: HotKeyScope.system,
      ),
      onQuickScreenshot,
    );

    // 区域截图：Ctrl + Shift + A
    await registerHotkey(
      'region_screenshot',
      HotKey(
        key: LogicalKeyboardKey.keyA,
        modifiers: [HotKeyModifier.control, HotKeyModifier.shift],
        scope: HotKeyScope.system,
      ),
      onRegionScreenshot,
    );

    // 显示/隐藏窗口：Ctrl + Shift + Q
    await registerHotkey(
      'toggle_window',
      HotKey(
        key: LogicalKeyboardKey.keyQ,
        modifiers: [HotKeyModifier.control, HotKeyModifier.shift],
        scope: HotKeyScope.system,
      ),
      onToggleWindow,
    );

    // 开始/停止自动答题：Ctrl + Shift + R
    await registerHotkey(
      'toggle_auto_answer',
      HotKey(
        key: LogicalKeyboardKey.keyR,
        modifiers: [HotKeyModifier.control, HotKeyModifier.shift],
        scope: HotKeyScope.system,
      ),
      onToggleAutoAnswer,
    );

    // 暂停/恢复：Ctrl + Shift + P
    await registerHotkey(
      'pause_resume',
      HotKey(
        key: LogicalKeyboardKey.keyP,
        modifiers: [HotKeyModifier.control, HotKeyModifier.shift],
        scope: HotKeyScope.system,
      ),
      onPauseResume,
    );
  }

  /// 注册热键
  Future<bool> registerHotkey(
    String id,
    HotKey hotkey,
    VoidCallback callback,
  ) async {
    try {
      // 如果已经注册，先注销
      if (_registeredHotkeys.containsKey(id)) {
        await unregisterHotkey(id);
      }

      // 注册新热键
      await hotKeyManager.register(
        hotkey,
        keyDownHandler: (hotkey) {
          Logger.info('热键触发: $id');
          callback();
        },
      );

      _registeredHotkeys[id] = hotkey;
      Logger.info('热键注册成功: $id');
      return true;
    } catch (e) {
      Logger.error('注册热键失败 ($id): $e');
      return false;
    }
  }

  /// 注销热键
  Future<bool> unregisterHotkey(String id) async {
    try {
      final hotkey = _registeredHotkeys[id];
      if (hotkey != null) {
        await hotKeyManager.unregister(hotkey);
        _registeredHotkeys.remove(id);
        Logger.info('热键注销成功: $id');
        return true;
      }
      return false;
    } catch (e) {
      Logger.error('注销热键失败 ($id): $e');
      return false;
    }
  }

  /// 重新注册所有热键
  Future<void> reregisterAll() async {
    try {
      Logger.info('重新注册所有热键');
      
      // 注销所有现有热键
      await unregisterAll();
      
      // 重新注册默认热键
      await _registerDefaultHotkeys();
      
      Logger.info('所有热键重新注册完成');
    } catch (e) {
      Logger.error('重新注册热键失败: $e');
    }
  }

  /// 注销所有热键
  Future<void> unregisterAll() async {
    try {
      final ids = List<String>.from(_registeredHotkeys.keys);
      for (final id in ids) {
        await unregisterHotkey(id);
      }
      Logger.info('所有热键已注销');
    } catch (e) {
      Logger.error('注销所有热键失败: $e');
    }
  }

  /// 获取已注册的热键列表
  Map<String, HotKey> getRegisteredHotkeys() {
    return Map.from(_registeredHotkeys);
  }

  /// 检查热键是否已注册
  bool isHotkeyRegistered(String id) {
    return _registeredHotkeys.containsKey(id);
  }

  // 热键回调函数

  /// 快速截图回调
  void onQuickScreenshot() {
    Logger.info('热键触发：快速截图');
    // TODO: 调用截图服务
    _notifyHotkeyTriggered('quick_screenshot');
  }

  /// 区域截图回调
  void onRegionScreenshot() {
    Logger.info('热键触发：区域截图');
    // TODO: 调用区域截图服务
    _notifyHotkeyTriggered('region_screenshot');
  }

  /// 显示/隐藏窗口回调
  void onToggleWindow() {
    Logger.info('热键触发：切换窗口显示');
    // TODO: 调用窗口服务
    _notifyHotkeyTriggered('toggle_window');
  }

  /// 开始/停止自动答题回调
  void onToggleAutoAnswer() {
    Logger.info('热键触发：切换自动答题');
    // TODO: 调用自动答题服务
    _notifyHotkeyTriggered('toggle_auto_answer');
  }

  /// 暂停/恢复回调
  void onPauseResume() {
    Logger.info('热键触发：暂停/恢复');
    // TODO: 调用暂停/恢复功能
    _notifyHotkeyTriggered('pause_resume');
  }

  /// 通知热键被触发（供其他组件监听）
  void _notifyHotkeyTriggered(String hotkeyId) {
    // TODO: 实现事件通知机制
  }

  /// 自定义热键配置
  Future<bool> setCustomHotkey(
    String id,
    LogicalKeyboardKey key,
    List<HotKeyModifier> modifiers,
    VoidCallback callback,
  ) async {
    final hotkey = HotKey(
      key: key,
      modifiers: modifiers,
      scope: HotKeyScope.system,
    );

    return await registerHotkey(id, hotkey, callback);
  }

  /// 清理资源
  Future<void> dispose() async {
    if (_isInitialized) {
      await unregisterAll();
      _isInitialized = false;
      Logger.info('桌面热键服务已清理');
    }
  }
} 