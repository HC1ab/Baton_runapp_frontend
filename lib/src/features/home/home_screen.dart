import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../common/widgets/app_bottom_nav_bar.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/shell/shell_providers.dart';

/// Root shell: owns the bottom nav + IndexedStack.
/// Does NOT import any feature directly — tabs are registered via [TabRegistry].
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentTab = AppTabs.running;

  void _onTabTap(int index) {
    setState(() => _currentTab = index);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = ref.watch(tabRegistryProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        // bottom: false — nav bar 자체가 SafeArea를 처리함
        bottom: false,
        child: IndexedStack(
          index: _currentTab,
          children: tabs.map((t) => t.builder(context)).toList(),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentTab,
        onTap: _onTabTap,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Placeholder tab — feature 미구현 화면용
// SafeArea 중복 없이 부모(HomeScreen)의 SafeArea에 위임
// ---------------------------------------------------------------------------

class PlaceholderTab extends StatelessWidget {
  const PlaceholderTab({
    super.key,
    required this.icon,
    required this.label,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          backgroundColor: AppColors.backgroundLight,
          title: Text(
            label,
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [if (trailing != null) trailing!],
          automaticallyImplyLeading: false,
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 48.r,
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  '준비 중',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
