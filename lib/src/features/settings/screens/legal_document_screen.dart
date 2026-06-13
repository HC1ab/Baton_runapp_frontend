import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../data/legal_documents.dart';

/// 개인정보처리방침 / 이용약관 등 약관성 문서를 보여주는 공용 화면.
class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dScreen,
      appBar: AppBar(
        backgroundColor: AppColors.dScreen,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.dText, size: 20.r),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          title,
          style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 40.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '시행일자 ${LegalDocuments.effectiveDate}',
              style: TextStyle(fontSize: 13.sp, color: AppColors.dMuted),
            ),
            SizedBox(height: 16.h),
            Divider(color: AppColors.dLine),
            SizedBox(height: 16.h),
            Text(
              content.trim(),
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.dText,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
