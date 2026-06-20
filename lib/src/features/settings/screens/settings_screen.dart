import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          '설정',
          style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
      ),
      body: ListView(
        children: [
          SizedBox(height: 8.h),

          // ── 계정 ──────────────────────────────────────────────────────────
          _SectionHeader(label: '계정'),
          _SettingsCard(children: [
            _SettingsTile(
              icon: Icons.person_outline_rounded,
              iconBg: AppColors.primary.withValues(alpha: 0.12),
              iconColor: AppColors.primary,
              label: '계정',
              onTap: () => context.push(AppRoutes.account),
            ),
          ]),

          SizedBox(height: 24.h),

          // ── 앱 정보 ───────────────────────────────────────────────────────
          _SectionHeader(label: '앱 정보'),
          _SettingsCard(children: [
            _SettingsTile(
              icon: Icons.campaign_outlined,
              iconBg: const Color(0xFFFFF3E0),
              iconColor: const Color(0xFFE65100),
              label: '공지사항',
              onTap: () => context.push(AppRoutes.noticeList),
            ),
            _TileDivider(),
            _SettingsTile(
              icon: Icons.privacy_tip_outlined,
              iconBg: const Color(0xFFE8F5E9),
              iconColor: const Color(0xFF388E3C),
              label: '개인정보처리방침',
              onTap: () => context.push(AppRoutes.privacyPolicy),
            ),
            _TileDivider(),
            _SettingsTile(
              icon: Icons.description_outlined,
              iconBg: const Color(0xFFE3F2FD),
              iconColor: const Color(0xFF1976D2),
              label: '이용약관',
              onTap: () => context.push(AppRoutes.termsOfService),
            ),
            _TileDivider(),
            _SettingsTile(
              icon: Icons.info_outline_rounded,
              iconBg: const Color(0xFFF3E5F5),
              iconColor: const Color(0xFF7B1FA2),
              label: '앱 버전',
              trailing: Text(
                'v1.0.0',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dMuted,
                ),
              ),
              onTap: null,
            ),
          ]),

          SizedBox(height: 32.h),

          // ── 로그아웃 ──────────────────────────────────────────────────────
          _SettingsCard(children: [
            _SettingsTile(
              icon: Icons.logout_rounded,
              iconBg: AppColors.error.withValues(alpha: 0.1),
              iconColor: AppColors.error,
              label: '로그아웃',
              labelColor: AppColors.error,
              showArrow: false,
              onTap: () => _confirmLogout(context, ref),
            ),
          ]),

          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r)),
        title: Text('로그아웃',
            style: AppTextStyles.headlineSmall
                .copyWith(fontWeight: FontWeight.w800)),
        content: Text('정말 로그아웃 하시겠어요?',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.dMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('취소',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.dMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authProvider.notifier).logout();
            },
            child: Text('로그아웃',
                style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── 공통 위젯 ────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 8.h),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.dMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: AppColors.dCard,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.dLine, width: 1),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.trailing,
    this.showArrow = true,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final Color? labelColor;
  final Widget? trailing;
  final bool showArrow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          children: [
            Container(
              width: 36.r,
              height: 36.r,
              decoration:
                  BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 18.r),
            ),
            SizedBox(width: 14.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: labelColor ?? AppColors.dText,
              ),
            ),
            const Spacer(),
            ?trailing,
            if (trailing == null && showArrow)
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14.r, color: AppColors.dMuted),
          ],
        ),
      ),
    );
  }
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, indent: 66.w, color: AppColors.dLine);
}
