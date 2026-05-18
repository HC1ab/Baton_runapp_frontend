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

  Future<void> _submit() async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '회원가입이 완료되었습니다. 로그인해 주세요.',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final joinState = ref.watch(joinProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColors.textPrimary,
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
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '이메일과 비밀번호로 간단히 시작할 수 있어요.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
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
                    onPressed: joinState.isLoading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor:
                          AppColors.primary.withValues(alpha: 0.5),
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
                        color: AppColors.textSecondary,
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
      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
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
      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: '비밀번호',
        hintText: '8자 이상',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: AppColors.textSecondary,
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
