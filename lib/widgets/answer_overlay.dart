import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/question.dart';
import '../utils/app_colors.dart';

class AnswerOverlay extends StatelessWidget {
  final Question question;
  final List<String> answers;
  final String source;
  final double confidence;
  final VoidCallback? onClose;

  const AnswerOverlay({
    Key? key,
    required this.question,
    required this.answers,
    required this.source,
    required this.confidence,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black26,
      child: Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题栏
              Row(
                children: [
                  Icon(
                    Icons.lightbulb,
                    color: AppColors.primary,
                    size: 24.w,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '找到答案！',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              SizedBox(height: 16.h),
              
              // 题目信息
              Text(
                '题目类型: ${question.typeDescription}',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              
              SizedBox(height: 8.h),
              
              // 答案
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.success.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '推荐答案:',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      answers.join('、'),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 12.h),
              
              // 来源信息
              Row(
                children: [
                  Icon(
                    Icons.source,
                    size: 16.w,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '来源: $source',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '置信度: ${(confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 显示答案浮窗的辅助函数
void showAnswerOverlay(
  BuildContext context, {
  required Question question,
  required List<String> answers,
  required String source,
  required double confidence,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => AnswerOverlay(
      question: question,
      answers: answers,
      source: source,
      confidence: confidence,
      onClose: () => Navigator.of(context).pop(),
    ),
  );
} 