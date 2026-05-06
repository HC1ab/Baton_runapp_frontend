import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tab_registry.dart';

import '../../features/home/home_screen.dart';
import '../../features/running/screens/running_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/social/screens/social_group_running_screen.dart';

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

    // Tab 3: Profile
    const TabEntry(builder: _buildProfile),
  ];
});

Widget _buildRunning(BuildContext _) => const RunningScreen();

Widget _buildSpot(BuildContext _) => const PlaceholderTab(
      icon: Icons.location_on_rounded,
      label: '스팟',
    );

Widget _buildSocial(BuildContext _) => const SocialGroupRunningScreen();

Widget _buildProfile(BuildContext _) => const ProfileScreen();
