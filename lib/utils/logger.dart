/// 简单的日志工具类
class Logger {
  static bool _debugMode = true;
  
  /// 设置调试模式
  static void setDebugMode(bool enabled) {
    _debugMode = enabled;
  }
  
  /// 输出信息日志
  static void info(String message) {
    if (_debugMode) {
      print('[INFO] ${DateTime.now().toString().substring(0, 19)}: $message');
    }
  }
  
  /// 输出警告日志
  static void warning(String message) {
    if (_debugMode) {
      print('[WARN] ${DateTime.now().toString().substring(0, 19)}: $message');
    }
  }
  
  /// 输出错误日志
  static void error(String message) {
    if (_debugMode) {
      print('[ERROR] ${DateTime.now().toString().substring(0, 19)}: $message');
    }
  }
  
  /// 输出调试日志
  static void debug(String message) {
    if (_debugMode) {
      print('[DEBUG] ${DateTime.now().toString().substring(0, 19)}: $message');
    }
  }
} 