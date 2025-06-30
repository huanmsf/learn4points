import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../utils/app_colors.dart';

class StatisticsCard extends StatefulWidget {
  const StatisticsCard({Key? key}) : super(key: key);

  @override
  State<StatisticsCard> createState() => _StatisticsCardState();
}

class _StatisticsCardState extends State<StatisticsCard> {
  Map<String, int> _statistics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final database = context.read<DatabaseService>();
    final stats = await database.getStatistics();
    
    if (mounted) {
      setState(() {
        _statistics = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          // 标题
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: AppColors.primary,
                size: 24.w,
              ),
              SizedBox(width: 8.w),
              Text(
                '学习统计',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _loadStatistics,
                child: Icon(
                  Icons.refresh,
                  color: AppColors.textSecondary,
                  size: 20.w,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 20.h),
          
          // 统计内容
          if (_isLoading)
            _buildLoadingState()
          else
            _buildStatisticsContent(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildStatisticsContent() {
    return Column(
      children: [
        // 主要统计数据
        Row(
          children: [
            Expanded(
              child: _buildMainStatItem(
                '题库容量',
                _statistics['totalQuestions']?.toString() ?? '0',
                Icons.library_books,
                AppColors.primary,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: _buildMainStatItem(
                '错题数量',
                _statistics['totalWrongQuestions']?.toString() ?? '0',
                Icons.error_outline,
                AppColors.error,
              ),
            ),
          ],
        ),
        
        SizedBox(height: 16.h),
        
        // 正确率展示
        _buildAccuracySection(),
        
        SizedBox(height: 16.h),
        
        // 详细统计
        _buildDetailedStats(),
      ],
    );
  }

  Widget _buildMainStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20.w,
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracySection() {
    final accuracy = _statistics['accuracy'] ?? 0;
    final color = _getAccuracyColor(accuracy);
    
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.gps_fixed,
                color: color,
                size: 24.w,
              ),
              SizedBox(width: 12.w),
              Text(
                '答题正确率',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '$accuracy%',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // 进度条
          LinearProgressIndicator(
            value: accuracy / 100,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6.h,
          ),
          SizedBox(height: 8.h),
          Text(
            _getAccuracyDescription(accuracy),
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats() {
    final totalUsage = _statistics['totalUsage'] ?? 0;
    final totalQuestions = _statistics['totalQuestions'] ?? 0;
    final wrongQuestions = _statistics['totalWrongQuestions'] ?? 0;
    
    return Column(
      children: [
        _buildDetailStatRow(
          '总答题次数',
          totalUsage.toString(),
          Icons.quiz,
          AppColors.info,
        ),
        SizedBox(height: 8.h),
        _buildDetailStatRow(
          '平均每题使用',
          totalQuestions > 0 ? (totalUsage / totalQuestions).toStringAsFixed(1) : '0.0',
          Icons.repeat,
          AppColors.warning,
        ),
        SizedBox(height: 8.h),
        _buildDetailStatRow(
          '错误率',
          totalUsage > 0 ? '${((wrongQuestions / totalUsage) * 100).toStringAsFixed(1)}%' : '0%',
          Icons.trending_down,
          AppColors.error,
        ),
      ],
    );
  }

  Widget _buildDetailStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Icon(
            icon,
            color: color,
            size: 16.w,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Color _getAccuracyColor(int accuracy) {
    if (accuracy >= 80) {
      return AppColors.success;
    } else if (accuracy >= 60) {
      return AppColors.warning;
    } else {
      return AppColors.error;
    }
  }

  String _getAccuracyDescription(int accuracy) {
    if (accuracy >= 90) {
      return '优秀！继续保持这种状态';
    } else if (accuracy >= 80) {
      return '不错！还有提升空间';
    } else if (accuracy >= 60) {
      return '一般，建议多练习错题';
    } else {
      return '需要加强练习';
    }
  }
} 