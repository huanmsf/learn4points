import 'desktop_screenshot_service.dart';
import 'desktop_window_service.dart';
import 'desktop_hotkey_service.dart';

/// 桌面环境下的真实桌面服务实现
class DesktopServices {
  /// 初始化桌面服务
  static Future<void> initialize() async {
    try {
      // 初始化窗口管理服务
      await DesktopWindowService().initialize();
      print('✅ 桌面窗口服务初始化成功');
      
      // 初始化热键服务
      await DesktopHotkeyService().initialize();
      print('✅ 桌面热键服务初始化成功');
      
      print('🎉 所有桌面服务初始化完成');
    } catch (e) {
      print('❌ 桌面服务初始化过程中出现错误: $e');
      // 即使有错误也继续运行，不要抛出异常
    }
  }
} 