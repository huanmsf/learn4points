import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../services/screenshot_monitor.dart';
import '../services/database_service.dart';
import '../widgets/monitor_status_card.dart';
import '../widgets/statistics_card.dart';
import '../widgets/quick_actions_card.dart';
import '../screens/wrong_questions_screen.dart';
import '../screens/question_bank_screen.dart';
import '../screens/settings_screen.dart';
import '../utils/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late ScreenshotMonitor _monitor;
  late DatabaseService _database;
  dynamic _webService; // 使用dynamic避免编译时类型检查
  bool _isDragOver = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _monitor = context.read<ScreenshotMonitor>();
    _database = context.read<DatabaseService>();
    
    // 只在Web环境下创建WebScreenshotService（桌面版暂不支持）
    if (kIsWeb) {
      // 注释掉Web服务，桌面版不需要
      // _webService = WebScreenshotService();
      _webService = null;
      _setupDragAndDrop();
    } else {
      _webService = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _webService?.dispose();
    super.dispose();
  }

  /// 设置拖拽和放置功能（仅Web环境）
  void _setupDragAndDrop() {
    if (!kIsWeb) return;
    
    // Web平台的拖拽功能将通过WebScreenshotService处理
    // 这里只是一个占位方法，实际实现在WebScreenshotService中
    print('📱 桌面环境: 拖拽功能不可用');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // 应用生命周期变化处理
    switch (state) {
      case AppLifecycleState.resumed:
        // 应用回到前台
        print('📱 应用回到前台');
        break;
      case AppLifecycleState.paused:
        // 应用进入后台
        print('📱 应用进入后台');
        break;
      case AppLifecycleState.detached:
        // 应用即将关闭
        _monitor.stopMonitoring();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 欢迎区域
                  _buildWelcomeSection(),
                  
                  SizedBox(height: 24.h),
                  
                  // Web环境特殊功能
                  if (kIsWeb) _buildWebUploadSection(),
                  
                  if (kIsWeb) SizedBox(height: 16.h),
                  
                  // 监听状态卡片
                  if (!kIsWeb) const MonitorStatusCard(),
                  
                  if (!kIsWeb) SizedBox(height: 16.h),
                  
                  // 统计信息卡片
                  const StatisticsCard(),
                  
                  SizedBox(height: 16.h),
                  
                  // 快捷操作卡片
                  const QuickActionsCard(),
                  
                  SizedBox(height: 24.h),
                  
                  // 功能菜单
                  _buildFunctionMenu(),
                  
                  SizedBox(height: 24.h),
                  
                  // 使用说明
                  _buildUsageInstructions(),
                  
                  SizedBox(height: 100.h), // 底部安全区域
                ],
              ),
            ),
          ),
          
          // 拖拽覆盖层（仅Web环境）
          if (kIsWeb && _isDragOver) _buildDragOverlay(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  /// 构建应用栏
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.psychology,
              color: AppColors.primary,
              size: 24.w,
            ),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '智能答题助手',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '让答题变得更简单',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => _navigateToSettings(),
          icon: Icon(
            Icons.settings_outlined,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// 构建欢迎区域
  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppColors.primary,
                size: 24.w,
              ),
              SizedBox(width: 8.w),
              Text(
                '使用提示',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            kIsWeb ? 
            '1. 点击"上传图片"按钮选择题目图片\n'
            '2. 或直接拖拽图片到页面进行识别\n'
            '3. 系统会自动识别题目并查找答案\n'
            '4. 查看答案提示后可保存到题库' :
            '1. 点击"开始监听"按钮启动截图监听\n'
            '2. 在答题app中截图，系统会自动识别题目\n'
            '3. 查看通知栏或浮窗获取答案提示\n'
            '4. 答题结束后可以查看错题库复习',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建Web上传区域
  Widget _buildWebUploadSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cloud_upload,
            color: AppColors.primary,
            size: 48.w,
          ),
          SizedBox(height: 16.h),
          Text(
            '上传题目图片',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '点击上传按钮选择图片，或直接拖拽图片到此区域',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: (_webService?.isProcessing ?? false) ? null : () => _webService?.selectAndProcessImage(),
                icon: Icon(Icons.file_upload),
                label: Text('选择图片'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                ),
              ),
              if (_webService?.isProcessing ?? false)
                Row(
                  children: [
                    SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '处理中...',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建拖拽覆盖层
  Widget _buildDragOverlay() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.primary.withOpacity(0.1),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(40.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.file_upload,
                color: AppColors.primary,
                size: 64.w,
              ),
              SizedBox(height: 16.h),
              Text(
                '释放以上传图片',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '支持 PNG、JPG、JPEG 格式',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建功能菜单
  Widget _buildFunctionMenu() {
    final menuItems = [
      {
        'title': '题库管理',
        'subtitle': '查看和管理本地题库',
        'icon': Icons.quiz_outlined,
        'color': Colors.blue,
        'onTap': () => _navigateToQuestionBank(),
      },
      {
        'title': '错题库',
        'subtitle': '查看错题并进行练习',
        'icon': Icons.error_outline,
        'color': Colors.red,
        'onTap': () => _navigateToWrongQuestions(),
      },
      {
        'title': '学习记录',
        'subtitle': '查看答题历史和统计',
        'icon': Icons.history,
        'color': Colors.green,
        'onTap': () => _navigateToHistory(),
      },
      {
        'title': '设置',
        'subtitle': '个性化设置和配置',
        'icon': Icons.settings_outlined,
        'color': Colors.purple,
        'onTap': () => _navigateToSettings(),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '功能菜单',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        ...menuItems.map((item) => _buildMenuItem(item)),
      ],
    );
  }

  /// 构建菜单项
  Widget _buildMenuItem(Map<String, dynamic> item) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: item['onTap'],
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    item['icon'],
                    color: item['color'],
                    size: 24.w,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'],
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        item['subtitle'],
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textSecondary,
                  size: 16.w,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建使用说明
  Widget _buildUsageInstructions() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                color: AppColors.primary,
                size: 20.w,
              ),
              SizedBox(width: 8.w),
              Text(
                '使用说明',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (!kIsWeb) _buildInstructionItem(
            '权限设置',
            '首次使用需要授予存储和通知权限',
            Icons.security,
          ),
          if (kIsWeb) _buildInstructionItem(
            '图片上传',
            '支持拖拽上传和文件选择两种方式',
            Icons.file_upload,
          ),
          _buildInstructionItem(
            '答案来源',
            '题库 > 网络搜索 > AI辅助，多重保障',
            Icons.search,
          ),
          _buildInstructionItem(
            '错题管理',
            '自动记录错题，支持重复练习',
            Icons.repeat,
          ),
          if (kIsWeb) _buildInstructionItem(
            'Web限制',
            'Web版本功能有限，建议使用移动端',
            Icons.warning_outlined,
          ),
          _buildInstructionItem(
            '数据安全',
            '所有数据本地存储，保护隐私',
            Icons.lock_outline,
          ),
        ],
      ),
    );
  }

  /// 构建说明项
  Widget _buildInstructionItem(String title, String content, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 16.w,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建悬浮按钮
  Widget _buildFloatingActionButton() {
    if (kIsWeb) {
      // Web环境显示上传按钮
      return FloatingActionButton.extended(
        onPressed: (_webService?.isProcessing ?? false) ? null : () => _webService?.selectAndProcessImage(),
        backgroundColor: (_webService?.isProcessing ?? false) ? Colors.grey : AppColors.primary,
        icon: Icon(
          (_webService?.isProcessing ?? false) ? Icons.hourglass_empty : Icons.file_upload,
          color: Colors.white,
        ),
        label: Text(
          (_webService?.isProcessing ?? false) ? '处理中...' : '上传图片',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      // 移动端显示监听按钮
      return StreamBuilder<MonitorStatus>(
        stream: _monitor.statusStream,
        initialData: _monitor.status,
        builder: (context, snapshot) {
          final status = snapshot.data ?? MonitorStatus.stopped;
          final isRunning = status == MonitorStatus.running;
          
          return FloatingActionButton.extended(
            onPressed: () => _toggleMonitoring(),
            backgroundColor: isRunning ? Colors.red : AppColors.primary,
            icon: Icon(
              isRunning ? Icons.stop : Icons.play_arrow,
              color: Colors.white,
            ),
            label: Text(
              isRunning ? '停止监听' : '开始监听',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      );
    }
  }

  /// 切换监听状态
  Future<void> _toggleMonitoring() async {
    if (_monitor.status == MonitorStatus.running) {
      await _monitor.stopMonitoring();
      _showSnackBar('已停止监听');
    } else {
      final success = await _monitor.startMonitoring();
      if (success) {
        _showSnackBar('开始监听截图...');
      } else {
        _showSnackBar('启动监听失败，请检查权限');
      }
    }
  }

  /// 刷新数据
  Future<void> _refreshData() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {});
  }

  /// 导航到错题库
  void _navigateToWrongQuestions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WrongQuestionsScreen(),
      ),
    );
  }

  /// 导航到题库管理
  void _navigateToQuestionBank() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QuestionBankScreen(),
      ),
    );
  }

  /// 导航到学习记录
  void _navigateToHistory() {
    // TODO: 实现学习记录页面
    _showSnackBar('学习记录功能开发中...');
  }

  /// 导航到设置
  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  /// 显示提示消息
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
} 