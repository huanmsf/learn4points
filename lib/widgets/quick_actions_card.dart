import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/app_colors.dart';

class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({Key? key}) : super(key: key);

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
                Icons.flash_on,
                color: AppColors.primary,
                size: 24.w,
              ),
              SizedBox(width: 8.w),
              Text(
                '快捷操作',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16.h),
          
          // 操作按钮网格
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      '错题练习',
                      '复习错题库',
                      Icons.replay,
                      AppColors.error,
                      () => _navigateToWrongQuestions(context),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildActionButton(
                      '题库管理',
                      '查看题库',
                      Icons.library_books,
                      AppColors.primary,
                      () => _navigateToQuestionBank(context),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      '手动识别',
                      '手动上传截图',
                      Icons.add_photo_alternate,
                      AppColors.info,
                      () => _showManualRecognition(context),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildActionButton(
                      '数据备份',
                      '备份题库数据',
                      Icons.backup,
                      AppColors.success,
                      () => _showBackupOptions(context),
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

  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 图标
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20.w,
                ),
              ),
              
              SizedBox(height: 12.h),
              
              // 标题
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              
              SizedBox(height: 4.h),
              
              // 副标题
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToWrongQuestions(BuildContext context) {
    // TODO: 导航到错题库页面
    _showSnackBar(context, '正在打开错题库...');
  }

  void _navigateToQuestionBank(BuildContext context) {
    // TODO: 导航到题库管理页面
    _showSnackBar(context, '正在打开题库管理...');
  }

  void _showManualRecognition(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildManualRecognitionSheet(context),
    );
  }

  void _showBackupOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _buildBackupDialog(context),
    );
  }

  Widget _buildManualRecognitionSheet(BuildContext context) {
    return Container(
      height: 300.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Text(
                  '手动识别题目',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            SizedBox(height: 20.h),
            
            // 选项列表
            _buildSheetOption(
              '从相册选择',
              '选择已保存的截图',
              Icons.photo_library,
              AppColors.primary,
              () {
                Navigator.pop(context);
                _pickFromGallery(context);
              },
            ),
            
            SizedBox(height: 12.h),
            
            _buildSheetOption(
              '拍照识别',
              '拍摄题目照片',
              Icons.camera_alt,
              AppColors.info,
              () {
                Navigator.pop(context);
                _takePhoto(context);
              },
            ),
            
            SizedBox(height: 12.h),
            
            _buildSheetOption(
              '文字输入',
              '手动输入题目内容',
              Icons.text_fields,
              AppColors.success,
              () {
                Navigator.pop(context);
                _showTextInput(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetOption(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24.w,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
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
    );
  }

  Widget _buildBackupDialog(BuildContext context) {
    return AlertDialog(
      title: const Text('数据备份'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.upload, color: AppColors.primary),
            title: const Text('导出题库'),
            subtitle: const Text('将题库导出为文件'),
            onTap: () {
              Navigator.pop(context);
              _exportDatabase(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.download, color: AppColors.success),
            title: const Text('导入题库'),
            subtitle: const Text('从文件导入题库'),
            onTap: () {
              Navigator.pop(context);
              _importDatabase(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.cloud_upload, color: AppColors.info),
            title: const Text('云端备份'),
            subtitle: const Text('备份到云存储'),
            onTap: () {
              Navigator.pop(context);
              _cloudBackup(context);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ],
    );
  }

  void _pickFromGallery(BuildContext context) {
    _showSnackBar(context, '正在打开相册...');
    // TODO: 实现从相册选择图片
  }

  void _takePhoto(BuildContext context) {
    _showSnackBar(context, '正在打开相机...');
    // TODO: 实现拍照功能
  }

  void _showTextInput(BuildContext context) {
    _showSnackBar(context, '正在打开文字输入...');
    // TODO: 实现文字输入功能
  }

  void _exportDatabase(BuildContext context) {
    _showSnackBar(context, '正在导出题库数据...');
    // TODO: 实现数据导出
  }

  void _importDatabase(BuildContext context) {
    _showSnackBar(context, '正在导入题库数据...');
    // TODO: 实现数据导入
  }

  void _cloudBackup(BuildContext context) {
    _showSnackBar(context, '云端备份功能开发中...');
    // TODO: 实现云端备份
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
} 