/// Web环境下的桌面服务空实现
/// 在Web环境中，桌面服务不可用
class DesktopServices {
  /// 初始化桌面服务（Web环境空实现）
  static Future<void> initialize() async {
    print('ℹ️ Web环境: 桌面服务不可用');
    // Web环境下不需要初始化任何桌面服务
  }
} 