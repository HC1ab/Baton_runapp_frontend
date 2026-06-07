import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/notice_providers.dart';

class NoticeDetailScreen extends ConsumerWidget {
  const NoticeDetailScreen({super.key, required this.noticeId, this.title});
  final int noticeId;
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(noticeDetailProvider(noticeId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20.r),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          title ?? '공지사항',
          style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.w800),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: false,
      ),
      body: detailAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => _buildError(ref),
        data: (notice) => SingleChildScrollView(
          padding: EdgeInsets.all(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목 + 날짜
              if (notice.isPinned)
                Container(
                  margin: EdgeInsets.only(bottom: 8.h),
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.push_pin_rounded,
                          size: 13.r, color: AppColors.primary),
                      SizedBox(width: 4.w),
                      Text('공지',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          )),
                    ],
                  ),
                ),
              Text(
                notice.title,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                notice.formattedDate,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 20.h),
              Divider(color: AppColors.divider),
              SizedBox(height: 20.h),

              // 본문
              Text(
                notice.content,
                style: TextStyle(
                  fontSize: 15.sp,
                  color: AppColors.textPrimary,
                  height: 1.7,
                ),
              ),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 40.r, color: AppColors.error),
          SizedBox(height: 12.h),
          Text('공지사항을 불러오지 못했어요.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
          SizedBox(height: 12.h),
          TextButton(
            onPressed: () => ref.invalidate(noticeDetailProvider(noticeId)),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}
