import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/question.dart';
import 'models/wrong_question.dart';
import 'services/screenshot_monitor.dart';
import 'services/database_service.dart';
import 'services/ocr_service.dart';
import 'screens/home_screen.dart';
import 'utils/app_theme.dart';
import 'utils/config.dart';
import 'widgets/web_notification_overlay.dart';

// 桌面平台服务导入（条件导入）
// 只有在非web环境且是桌面平台时才导入桌面服务
import 'services/desktop_services_stub.dart'
  if (dart.library.io) 'services/desktop_services_real.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 打印平台信息
  _printPlatformInfo();
  
  // 桌面平台特殊初始化
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    await _initializeDesktopPlatform();
  }
  
  // 初始化Hive数据库
  await Hive.initFlutter();
  
  // 注册Hive适配器
  Hive.registerAdapter(QuestionAdapter());
  Hive.registerAdapter(WrongQuestionAdapter());
  Hive.registerAdapter(QuestionTypeAdapter());
  Hive.registerAdapter(AnswerSourceAdapter());
  
  // 初始化数据库服务
  await DatabaseService().initialize();
  
  // 初始化OCR服务
  await OCRService().initialize();
  
  // 打印配置信息
  AppConfig.printConfig();
  
  // 设置系统UI样式（仅移动端）
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }
  
  runApp(const SmartQuizHelperApp());
}

/// 打印平台信息
void _printPlatformInfo() {
  if (kIsWeb) {
    print('🌐 平台: Web浏览器');
  } else if (Platform.isWindows) {
    print('🖥️ 平台: Windows桌面');
  } else if (Platform.isMacOS) {
    print('🍎 平台: macOS桌面');
  } else if (Platform.isLinux) {
    print('🐧 平台: Linux桌面');
  } else if (Platform.isAndroid) {
    print('📱 平台: Android');
  } else if (Platform.isIOS) {
    print('📱 平台: iOS');
  } else {
    print('❓ 平台: 未知');
  }
}

/// 初始化桌面平台服务
Future<void> _initializeDesktopPlatform() async {
  try {
    print('🛠️ 初始化桌面平台服务...');
    
    // 使用条件导入的桌面服务
    await DesktopServices.initialize();
    
    print('🎉 桌面平台服务初始化完成');
  } catch (e) {
    print('❌ 桌面平台服务初始化失败: $e');
  }
}

class SmartQuizHelperApp extends StatelessWidget {
  const SmartQuizHelperApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            // 截图监听服务
            Provider<ScreenshotMonitor>(
              create: (_) => ScreenshotMonitor(),
              dispose: (_, monitor) => monitor.dispose(),
            ),
            // 数据库服务
            Provider<DatabaseService>(
              create: (_) => DatabaseService(),
            ),
          ],
          child: MaterialApp(
            title: '智能答题助手',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            home: const AppWrapper(),
            // 路由配置
            routes: {
              '/home': (context) => const HomeScreen(),
            },
            // 全局导航观察器
            navigatorObservers: [
              _AppNavigatorObserver(),
            ],
          ),
        );
      },
    );
  }
}

/// 应用包装器，用于初始化Web通知管理器
class AppWrapper extends StatefulWidget {
  const AppWrapper({Key? key}) : super(key: key);

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  @override
  void initState() {
    super.initState();
    _initializePlatformSpecificServices();
  }

  /// 初始化平台特有的服务
  void _initializePlatformSpecificServices() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kIsWeb) {
        // Web平台初始化
        _initializeWebServices();
      } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        // 桌面平台初始化
        _initializeDesktopServices();
      } else {
        // 移动端平台初始化
        _initializeMobileServices();
      }
    });
  }

  /// 初始化Web服务
  void _initializeWebServices() {
    final overlay = Overlay.of(context);
    if (overlay != null) {
      WebNotificationManager.initialize(overlay);
      print('✅ WebNotificationManager 初始化成功');
    } else {
      print('❌ 无法获取Overlay实例');
    }
  }

  /// 初始化桌面服务
  void _initializeDesktopServices() {
    print('🖥️ 桌面平台UI初始化完成');
    // 桌面平台的UI初始化已经在main函数中完成
    // 这里可以添加额外的UI相关初始化
  }

  /// 初始化移动端服务
  void _initializeMobileServices() {
    print('📱 移动端平台UI初始化完成');
    // 移动端特有的UI初始化
  }

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}

/// 导航观察器
class _AppNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    // 记录页面访问
    print('📱 导航到: ${route.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    // 记录页面返回
    print('📱 返回从: ${route.settings.name}');
  }
}

/// Hive适配器生成
// 这些适配器需要通过 build_runner 生成
// 运行命令: flutter packages pub run build_runner build

class QuestionTypeAdapter extends TypeAdapter<QuestionType> {
  @override
  final int typeId = 2;

  @override
  QuestionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return QuestionType.single;
      case 1:
        return QuestionType.multiple;
      case 2:
        return QuestionType.judge;
      default:
        return QuestionType.single;
    }
  }

  @override
  void write(BinaryWriter writer, QuestionType obj) {
    switch (obj) {
      case QuestionType.single:
        writer.writeByte(0);
        break;
      case QuestionType.multiple:
        writer.writeByte(1);
        break;
      case QuestionType.judge:
        writer.writeByte(2);
        break;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}

class AnswerSourceAdapter extends TypeAdapter<AnswerSource> {
  @override
  final int typeId = 3;

  @override
  AnswerSource read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AnswerSource.database;
      case 1:
        return AnswerSource.search;
      case 2:
        return AnswerSource.ai;
      default:
        return AnswerSource.database;
    }
  }

  @override
  void write(BinaryWriter writer, AnswerSource obj) {
    switch (obj) {
      case AnswerSource.database:
        writer.writeByte(0);
        break;
      case AnswerSource.search:
        writer.writeByte(1);
        break;
      case AnswerSource.ai:
        writer.writeByte(2);
        break;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnswerSourceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
} 