import 'dart:async';

/// WebScreenshotService的存根版本（非Web平台）
class WebScreenshotService {
  static final WebScreenshotService _instance = WebScreenshotService._internal();
  factory WebScreenshotService() => _instance;
  WebScreenshotService._internal();

  /// 是否正在处理（存根版本始终返回false）
  bool get isProcessing => false;
  
  /// 处理状态流（存根版本）
  Stream<bool> get processingStream => Stream.value(false);

  /// 初始化服务（存根版本）
  void initialize() {
    print('⚠️ WebScreenshotService存根版本，仅Web平台可用');
  }

  /// 选择并处理图片（存根版本）
  Future<void> selectAndProcessImage() async {
    print('⚠️ 此功能仅在Web平台可用');
  }

  /// 处理拖拽的文件（存根版本）
  Future<void> handleDroppedFiles(dynamic files) async {
    print('⚠️ 此功能仅在Web平台可用');
  }

  /// 获取使用统计（存根版本）
  Map<String, dynamic> getStatistics() {
    return {
      'supportedFormats': [],
      'maxFileSize': '0MB',
      'features': ['存根版本 - 仅Web平台可用'],
    };
  }

  /// 清理资源（存根版本）
  void dispose() {
    // 存根版本无需清理
  }
} 