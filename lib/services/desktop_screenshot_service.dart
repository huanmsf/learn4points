import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
// import 'package:screen_capturer/screen_capturer.dart'; // 暂时注释，需要ATL库
import 'package:window_manager/window_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../utils/logger.dart';

/// 桌面平台专用屏幕截图服务
class DesktopScreenshotService {
  static final DesktopScreenshotService _instance = DesktopScreenshotService._internal();
  factory DesktopScreenshotService() => _instance;
  DesktopScreenshotService._internal();

  /// 获取全屏截图
  Future<Uint8List?> captureFullScreen() async {
    // 暂时禁用，因为screen_capturer包需要ATL库
    Logger.warning('全屏截图功能暂时不可用，需要安装ATL库');
    return null;
    
    /* 原实现暂时注释
    try {
      Logger.info('开始全屏截图');
      
      // 使用临时文件路径
      final directory = await getTemporaryDirectory();
      final imagePath = path.join(directory.path, 'screenshot_${DateTime.now().millisecondsSinceEpoch}.png');
      
      final capturedData = await screenCapturer.capture(
        mode: CaptureMode.screen,
        imagePath: imagePath,
      );
      
      if (capturedData == null || capturedData.imagePath == null) {
        Logger.error('全屏截图失败：返回null');
        return null;
      }

      final file = File(capturedData.imagePath!);
      final bytes = await file.readAsBytes();
      Logger.info('全屏截图成功，大小: ${bytes.length} bytes');
      
      // 删除临时文件
      await file.delete();
      
      return bytes;
    } catch (e) {
      Logger.error('全屏截图异常: $e');
      return null;
    }
    */
  }

  /// 获取指定区域截图
  Future<Uint8List?> captureRegion({
    required int x,
    required int y,
    required int width,
    required int height,
  }) async {
    // 暂时禁用，因为screen_capturer包需要ATL库
    Logger.warning('区域截图功能暂时不可用，需要安装ATL库');
    return null;
  }

  /// 保存截图到文件
  Future<String?> saveScreenshot(Uint8List imageBytes) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final screenshotDir = Directory(path.join(directory.path, 'screenshots'));
      
      if (!await screenshotDir.exists()) {
        await screenshotDir.create(recursive: true);
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'screenshot_$timestamp.png';
      final filePath = path.join(screenshotDir.path, fileName);
      
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);
      
      Logger.info('截图已保存到: $filePath');
      return filePath;
    } catch (e) {
      Logger.error('保存截图失败: $e');
      return null;
    }
  }

  /// 开始区域选择截图（交互式）
  Future<Uint8List?> startRegionSelection() async {
    // 暂时禁用，因为screen_capturer包需要ATL库
    Logger.warning('区域选择截图功能暂时不可用，需要安装ATL库');
    return null;
  }

  /// 定时截图
  Future<void> startPeriodicCapture({
    required Duration interval,
    required Function(Uint8List) onCapture,
  }) async {
    Logger.info('开始定时截图，间隔: ${interval.inSeconds}秒');
    
    Timer.periodic(interval, (timer) async {
      final screenshot = await captureFullScreen();
      if (screenshot != null) {
        onCapture(screenshot);
      }
    });
  }

  /// 检查截图权限
  Future<bool> checkPermission() async {
    // 暂时禁用，因为screen_capturer包需要ATL库
    Logger.warning('截图权限检查暂时不可用，需要安装ATL库');
    return false;
  }

  /// 请求截图权限
  Future<void> requestPermission() async {
    // 暂时禁用，因为screen_capturer包需要ATL库
    Logger.warning('截图权限请求暂时不可用，需要安装ATL库');
  }
} 