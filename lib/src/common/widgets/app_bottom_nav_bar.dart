import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';

/// App-wide bottom navigation bar — floating dark glass pill (redesign).
/// Used in 2+ features → lives in common/widgets.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    _NavItem(icon: Icons.directions_run_rounded, label: '러닝'),
    _NavItem(icon: Icons.flag_rounded, label: '점령'),
    _NavItem(icon: Icons.people_alt_rounded, label: '소셜'),
    _NavItem(icon: Icons.home_rounded, label: '마이 룸'),
    _NavItem(icon: Icons.person_rounded, label: '프로필'),
  ];

  @override
  Widget build(BuildContext context) {
    final systemBottom = MediaQuery.of(context).padding.bottom;
    // 시스템 인셋의 절반만 적용해 바 위치를 낮춤 (최소 4.h 확보)
    final bottomPad = systemBottom > 0
        ? (systemBottom / 3).clamp(4.h, 20.h)
        : 12.h;
    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomPad,
        left: 14.w,
        right: 14.w,
      ),
      child: Container(
          height: 75.h,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E21), // 불투명 — 뒤 콘텐츠 비침/번짐 없음
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: AppColors.dLine2, width: 1),
          ),
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              return Expanded(
                child: _NavButton(
                  icon: item.icon,
                  label: item.label,
                  selected: currentIndex == index,
                  onTap: () => onTap(index),
                ),
              );
            }),
          ),
        ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.dAccent : AppColors.dFaint;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26.r),
          SizedBox(height: 6.h),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5.sp,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}
