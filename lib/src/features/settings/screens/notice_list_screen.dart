import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/notice_providers.dart';

class NoticeListScreen extends ConsumerWidget {
  const NoticeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noticesAsync = ref.watch(noticeListProvider);

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
          '공지사항',
          style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
      ),
      body: noticesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => _buildError(ref),
        data: (notices) => notices.isEmpty
            ? _buildEmpty()
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => ref.invalidate(noticeListProvider),
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  itemCount: notices.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: AppColors.dLine),
                  itemBuilder: (_, i) {
                    final notice = notices[i];
                    return InkWell(
                      onTap: () => context.push(
                        '/notices/${notice.noticeId}',
                        extra: notice.title,
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 20.w, vertical: 16.h),
                        child: Row(
                          children: [
                            if (notice.isPinned) ...[
                              Icon(Icons.push_pin_rounded,
                                  size: 16.r, color: AppColors.primary),
                              SizedBox(width: 8.w),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notice.title,
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: notice.isPinned
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: AppColors.dText,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    notice.formattedDate,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: AppColors.dMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Icon(Icons.arrow_forward_ios_rounded,
                                size: 14.r, color: AppColors.dMuted),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.campaign_outlined,
              size: 48.r,
              color: AppColors.primary.withValues(alpha: 0.25)),
          SizedBox(height: 16.h),
          Text('등록된 공지사항이 없어요.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.dMuted)),
        ],
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
                  .copyWith(color: AppColors.dMuted)),
          SizedBox(height: 12.h),
          TextButton(
            onPressed: () => ref.invalidate(noticeListProvider),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}
