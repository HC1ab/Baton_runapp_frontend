import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';

/// Floating action style run control.
/// Play button (start) / Stop button (finish) + locate-me.
class RunningActionBar extends StatelessWidget {
  const RunningActionBar({
    super.key,
    required this.isRunning,
    required this.isBusy,
    required this.onStart,
    required this.onFinish,
    required this.onLocateMe,
  });

  final bool isRunning;
  final bool isBusy;
  final VoidCallback onStart;
  final VoidCallback onFinish;
  final VoidCallback onLocateMe;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Locate me — small tonal button
        _LocateButton(isBusy: isBusy, onTap: onLocateMe),
        SizedBox(width: AppSpacing.sm),

        // Main action — large circular FAB style
        _RunButton(
          isRunning: isRunning,
          isBusy: isBusy,
          onTap: isRunning ? onFinish : onStart,
        ),
      ],
    );
  }
}

class _RunButton extends StatelessWidget {
  const _RunButton({
    required this.isRunning,
    required this.isBusy,
    required this.onTap,
  });

  final bool isRunning;
  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isBusy ? null : onTap,
      child: Container(
        width: 64.r,
        height: 64.r,
        decoration: BoxDecoration(
          color: isRunning ? AppColors.error : AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (isRunning ? AppColors.error : AppColors.primary)
                  .withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: isBusy
            ? Padding(
                padding: EdgeInsets.all(18.r),
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Icon(
                isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 32.r,
              ),
      ),
    );
  }
}

class _LocateButton extends StatelessWidget {
  const _LocateButton({required this.isBusy, required this.onTap});

  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isBusy ? null : onTap,
      child: Container(
        width: 44.r,
        height: 44.r,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          Icons.my_location_rounded,
          color: AppColors.textSecondary,
          size: 20.r,
        ),
      ),
    );
  }
}
