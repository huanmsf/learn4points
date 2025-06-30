import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/app_colors.dart';

class WrongQuestionsScreen extends StatefulWidget {
  const WrongQuestionsScreen({Key? key}) : super(key: key);

  @override
  State<WrongQuestionsScreen> createState() => _WrongQuestionsScreenState();
}

class _WrongQuestionsScreenState extends State<WrongQuestionsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('错题库'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64.w,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16.h),
            Text(
              '错题库功能开发中',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '即将为您提供智能错题管理功能',
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