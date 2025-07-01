import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:screen_capturer/screen_capturer.dart';
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
  }

  /// 获取指定区域截图
  Future<Uint8List?> captureRegion({
    required int x,
    required int y,
    required int width,
    required int height,
  }) async {
    try {
      Logger.info('开始区域截图: x=$x, y=$y, width=$width, height=$height');
      
      // 使用临时文件路径
      final directory = await getTemporaryDirectory();
      final imagePath = path.join(directory.path, 'screenshot_${DateTime.now().millisecondsSinceEpoch}.png');
      
      final capturedData = await screenCapturer.capture(
        mode: CaptureMode.region,
        imagePath: imagePath,
      );
      
      if (capturedData == null || capturedData.imagePath == null) {
        Logger.error('区域截图失败：返回null');
        return null;
      }

      final file = File(capturedData.imagePath!);
      final bytes = await file.readAsBytes();
      Logger.info('区域截图成功，大小: ${bytes.length} bytes');
      
      // 删除临时文件
      await file.delete();
      
      return bytes;
    } catch (e) {
      Logger.error('区域截图异常: $e');
      return null;
    }
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
    try {
      Logger.info('开始交互式区域选择截图');
      
      // 隐藏当前窗口
      await windowManager.hide();
      
      // 等待用户选择
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 使用临时文件路径
      final directory = await getTemporaryDirectory();
      final imagePath = path.join(directory.path, 'screenshot_${DateTime.now().millisecondsSinceEpoch}.png');
      
      // 使用框选模式
      final capturedData = await screenCapturer.capture(
        mode: CaptureMode.region,
        imagePath: imagePath,
      );
      
      // 重新显示窗口
      await windowManager.show();
      await windowManager.focus();
      
      if (capturedData == null || capturedData.imagePath == null) {
        Logger.error('用户取消了区域选择');
        return null;
      }

      final file = File(capturedData.imagePath!);
      final bytes = await file.readAsBytes();
      Logger.info('区域选择截图成功，大小: ${bytes.length} bytes');
      
      // 删除临时文件
      await file.delete();
      
      return bytes;
    } catch (e) {
      Logger.error('区域选择截图异常: $e');
      // 确保窗口重新显示
      await windowManager.show();
      await windowManager.focus();
      return null;
    }
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
    try {
      if (Platform.isMacOS) {
        // macOS需要屏幕录制权限
        final hasPermission = await screenCapturer.isAccessAllowed();
        if (!hasPermission) {
          Logger.warning('macOS缺少屏幕录制权限');
          return false;
        }
      }
      return true;
    } catch (e) {
      Logger.error('检查截图权限失败: $e');
      return false;
    }
  }

  /// 请求截图权限
  Future<void> requestPermission() async {
    try {
      if (Platform.isMacOS) {
        await screenCapturer.requestAccess();
      }
    } catch (e) {
      Logger.error('请求截图权限失败: $e');
    }
  }
} 