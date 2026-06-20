import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_snack_bar.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/services/auth_service.dart';
import '../providers/notice_providers.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meAsync = ref.watch(memberMeProvider);

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
          '계정',
          style: AppTextStyles.headlineMedium.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
      ),
      body: meAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => _buildError(context, ref),
        data: (user) => ListView(
          children: [
            SizedBox(height: 8.h),

            // ── 계정 정보 ────────────────────────────────────────────────────
            _SectionHeader(label: '계정 정보'),
            _buildInfoCard(children: [
              _InfoRow(label: '이메일', value: user.email),
              _Divider(),
              _InfoRow(label: '닉네임', value: user.nickname),
              _Divider(),
              _InfoRow(label: '이름', value: user.realname),
            ]),

            SizedBox(height: 24.h),

            // ── 보안 ─────────────────────────────────────────────────────────
            _SectionHeader(label: '보안'),
            _buildActionCard(children: [
              _ActionTile(
                icon: Icons.lock_outline_rounded,
                iconBg: const Color(0xFFEEF2FF),
                iconColor: const Color(0xFF5C6BC0),
                label: '비밀번호 변경',
                onTap: () => _showChangePasswordSheet(context, ref),
              ),
            ]),

            SizedBox(height: 24.h),

            // ── 회원 탈퇴 ────────────────────────────────────────────────────
            _SectionHeader(label: ''),
            _buildActionCard(children: [
              _ActionTile(
                icon: Icons.person_remove_outlined,
                iconBg: AppColors.error.withValues(alpha: 0.1),
                iconColor: AppColors.error,
                label: '회원 탈퇴',
                labelColor: AppColors.error,
                showArrow: false,
                onTap: () => _confirmDeleteAccount(context, ref),
              ),
            ]),

            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required List<Widget> children}) {
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

  Widget _buildActionCard({required List<Widget> children}) {
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

  Widget _buildError(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 40.r, color: AppColors.error),
          SizedBox(height: 12.h),
          Text('정보를 불러오지 못했어요.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.dMuted)),
          SizedBox(height: 12.h),
          TextButton(
            onPressed: () => ref.invalidate(memberMeProvider),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context, WidgetRef ref) {
    final oldPwCtrl = TextEditingController();
    final newPwCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var isLoading = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.dCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24.w,
            right: 24.w,
            top: 24.h,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32.h,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.dLine2,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                Text('비밀번호 변경',
                    style: AppTextStyles.headlineSmall
                        .copyWith(fontWeight: FontWeight.w800)),
                SizedBox(height: 20.h),
                _PwField(
                  controller: oldPwCtrl,
                  label: '현재 비밀번호',
                  validator: (v) =>
                      (v == null || v.isEmpty) ? '현재 비밀번호를 입력해주세요.' : null,
                ),
                SizedBox(height: 12.h),
                _PwField(
                  controller: newPwCtrl,
                  label: '새 비밀번호',
                  validator: (v) {
                    if (v == null || v.length < 6) return '6자 이상 입력해주세요.';
                    return null;
                  },
                ),
                SizedBox(height: 12.h),
                _PwField(
                  controller: confirmCtrl,
                  label: '새 비밀번호 확인',
                  validator: (v) =>
                      v != newPwCtrl.text ? '비밀번호가 일치하지 않아요.' : null,
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    onPressed: isLoading
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setSheetState(() => isLoading = true);
                            try {
                              await ref
                                  .read(authServiceWithTokenProvider)
                                  .changePassword(
                                    oldPassword: oldPwCtrl.text,
                                    newPassword: newPwCtrl.text,
                                  );
                              if (ctx.mounted) {
                                Navigator.of(ctx).pop();
                                AppSnackBar.success(context, '비밀번호가 변경되었어요.');
                              }
                            } catch (e) {
                              setSheetState(() => isLoading = false);
                              if (ctx.mounted) {
                                AppSnackBar.error(ctx,
                                  e is ApiException ? e.message : '비밀번호 변경에 실패했어요. 다시 시도해주세요.');
                              }
                            }
                          },
                    child: isLoading
                        ? SizedBox(
                            width: 20.r,
                            height: 20.r,
                            child: const CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('변경하기',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    final pwCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text('회원 탈퇴',
            style: AppTextStyles.headlineSmall
                .copyWith(fontWeight: FontWeight.w800, color: AppColors.error)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '탈퇴 시 모든 데이터가 삭제되며\n복구할 수 없어요. 정말 탈퇴하시겠어요?',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.dMuted),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: pwCtrl,
              obscureText: true,
              decoration: InputDecoration(
                hintText: '비밀번호 입력',
                filled: true,
                fillColor: AppColors.dCard2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('취소',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.dMuted)),
          ),
          TextButton(
            onPressed: () async {
              final password = pwCtrl.text.trim();
              if (password.isEmpty) return;
              Navigator.of(ctx).pop();
              try {
                await ref
                    .read(authServiceWithTokenProvider)
                    .deleteAccount(password: password);
                await ref.read(authProvider.notifier).forceLogout();
              } catch (e) {
                if (context.mounted) {
                  AppSnackBar.error(context,
                    e is ApiException ? e.message : '회원 탈퇴에 실패했어요. 다시 시도해주세요.');
                }
              }
            },
            child: Text('탈퇴',
                style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── 공통 위젯 ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return SizedBox(height: 0.h);
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.dMuted,
              )),
          const Spacer(),
          Text(
            value.isEmpty ? '-' : value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: value.isEmpty ? AppColors.dMuted : AppColors.dText,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, indent: 20.w, endIndent: 20.w, color: AppColors.dLine);
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.showArrow = true,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final Color? labelColor;
  final bool showArrow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
        child: Row(
          children: [
            Container(
              width: 36.r,
              height: 36.r,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
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
            if (showArrow)
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14.r, color: AppColors.dMuted),
          ],
        ),
      ),
    );
  }
}

class _PwField extends StatelessWidget {
  const _PwField({
    required this.controller,
    required this.label,
    required this.validator,
  });
  final TextEditingController controller;
  final String label;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.dCard2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.error, width: 1),
        ),
      ),
    );
  }
}
