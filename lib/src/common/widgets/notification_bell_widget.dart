import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../features/notifications/providers/notification_providers.dart';

class NotificationBellWidget extends ConsumerWidget {
  const NotificationBellWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCountAsync = ref.watch(notificationUnreadCountProvider);
    final count = unreadCountAsync.when(
      data: (count) => count,
      loading: () => 0,
      error: (_, _) => 0,
    );

    return GestureDetector(
      onTap: () {
        context.push(AppRoutes.notifications).then((_) {
          ref.invalidate(notificationUnreadCountProvider);
          ref.invalidate(notificationsProvider);
        });
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.notifications_rounded,
            color: AppColors.dMuted,
            size: 22.r,
          ),
          if (count > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 16.r,
                height: 16.r,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
