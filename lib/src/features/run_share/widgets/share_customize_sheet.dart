import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/stat_item_config.dart';
import '../providers/run_share_provider.dart';

/// 스탯별 표시 여부 토글 + 색상 팔레트
class ShareCustomizeSheet extends ConsumerWidget {
  const ShareCustomizeSheet({super.key});

  static const _palette = [
    Colors.white,
    Colors.black,
    AppColors.primary,
    AppColors.warning,
    AppColors.success,
    AppColors.error,
    AppColors.info,
    AppColors.textSecondary,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(runShareProvider);
    final notifier = ref.read(runShareProvider.notifier);

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xl + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 핸들
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            '항목 설정',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12.h),

          // 스탯 3개
          for (final stat in config.stats)
            _StatRow(
              stat: stat,
              palette: _palette,
              onToggle: () => notifier.toggleStat(stat.id),
              onColorTap: (color) => notifier.setStatColor(stat.id, color),
            ),

          SizedBox(height: 8.h),
          Text(
            '캔버스에서 직접 드래그해 위치를 조절하세요.\n우하단 핸들로 크기를 변경할 수 있습니다.',
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── _StatRow ──────────────────────────────────────────────────────────────────

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.stat,
    required this.palette,
    required this.onToggle,
    required this.onColorTap,
  });

  final StatItemConfig stat;
  final List<Color> palette;
  final VoidCallback onToggle;
  final ValueChanged<Color> onColorTap;

  String get _displayName => switch (stat.id) {
        'distance' => '거리 KM',
        'duration' => '시간',
        _ => '페이스',
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이름 + 토글
          Row(
            children: [
              Text(
                _displayName,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: stat.visible
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44.w,
                  height: 24.h,
                  decoration: BoxDecoration(
                    color: stat.visible ? AppColors.primary : AppColors.divider,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: stat.visible
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.all(3.r),
                      child: Container(
                        width: 18.r,
                        height: 18.r,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (stat.visible) ...[
            SizedBox(height: 8.h),
            // 색상 팔레트
            Row(
              children: [
                for (final color in palette)
                  _ColorDot(
                    color: color,
                    isSelected: stat.color.toARGB32() == color.toARGB32(),
                    onTap: () => onColorTap(color),
                  ),
              ],
            ),
          ],
          SizedBox(height: 4.h),
          Divider(height: 1, color: AppColors.divider),
        ],
      ),
    );
  }
}

// ── _ColorDot ─────────────────────────────────────────────────────────────────

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(right: 8.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 28.r,
          height: 28.r,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider,
              width: isSelected ? 2.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: isSelected
              ? Icon(
                  Icons.check_rounded,
                  size: 14.r,
                  color: color == Colors.white || color == Colors.black38
                      ? AppColors.primary
                      : Colors.white,
                )
              : null,
        ),
      ),
    );
  }
}
