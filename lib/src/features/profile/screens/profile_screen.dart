import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../common/widgets/character_sphere_widget.dart';
import '../../../common/widgets/notification_bell_widget.dart';
import '../../../common/widgets/rarity_title_badge.dart';
import '../../../core/character/character_provider.dart';
import '../../../core/character/character_style.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/myroom/my_room_service.dart';
import '../../../core/shell/tab_providers.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/profile_service.dart';

/// ProfileScreen — 프로필 탭: API 기반 닉네임/타이틀/레벨/러닝 통계 표시 + 로그아웃 버튼.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const Color _bg = AppColors.dScreen;
  static const Color _primary = AppColors.dAccent;
  static const Color _cardLight = AppColors.dCard;
  static const Color _textPrimary = AppColors.dText;
  static const Color _textSub = AppColors.dMuted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final characterStyle = ref.watch(selectedCharacterStyleProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: _primary),
          ),
          error: (e, _) => _buildError(ref),
          data: (profile) => ListView(
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 140.h),
            children: [
              _buildAppBar(context, ref),
              const SizedBox(height: 12),
              _buildHeroAvatar(characterStyle),
              const SizedBox(height: 20),
              Text(
                profile.nickname,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              _buildEquippedTitleBadge(ref, profile.equippedTitleName),
              const SizedBox(height: 20),
              _buildLevelCard(profile.level),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.straighten_rounded,
                      label: '총 거리',
                      value: '${profile.totalDistance.toStringAsFixed(1)} km',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.speed_rounded,
                      label: '평균 페이스',
                      value: profile.avgPaceText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _BigActionCard(
                      icon: Icons.emoji_events_rounded,
                      title: '러닝 히스토리',
                      subtitle: '레벨 혜택 및 기록',
                      filled: true,
                      onTap: () => context.push(AppRoutes.history),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BigActionCard(
                      icon: Icons.place_rounded,
                      title: '나의 스팟',
                      subtitle: '저장된 코스 확인',
                      filled: false,
                      onTap: () => ref
                          .read(currentTabProvider.notifier)
                          .switchTo(AppTabs.spot),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _BigActionCard(
                icon: Icons.people_rounded,
                title: '친구',
                subtitle: '팔로워 · 팔로잉 관리',
                filled: false,
                onTap: () => context.push(AppRoutes.friends),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEquippedTitleBadge(WidgetRef ref, String equippedTitleName) {
    if (equippedTitleName.isEmpty) {
      return Text(
        'No Title',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 15,
          color: _primary,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final rarity = ref.watch(myRoomProvider).maybeWhen(
          data: (myRoom) => myRoom.titles
              .cast<MyRoomTitleItem?>()
              .firstWhere(
                (t) => t?.name == equippedTitleName,
                orElse: () => null,
              )
              ?.rarity,
          orElse: () => null,
        ) ??
        'NORMAL';

    return RarityTitleBadge(
      title: equippedTitleName,
      rarity: rarity,
      fontSize: 15,
    );
  }

  Widget _buildError(WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '프로필을 불러오지 못했어요.',
            style: TextStyle(color: _textSub, fontSize: 14),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => ref.invalidate(profileProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('다시 시도',
                style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            child: const Text('로그아웃', style: TextStyle(color: _textSub)),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 18,
          backgroundColor: _primary,
          child: Icon(Icons.person, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        const Text(
          'Baton',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: _primary,
            letterSpacing: -0.5,
          ),
        ),
        const Spacer(),
        const NotificationBellWidget(),
        SizedBox(width: 4.w),
        IconButton(
          onPressed: () => context.push(AppRoutes.settings),
          icon: const Icon(Icons.settings_rounded, color: _primary, size: 24),
          tooltip: '설정',
        ),
      ],
    );
  }

  Widget _buildHeroAvatar(CharacterStyle style) {
    return Center(
      child: CharacterSphereWidget(
        style: style,
        size: 180.r,
      ),
    );
  }

  Widget _buildLevelCard(int level) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: _cardLight,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.dLine, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '러닝 레벨',
            style: TextStyle(
              fontSize: 14,
              color: _textSub,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Lv.$level',
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: _primary,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared Sub-widgets
// ---------------------------------------------------------------------------

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.dCard2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.dLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.dAccent, size: 22),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.dMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.dText,
            ),
          ),
        ],
      ),
    );
  }
}

class _BigActionCard extends StatelessWidget {
  const _BigActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.filled,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const Color primary = AppColors.dAccent;
    const Color cardSoft = AppColors.dCard2;
    const Color textSub = AppColors.dMuted;

    final bg = filled ? primary : cardSoft;
    final fg = filled ? const Color(0xFF1A0E06) : AppColors.dText;
    final subFg =
        filled ? const Color(0xFF1A0E06).withValues(alpha: 0.75) : textSub;
    final iconBg = filled
        ? Colors.white.withValues(alpha: 0.22)
        : AppColors.dAccent.withValues(alpha: 0.14);
    final iconColor = filled ? const Color(0xFF1A0E06) : primary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
          border: filled
              ? null
              : Border.all(color: AppColors.dLine, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: subFg,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
