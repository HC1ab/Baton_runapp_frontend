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

          // 자유 배치 모드: 글로우 경로 토글 + 색상 + 두께
          if (config.cardStyle == CardStyle.freestyle || config.cardStyle == CardStyle.free2) ...[
            _ToggleRow(
              label: '글로우 경로',
              value: config.showRoute,
              onToggle: notifier.toggleRoute,
            ),
            if (config.showRoute) ...[
              SizedBox(height: 10.h),
              // 색상 팔레트
              Row(
                children: [
                  for (final color in _palette)
                    _ColorDot(
                      color: color,
                      isSelected:
                          config.routeColor.toARGB32() == color.toARGB32(),
                      onTap: () => notifier.setRouteColor(color),
                    ),
                ],
              ),
              SizedBox(height: 10.h),
              // 두께 슬라이더
              Row(
                children: [
                  Text(
                    '두께',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: config.routeStrokeWidth,
                      min: 1.0,
                      max: 8.0,
                      divisions: 14,
                      activeColor: AppColors.primary,
                      inactiveColor: AppColors.divider,
                      onChanged: notifier.setRouteStrokeWidth,
                    ),
                  ),
                  Text(
                    config.routeStrokeWidth.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 4.h),
            Divider(height: 1, color: AppColors.divider),
            SizedBox(height: 14.h),
          ],

          // 태그 스타일
          _TagStyleRow(
            current: config.tagStyle,
            onSelect: notifier.setTagStyle,
          ),
          SizedBox(height: 14.h),
          Divider(height: 1, color: AppColors.divider),
          SizedBox(height: 14.h),

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

// ── _ToggleRow ────────────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onToggle,
  });

  final String label;
  final bool value;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: value ? AppColors.textPrimary : AppColors.textSecondary,
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
              color: value ? AppColors.primary : AppColors.divider,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
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

// ── _TagStyleRow ──────────────────────────────────────────────────────────────

class _TagStyleRow extends StatelessWidget {
  const _TagStyleRow({required this.current, required this.onSelect});
  final TagStyle current;
  final ValueChanged<TagStyle> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CHAGI 태그',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            _TagPreview(
              tagStyle: TagStyle.dark,
              isSelected: current == TagStyle.dark,
              onTap: () => onSelect(TagStyle.dark),
            ),
            SizedBox(width: 12.w),
            _TagPreview(
              tagStyle: TagStyle.light,
              isSelected: current == TagStyle.light,
              onTap: () => onSelect(TagStyle.light),
            ),
          ],
        ),
      ],
    );
  }
}

class _TagPreview extends StatelessWidget {
  const _TagPreview({
    required this.tagStyle,
    required this.isSelected,
    required this.onTap,
  });
  final TagStyle tagStyle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = tagStyle == TagStyle.dark;
    final bgColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final label = isDark ? '블랙' : '화이트';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'CHAGI',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
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
