import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../common/widgets/app_bottom_nav_bar.dart';
import '../../common/widgets/group_connection_badge.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/shell/shell_providers.dart';
import '../../core/shell/tab_providers.dart';
import '../auth/providers/auth_provider.dart';
import '../group_running/providers/run_location_provider.dart';

const _isDev = String.fromEnvironment('ENV', defaultValue: 'dev') == 'dev';

/// Root shell: owns the bottom nav + IndexedStack.
/// Does NOT import any feature directly — tabs are registered via [TabRegistry].
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  void _onTabTap(int index) {
    ref.read(currentTabProvider.notifier).switchTo(index);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = ref.watch(tabRegistryProvider);
    final currentTab = ref.watch(currentTabProvider);
    final connState = ref.watch(
      runLocationProvider.select((s) => s.connectionState),
    );
    final showBadge = connState != RunLocationConnectionState.idle;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      extendBody: true,
      body: Stack(
        children: [
          SafeArea(
            // bottom: false — nav bar 자체가 SafeArea를 처리함
            bottom: false,
            child: IndexedStack(
              index: currentTab,
              children: tabs.map((t) => t.builder(context)).toList(),
            ),
          ),
          if (showBadge)
            Positioned(
              top: topPadding + 12,
              left: 0,
              right: 0,
              child: Center(
                child: GroupConnectionBadge(connectionState: connState),
              ),
            ),
        ],
      ),
      floatingActionButton: _isDev
          ? FloatingActionButton.small(
              heroTag: 'dev_logout',
              backgroundColor: Colors.red.shade700,
              onPressed: () => ref.read(authProvider.notifier).forceLogout(),
              tooltip: '[DEV] 강제 로그아웃',
              child: const Icon(Icons.logout, color: Colors.white, size: 18),
            )
          : null,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: currentTab,
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
    this.englishLabel,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String? englishLabel;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            topPadding + AppSpacing.verticalSm,
            AppSpacing.screenHorizontal,
            0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (englishLabel != null)
                      Text(
                        englishLabel!,
                        style: TextStyle(
                          color: AppColors.sectionLabel,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                        ),
                      ),
                    if (englishLabel != null) const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        const SizedBox(height: 12),
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
