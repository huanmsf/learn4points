import 'package:flutter/material.dart';
import 'dart:async';

/// Web专用通知覆盖层
class WebNotificationOverlay extends StatefulWidget {
  final String title;
  final String content;
  final VoidCallback? onDismiss;
  final Duration duration;

  const WebNotificationOverlay({
    Key? key,
    required this.title,
    required this.content,
    this.onDismiss,
    this.duration = const Duration(seconds: 8),
  }) : super(key: key);

  @override
  State<WebNotificationOverlay> createState() => _WebNotificationOverlayState();
}

class _WebNotificationOverlayState extends State<WebNotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // 开始动画
    _animationController.forward();

    // 设置自动消失定时器
    _dismissTimer = Timer(widget.duration, () {
      _dismiss();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (mounted) {
      _animationController.reverse().then((_) {
        widget.onDismiss?.call();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      right: 20,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 左侧彩色条
                  Container(
                    width: 4,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5CE7),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // 内容区域
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 标题
                        Row(
                          children: [
                            const Icon(
                              Icons.lightbulb,
                              color: Color(0xFF6C5CE7),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // 内容
                        Text(
                          widget.content,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 关闭按钮
                  IconButton(
                    onPressed: _dismiss,
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFF999999),
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 全局通知管理器
class WebNotificationManager {
  static final WebNotificationManager _instance = WebNotificationManager._internal();
  factory WebNotificationManager() => _instance;
  WebNotificationManager._internal();

  OverlayEntry? _currentOverlay;
  static OverlayState? _overlayState;

  /// 初始化（在main中调用）
  static void initialize(OverlayState overlayState) {
    _overlayState = overlayState;
  }

  /// 显示通知
  void showNotification({
    required String title,
    required String content,
    Duration duration = const Duration(seconds: 8),
  }) {
    if (_overlayState == null) {
      print('WebNotificationManager未初始化');
      return;
    }

    // 如果已有通知，先移除
    hideNotification();

    _currentOverlay = OverlayEntry(
      builder: (context) => WebNotificationOverlay(
        title: title,
        content: content,
        duration: duration,
        onDismiss: hideNotification,
      ),
    );

    _overlayState!.insert(_currentOverlay!);
  }

  /// 隐藏通知
  void hideNotification() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
} 