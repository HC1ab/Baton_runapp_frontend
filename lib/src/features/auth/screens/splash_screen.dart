import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

/// Shown while AuthNotifier.build() reads tokens from secure storage.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dScreen,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icons/cha_ji_symbol.png',
              width: 80.r,
              height: 80.r,
            ),
            SizedBox(height: 16.h),
            Text(
              '차지',
              style: GoogleFonts.barlowCondensed(
                fontSize: 32.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 52.h),
            SizedBox(
              width: 22.r,
              height: 22.r,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
