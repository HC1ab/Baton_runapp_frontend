import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tab_registry.dart';

import '../../features/running/screens/running_screen.dart';
import '../../features/occupation/screens/occupation_screen.dart';
import '../../features/profile/screens/my_room_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/social/social_feed_screen.dart';
import '../../features/spot/screens/spot_screen.dart';

/// 앱 전체 탭 목록을 제공하는 provider.
/// HomeScreen은 이 provider만 watch하고 feature를 직접 import하지 않음.
final tabRegistryProvider = Provider<List<TabEntry>>((ref) {
  return [
    // Tab 0: Running
    const TabEntry(builder: _buildRunning),

    // Tab 1: Spot
    const TabEntry(builder: _buildSpot),

    // Tab 2: Occupation (점령)
    const TabEntry(builder: _buildOccupation),

    // Tab 3: Social
    const TabEntry(builder: _buildSocial),

    // Tab 4: My Room
    const TabEntry(builder: _buildMyRoom),

    // Tab 5: Profile
    const TabEntry(builder: _buildProfile),
  ];
});

Widget _buildMyRoom(BuildContext _) => const MyRoomScreen();

Widget _buildRunning(BuildContext _) => const RunningScreen();

Widget _buildSpot(BuildContext _) => const SpotScreen();

Widget _buildOccupation(BuildContext _) => const OccupationScreen();

Widget _buildSocial(BuildContext _) => const SocialFeedScreen();

Widget _buildProfile(BuildContext _) => const ProfileScreen();
