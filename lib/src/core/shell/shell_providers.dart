import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tab_registry.dart';

import '../../features/running/screens/running_screen.dart';
import '../../features/occupation/screens/occupation_screen.dart';
import '../../features/ghost/screens/ghost_ranking_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/social/social_feed_screen.dart';

/// 앱 전체 탭 목록을 제공하는 provider.
/// HomeScreen은 이 provider만 watch하고 feature를 직접 import하지 않음.
/// (스팟·마이룸은 하단 탭에서 제외 — 프로필 화면에서 push로 진입)
final tabRegistryProvider = Provider<List<TabEntry>>((ref) {
  return [
    // Tab 0: Running
    const TabEntry(builder: _buildRunning),

    // Tab 1: Occupation (점령 + 스팟)
    const TabEntry(builder: _buildOccupation),

    // Tab 2: Ghost (고스트)
    const TabEntry(builder: _buildGhost),

    // Tab 3: Social
    const TabEntry(builder: _buildSocial),

    // Tab 4: Profile
    const TabEntry(builder: _buildProfile),
  ];
});

Widget _buildRunning(BuildContext _) => const RunningScreen();

Widget _buildOccupation(BuildContext _) => const OccupationScreen();

Widget _buildGhost(BuildContext _) => const GhostRankingScreen();

Widget _buildSocial(BuildContext _) => const SocialFeedScreen();

Widget _buildProfile(BuildContext _) => const ProfileScreen();
