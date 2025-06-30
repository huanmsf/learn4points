import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/app_colors.dart';

class QuestionBankScreen extends StatefulWidget {
  const QuestionBankScreen({Key? key}) : super(key: key);

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('题库管理'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books,
              size: 64.w,
              color: AppColors.primary,
            ),
            SizedBox(height: 16.h),
            Text(
              '题库管理功能开发中',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '即将为您提供完整的题库管理功能',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 