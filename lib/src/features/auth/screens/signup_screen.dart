import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/login_provider.dart';

const _devEmail = 'test1@naver.com';
const _devPassword = 'password1234';
const _devRealname = '테스트1';
const _devNickname = '러너1';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _realnameController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _obscurePassword = true;

  bool _agreeAll = false;
  bool _agreeTerms = false;
  bool _agreePrivacy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(joinProvider.notifier).reset();
    });
    if (const String.fromEnvironment('ENV', defaultValue: 'dev') == 'dev') {
      _emailController.text = _devEmail;
      _passwordController.text = _devPassword;
      _realnameController.text = _devRealname;
      _nicknameController.text = _devNickname;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _realnameController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _onAgreeAll(bool? v) {
    final checked = v ?? false;
    setState(() {
      _agreeAll = checked;
      _agreeTerms = checked;
      _agreePrivacy = checked;
    });
  }

  void _onAgreeTerms(bool? v) {
    setState(() {
      _agreeTerms = v ?? false;
      _agreeAll = _agreeTerms && _agreePrivacy;
    });
  }

  void _onAgreePrivacy(bool? v) {
    setState(() {
      _agreePrivacy = v ?? false;
      _agreeAll = _agreeTerms && _agreePrivacy;
    });
  }

  bool get _canSubmit => _agreeTerms && _agreePrivacy;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    FocusScope.of(context).unfocus();
    await ref.read(joinProvider.notifier).join(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          realname: _realnameController.text.trim(),
          nickname: _nicknameController.text.trim(),
        );
    if (!mounted) return;
    final joinState = ref.read(joinProvider);
    if (joinState.status == JoinStatus.success) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _SignupSuccessDialog(
          onConfirm: () {
            Navigator.of(context).pop();
            context.go(AppRoutes.login);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final joinState = ref.watch(joinProvider);

    return Scaffold(
      backgroundColor: AppColors.dScreen,
      appBar: AppBar(
        backgroundColor: AppColors.dScreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColors.dText,
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '회원가입',
                  style: AppTextStyles.displayMedium.copyWith(
                    color: AppColors.dText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '이메일과 비밀번호로 간단히 시작할 수 있어요.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.dMuted,
                  ),
                ),
                SizedBox(height: 32.h),
                _LabeledField(
                  label: '이메일',
                  hint: 'hello@example.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  icon: Icons.email_outlined,
                  autofillHints: const [AutofillHints.email],
                ),
                SizedBox(height: AppSpacing.verticalMd),
                _PasswordField(
                  controller: _passwordController,
                  obscure: _obscurePassword,
                  onToggleObscure: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                SizedBox(height: AppSpacing.verticalMd),
                _LabeledField(
                  label: '이름',
                  hint: '실명',
                  controller: _realnameController,
                  textInputAction: TextInputAction.next,
                  icon: Icons.person_outline_rounded,
                  autofillHints: const [AutofillHints.name],
                ),
                SizedBox(height: AppSpacing.verticalMd),
                _LabeledField(
                  label: '닉네임',
                  hint: '앱에서 표시될 이름',
                  controller: _nicknameController,
                  textInputAction: TextInputAction.done,
                  icon: Icons.badge_outlined,
                  onFieldSubmitted: (_) => _submit(),
                ),
                SizedBox(height: 28.h),

                // ── 약관 동의 ─────────────────────────────────────────────
                _TermsSection(
                  agreeAll: _agreeAll,
                  agreeTerms: _agreeTerms,
                  agreePrivacy: _agreePrivacy,
                  onAgreeAll: _onAgreeAll,
                  onAgreeTerms: _onAgreeTerms,
                  onAgreePrivacy: _onAgreePrivacy,
                ),
                SizedBox(height: AppSpacing.verticalSm),

                if (joinState.status == JoinStatus.error &&
                    joinState.errorMessage != null)
                  Padding(
                    padding: EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      joinState.errorMessage!.trim(),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(height: AppSpacing.verticalXl),
                SizedBox(
                  height: 54.h,
                  child: FilledButton(
                    onPressed: (joinState.isLoading || !_canSubmit)
                        ? null
                        : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor:
                          AppColors.primary.withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      elevation: 0,
                    ),
                    child: joinState.isLoading
                        ? SizedBox(
                            width: 22.r,
                            height: 22.r,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            '가입하기',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '이미 계정이 있으신가요?',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.dMuted,
                      ),
                    ),
                    TextButton(
                      onPressed: joinState.isLoading
                          ? null
                          : () => context.go(AppRoutes.login),
                      child: Text(
                        '로그인',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 약관 동의 섹션 ─────────────────────────────────────────────────────────────

class _TermsSection extends StatelessWidget {
  const _TermsSection({
    required this.agreeAll,
    required this.agreeTerms,
    required this.agreePrivacy,
    required this.onAgreeAll,
    required this.onAgreeTerms,
    required this.onAgreePrivacy,
  });

  final bool agreeAll;
  final bool agreeTerms;
  final bool agreePrivacy;
  final ValueChanged<bool?> onAgreeAll;
  final ValueChanged<bool?> onAgreeTerms;
  final ValueChanged<bool?> onAgreePrivacy;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.dCard,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.dLine),
      ),
      child: Column(
        children: [
          // 전체 동의
          InkWell(
            onTap: () => onAgreeAll(!agreeAll),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              child: Row(
                children: [
                  _CheckIcon(checked: agreeAll, color: AppColors.primary),
                  SizedBox(width: 10.w),
                  Text(
                    '전체 동의',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dText,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: AppColors.dLine),

          // 서비스 이용약관
          _TermsItem(
            label: '서비스 이용약관',
            required: true,
            checked: agreeTerms,
            onChanged: onAgreeTerms,
            content: _kTermsOfService,
          ),
          Divider(height: 1, color: AppColors.dLine),

          // 개인정보 처리방침
          _TermsItem(
            label: '개인정보 처리방침',
            required: true,
            checked: agreePrivacy,
            onChanged: onAgreePrivacy,
            content: _kPrivacyPolicy,
          ),
        ],
      ),
    );
  }
}

class _TermsItem extends StatefulWidget {
  const _TermsItem({
    required this.label,
    required this.required,
    required this.checked,
    required this.onChanged,
    required this.content,
  });

  final String label;
  final bool required;
  final bool checked;
  final ValueChanged<bool?> onChanged;
  final String content;

  @override
  State<_TermsItem> createState() => _TermsItemState();
}

class _TermsItemState extends State<_TermsItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => widget.onChanged(!widget.checked),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              children: [
                _CheckIcon(
                  checked: widget.checked,
                  color: AppColors.primary,
                  size: 20.r,
                ),
                SizedBox(width: 10.w),
                if (widget.required)
                  Container(
                    margin: EdgeInsets.only(right: 6.w),
                    padding:
                        EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      '필수',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dText,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.dMuted,
                    size: 20.r,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Container(
            width: double.infinity,
            margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: AppColors.dScreen,
              borderRadius: BorderRadius.circular(10.r),
            ),
            constraints: BoxConstraints(maxHeight: 160.h),
            child: SingleChildScrollView(
              child: Text(
                widget.content,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.dFaint,
                  height: 1.6,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CheckIcon extends StatelessWidget {
  const _CheckIcon({required this.checked, required this.color, this.size});
  final bool checked;
  final Color color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final s = size ?? 22.r;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: s,
      height: s,
      decoration: BoxDecoration(
        color: checked ? color : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: checked ? color : AppColors.dMuted,
          width: 1.5,
        ),
      ),
      child: checked
          ? Icon(Icons.check_rounded, size: s * 0.65, color: Colors.white)
          : null,
    );
  }
}

// ── 약관 본문 ─────────────────────────────────────────────────────────────────

const _kTermsOfService = '''
제1조 (목적)
본 약관은 바통(이하 "회사")이 제공하는 Baton 서비스(이하 "서비스")의 이용조건 및 절차, 회사와 이용자의 권리·의무 및 책임 사항을 규정함을 목적으로 합니다.

제2조 (서비스 이용)
① 서비스는 GPS 기반 러닝 기록, 소셜 기능, 캐릭터 커스터마이징 등을 포함합니다.
② 이용자는 서비스 이용 시 타인의 권리를 침해하거나 법령에 위반되는 행위를 하여서는 안 됩니다.
③ 회사는 서비스 운영상 필요한 경우 사전 공지 후 서비스를 변경하거나 중단할 수 있습니다.

제3조 (계정)
① 이용자는 정확한 정보를 입력하여 회원가입을 완료하여야 합니다.
② 계정 정보의 관리 책임은 이용자에게 있으며, 타인에게 양도·공유할 수 없습니다.

제4조 (책임 제한)
회사는 천재지변, 서버 장애 등 불가항력적 사유로 인한 서비스 장애에 대해 책임을 지지 않습니다.

제5조 (준거법)
본 약관은 대한민국 법령에 의거하여 해석·적용됩니다.''';

const _kPrivacyPolicy = '''
■ 수집하는 개인정보 항목
필수: 이메일, 비밀번호(암호화 저장), 이름, 닉네임
러닝 기록: GPS 위치 정보, 운동 시간·거리·페이스

■ 개인정보 수집 및 이용 목적
· 회원 가입 및 서비스 이용 식별
· 러닝 기록 저장 및 통계 제공
· 소셜 기능(팔로우, 그룹 러닝) 운영
· 서비스 개선 및 통계 분석

■ 개인정보 보유 및 이용 기간
회원 탈퇴 시까지. 단, 관련 법령에 의해 보존이 필요한 경우 해당 기간 동안 보관합니다.

■ 개인정보의 제3자 제공
이용자의 동의 없이 제3자에게 제공하지 않습니다. 단, 법령에 의한 경우 제외.

■ 위치정보 이용
러닝 중 GPS 위치 정보를 수집합니다. 위치 권한을 거부할 경우 일부 서비스 이용이 제한될 수 있습니다.

■ 이용자의 권리
이용자는 언제든지 개인정보 열람, 수정, 삭제, 처리 정지를 요청할 수 있습니다. 문의: support@baton.run''';

// ── 입력 필드 위젯 ─────────────────────────────────────────────────────────────

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onFieldSubmitted,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final void Function(String)? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onFieldSubmitted: onFieldSubmitted,
      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.dText),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggleObscure,
  });

  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggleObscure;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.newPassword],
      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.dText),
      decoration: InputDecoration(
        labelText: '비밀번호',
        hintText: '8자 이상',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: AppColors.dMuted,
          ),
          onPressed: onToggleObscure,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }
}

class _SignupSuccessDialog extends StatelessWidget {
  const _SignupSuccessDialog({required this.onConfirm});

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      backgroundColor: AppColors.dCard,
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64.r,
              height: 64.r,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                color: AppColors.primary,
                size: 36.r,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              '회원가입 완료!',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.dText,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '계정이 성공적으로 생성되었어요.\n지금 바로 로그인해 보세요.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.dMuted,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 28.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: FilledButton(
                onPressed: onConfirm,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  '로그인하러 가기',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
