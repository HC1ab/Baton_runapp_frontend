import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/follow/providers/follow_providers.dart';
import '../../../core/utils/app_snack_bar.dart';
import '../../social/follow_requests_screen.dart';
import '../models/app_notification_model.dart';
import '../providers/notification_providers.dart';

class NotificationListScreen extends ConsumerWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final hasUnread = notificationsAsync.maybeWhen(
      data: (items) => items.any((item) => !item.isRead),
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: AppColors.dScreen,
      appBar: AppBar(
        backgroundColor: AppColors.dScreen,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.dText,
            size: 20.r,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          '알림',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.dText,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (hasUnread)
            IconButton(
              tooltip: '모두 읽음',
              icon: Icon(
                Icons.done_all_rounded,
                color: AppColors.dAccent,
                size: 22.r,
              ),
              onPressed: () => _markAllAsRead(context, ref),
            ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.dAccent),
        ),
        error: (_, _) => _buildError(ref),
        data: (notifications) => notifications.isEmpty
            ? _buildEmpty(ref)
            : RefreshIndicator(
                color: AppColors.dAccent,
                onRefresh: () => _refresh(ref),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  itemCount: notifications.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: AppColors.dLine),
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _NotificationTile(
                      notification: notification,
                      onTap: () => _handleTap(context, ref, notification),
                    );
                  },
                ),
              ),
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(notificationsProvider);
    ref.invalidate(notificationUnreadCountProvider);
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> _markAllAsRead(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(notificationServiceProvider).markAllAsRead();
      ref.invalidate(notificationsProvider);
      ref.invalidate(notificationUnreadCountProvider);
    } on AppException catch (e) {
      if (context.mounted) AppSnackBar.error(context, e.message);
    } catch (_) {
      if (context.mounted) AppSnackBar.error(context, '알림 처리에 실패했어요.');
    }
  }

  Future<void> _handleTap(
    BuildContext context,
    WidgetRef ref,
    AppNotificationModel notification,
  ) async {
    try {
      if (!notification.isRead) {
        await ref
            .read(notificationServiceProvider)
            .markAsRead(notification.notificationId);
        ref.invalidate(notificationsProvider);
        ref.invalidate(notificationUnreadCountProvider);
      }

      if (!context.mounted) return;
      if (notification.pointsToSpot) {
        final spotId = notification.targetIdAsInt;
        if (spotId != null) {
          context.push('${AppRoutes.spotDetail}/$spotId');
          return;
        }
      }

      if (notification.type == AppNotificationType.followRequest) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const FollowRequestsScreen()),
        );
        ref.invalidate(pendingFollowRequestsProvider);
        return;
      }

      if (notification.type == AppNotificationType.followAccepted) {
        context.push(AppRoutes.friends);
      }
    } on AppException catch (e) {
      if (context.mounted) AppSnackBar.error(context, e.message);
    } catch (_) {
      if (context.mounted) AppSnackBar.error(context, '알림 처리에 실패했어요.');
    }
  }

  Widget _buildEmpty(WidgetRef ref) {
    return RefreshIndicator(
      color: AppColors.dAccent,
      onRefresh: () => _refresh(ref),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: constraints.maxHeight,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 52.r,
                    color: AppColors.dLine2,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    '아직 받은 알림이 없어요.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.dMuted,
                    ),
                  ),
                ],
              ),
            ),
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
          Icon(Icons.error_outline_rounded, size: 40.r, color: AppColors.error),
          SizedBox(height: 12.h),
          Text(
            '알림을 불러오지 못했어요.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.dMuted),
          ),
          SizedBox(height: 12.h),
          TextButton(
            onPressed: () => ref.invalidate(notificationsProvider),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = _iconFor(notification.type);
    final color = _colorFor(notification.type);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                color: color.withValues(
                  alpha: notification.isRead ? 0.10 : 0.18,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 21.r),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.dText,
                            fontSize: 15.sp,
                            fontWeight: notification.isRead
                                ? FontWeight.w600
                                : FontWeight.w800,
                          ),
                        ),
                      ),
                      if (!notification.isRead) ...[
                        SizedBox(width: 8.w),
                        Container(
                          width: 8.r,
                          height: 8.r,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    notification.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: notification.isRead
                          ? AppColors.dMuted
                          : AppColors.dText.withValues(alpha: 0.86),
                      fontSize: 13.sp,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    _formatCreatedAt(notification.createdAt),
                    style: TextStyle(color: AppColors.dFaint, fontSize: 11.sp),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.spotStealRisk:
        return Icons.location_searching_rounded;
      case AppNotificationType.spotStolen:
        return Icons.flag_rounded;
      case AppNotificationType.followRequest:
        return Icons.person_add_alt_1_rounded;
      case AppNotificationType.followAccepted:
        return Icons.people_alt_rounded;
      case AppNotificationType.unknown:
        return Icons.notifications_rounded;
    }
  }

  Color _colorFor(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.spotStealRisk:
        return AppColors.warning;
      case AppNotificationType.spotStolen:
        return AppColors.error;
      case AppNotificationType.followRequest:
        return AppColors.dAccent;
      case AppNotificationType.followAccepted:
        return AppColors.success;
      case AppNotificationType.unknown:
        return AppColors.dMuted;
    }
  }

  String _formatCreatedAt(DateTime createdAt) {
    final local = createdAt.toLocal();
    final now = DateTime.now();
    final period = local.hour < 12 ? '오전' : '오후';
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final time = '$period $hour:$minute';

    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      return time;
    }
    return '${local.month}월 ${local.day}일 $time';
  }
}
