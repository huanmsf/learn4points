import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../services/screenshot_monitor.dart';
import '../utils/app_colors.dart';

class MonitorStatusCard extends StatelessWidget {
  const MonitorStatusCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ScreenshotMonitor>(
      builder: (context, monitor, child) {
        return StreamBuilder<MonitorStatus>(
          stream: monitor.statusStream,
          initialData: monitor.status,
          builder: (context, snapshot) {
            final status = snapshot.data ?? MonitorStatus.stopped;
            return _buildStatusCard(status, monitor.statistics);
          },
        );
      },
    );
  }

  Widget _buildStatusCard(MonitorStatus status, Map<String, int> statistics) {
    final statusInfo = _getStatusInfo(status);
    
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 状态标题
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: statusInfo['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  statusInfo['icon'],
                  color: statusInfo['color'],
                  size: 20.w,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '监听状态',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      statusInfo['text'],
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: statusInfo['color'],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusIndicator(status),
            ],
          ),
          
          SizedBox(height: 20.h),
          
          // 统计信息
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '总题数',
                  statistics['total'].toString(),
                  Icons.quiz_outlined,
                  AppColors.info,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatItem(
                  '成功率',
                  '${statistics['accuracy']}%',
                  Icons.check_circle_outline,
                  AppColors.success,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatItem(
                  '已答',
                  statistics['successful'].toString(),
                  Icons.done_all,
                  AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 获取状态信息
  Map<String, dynamic> _getStatusInfo(MonitorStatus status) {
    switch (status) {
      case MonitorStatus.running:
        return {
          'text': '正在监听中',
          'color': AppColors.success,
          'icon': Icons.visibility,
        };
      case MonitorStatus.starting:
        return {
          'text': '启动中...',
          'color': AppColors.warning,
          'icon': Icons.hourglass_empty,
        };
      case MonitorStatus.error:
        return {
          'text': '监听异常',
          'color': AppColors.error,
          'icon': Icons.error_outline,
        };
      case MonitorStatus.stopped:
      default:
        return {
          'text': '未开始监听',
          'color': AppColors.textSecondary,
          'icon': Icons.visibility_off,
        };
    }
  }

  /// 构建状态指示器
  Widget _buildStatusIndicator(MonitorStatus status) {
    Color color = _getStatusInfo(status)['color'];
    
    return Container(
      width: 12.w,
      height: 12.w,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: status == MonitorStatus.starting
          ? Center(
              child: SizedBox(
                width: 8.w,
                height: 8.w,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          : null,
    );
  }

  /// 构建统计项
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20.w,
          ),
          SizedBox(height: 6.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
} 