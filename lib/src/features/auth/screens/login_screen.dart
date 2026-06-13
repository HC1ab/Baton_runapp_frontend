import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../providers/login_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // dev 환경에서 테스트 계정 자동 입력 (env에 없으면 빈값 유지)
    if (const String.fromEnvironment('ENV', defaultValue: 'dev') == 'dev') {
      final devEmail = dotenv.env['DEV_EMAIL'] ?? '';
      final devPassword = dotenv.env['DEV_PASSWORD'] ?? '';
      if (devEmail.isNotEmpty) _emailController.text = devEmail;
      if (devPassword.isNotEmpty) _passwordController.text = devPassword;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    await ref.read(loginProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  Future<void> _loginWithKakao() async {
    FocusScope.of(context).unfocus();
    await ref.read(loginProvider.notifier).loginWithKakao();
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginProvider);

    return Scaffold(
      backgroundColor: AppColors.dScreen,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 64.h),
                  const _Header(),
                  SizedBox(height: 40.h),

                  // Dev mode banner
                  if (const String.fromEnvironment('ENV', defaultValue: 'dev') == 'dev') ...[
                    _DevBanner(
                      onQuickLogin: () {
                        _emailController.text = dotenv.env['DEV_EMAIL'] ?? '';
                        _passwordController.text = dotenv.env['DEV_PASSWORD'] ?? '';
                        _submit();
                      },
                      onQuickLogin2: () {
                        _emailController.text = 'test1@naver.com';
                        _passwordController.text = 'password1234';
                        _submit();
                      },
                    ),
                    SizedBox(height: AppSpacing.verticalMd),
                  ],

                  _EmailField(controller: _emailController),
                  SizedBox(height: AppSpacing.verticalMd),
                  _PasswordField(
                    controller: _passwordController,
                    obscure: _obscurePassword,
                    onToggleObscure: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  SizedBox(height: AppSpacing.verticalSm),

                  // Error message
                  if (loginState.status == LoginStatus.error &&
                      loginState.errorMessage != null)
                    Padding(
                      padding: EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        loginState.errorMessage!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  SizedBox(height: AppSpacing.verticalXl),
                  _LoginButton(
                    isLoading: loginState.isLoading,
                    onPressed: loginState.isLoading ? null : _submit,
                  ),

                  //  추가: 카카오 로그인 버튼
                  SizedBox(height: 12.h),
                  _KakaoLoginButton(
                    isLoading: loginState.isLoading,
                    onPressed: loginState.isLoading ? null : _loginWithKakao,
                  ),

                  SizedBox(height: 16.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '계정이 없으신가요?',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.dMuted,
                        ),
                      ),
                      TextButton(
                        onPressed: loginState.isLoading
                            ? null
                            : () => context.push(AppRoutes.signup),
                        child: Text(
                          '회원가입',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo circle
        Container(
          width: 52.r,
          height: 52.r,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.directions_run_rounded,
            color: Colors.white,
            size: 28.r,
          ),
        ),
        SizedBox(height: 24.h),
        Text(
          'BATON',
          style: AppTextStyles.displayMedium.copyWith(
            color: AppColors.dText,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          '로그인하고 오늘의 러닝을 시작해보세요.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.dMuted,
          ),
        ),
      ],
    );
  }
}

class _DevBanner extends StatelessWidget {
  const _DevBanner({
    required this.onQuickLogin,
    required this.onQuickLogin2,
  });

  final VoidCallback onQuickLogin;
  final VoidCallback onQuickLogin2;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.construction_rounded, size: 15.r, color: AppColors.primary),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '개발 모드 · ${dotenv.env['DEV_EMAIL'] ?? ''}',
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
                ),
              ),
              _QuickLoginButton(label: 'ADMIN', onTap: onQuickLogin),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Icon(Icons.construction_rounded, size: 15.r, color: Colors.transparent),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'test1@naver.com',
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
                ),
              ),
              _QuickLoginButton(label: 'test1', onTap: onQuickLogin2),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickLoginButton extends StatelessWidget {
  const _QuickLoginButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4.h),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _EmailField extends StatelessWidget {
  const _EmailField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.email],
      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.dText),
      decoration: InputDecoration(
        labelText: '이메일',
        hintText: 'hello@example.com',
        prefixIcon: const Icon(Icons.email_outlined),
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
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.password],
      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.dText),
      decoration: InputDecoration(
        labelText: '비밀번호',
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

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54.h,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                width: 22.r,
                height: 22.r,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                '로그인',
                style: AppTextStyles.labelLarge.copyWith(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}

// 추가: 카카오 버튼 위젯
class _KakaoLoginButton extends StatelessWidget {
  const _KakaoLoginButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54.h,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFFEE500),
          disabledBackgroundColor: const Color(0xFFFEE500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                width: 22.r,
                height: 22.r,
                child: const CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_rounded, color: Colors.black, size: 18.r),
                  SizedBox(width: 8.w),
                  Text(
                    '카카오로 로그인',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
