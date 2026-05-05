import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import 'tab_registry.dart';

// feature import는 shell_providers 에서만 — home은 이 provider만 바라봄
import '../../features/auth/providers/auth_provider.dart';
import '../../features/home/home_screen.dart';
import '../../features/running/screens/running_screen.dart';

/// 앱 전체 탭 목록을 제공하는 provider.
/// HomeScreen은 이 provider만 watch하고 feature를 직접 import하지 않음.
final tabRegistryProvider = Provider<List<TabEntry>>((ref) {
  return [
    // Tab 0: Running
    const TabEntry(builder: _buildRunning),

    // Tab 1: Spot
    const TabEntry(builder: _buildSpot),

    // Tab 2: Social
    const TabEntry(builder: _buildSocial),

    // Tab 3: Profile — logout 버튼이 필요해 Consumer로 래핑
    const TabEntry(builder: _buildProfile),
  ];
});

Widget _buildRunning(BuildContext _) => const RunningScreen();

Widget _buildSpot(BuildContext _) => const PlaceholderTab(
      icon: Icons.location_on_rounded,
      label: '스팟',
    );

Widget _buildSocial(BuildContext _) => const PlaceholderTab(
      icon: Icons.people_alt_rounded,
      label: '소셜',
    );

Widget _buildProfile(BuildContext _) => const _ProfileTab();

// ---------------------------------------------------------------------------
// Profile tab — logout 버튼 때문에 Consumer 사용
// ---------------------------------------------------------------------------

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PlaceholderTab(
      icon: Icons.person_rounded,
      label: '프로필',
      trailing: IconButton(
        icon: Icon(
          Icons.logout,
          size: 22,
          color: AppColors.textSecondary,
        ),
        onPressed: () => ref.read(authProvider.notifier).logout(),
        tooltip: '로그아웃',
      ),
    );
  }
}
