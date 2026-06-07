import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/character_sphere_widget.dart';
import '../../../core/character/character_style.dart';
import '../../social/services/follow_service.dart';
import '../models/member_profile_model.dart';
import '../services/member_profile_service.dart';

class MemberProfileScreen extends ConsumerWidget {
  const MemberProfileScreen({super.key, required this.nickname});

  final String nickname;

  static const Color _bg = Color(0xFFFBF1EC);
  static const Color _primary = Color(0xFFDD6A3E);
  static const Color _textPrimary = Color(0xFF1F1A17);
  static const Color _textSub = Color(0xFF8C857F);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(memberProfileProvider(nickname));

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: _primary,
        ),
        title: const Text(
          '멤버 프로필',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: _primary),
          ),
          error: (e, _) => _buildError(ref),
          data: (profile) => _buildBody(context, ref, profile),
        ),
      ),
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
            onPressed: () => ref.invalidate(memberProfileProvider(nickname)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('다시 시도', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, MemberProfileModel profile) {
    return RefreshIndicator(
      color: _primary,
      onRefresh: () async => ref.invalidate(memberProfileProvider(nickname)),
      child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        const SizedBox(height: 12),
        _buildHeroAvatar(ref, profile.memberId),
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
        const SizedBox(height: 4),
        Text(
          profile.equippedTitleName.isEmpty
              ? 'No Title'
              : profile.equippedTitleName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            color: _primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _FollowSection(profile: profile),
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
      ],
      ),
    );
  }

  Widget _buildHeroAvatar(WidgetRef ref, int memberId) {
    final colorAsync = ref.watch(memberColorCodeProvider(memberId));
    final colorCode = colorAsync.when(
      data: (c) => c ?? 'CORE_ORANGE',
      loading: () => 'CORE_ORANGE',
      error: (_, __) => 'CORE_ORANGE',
    );
    return Center(
      child: CharacterSphereWidget(
        style: CharacterStylePresets.fromCode(colorCode),
        size: 120,
      ),
    );
  }

  Widget _buildLevelCard(int level) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
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
// _FollowSection — relationStatus별 UI 분기
// ---------------------------------------------------------------------------

class _FollowSection extends ConsumerStatefulWidget {
  const _FollowSection({required this.profile});
  final MemberProfileModel profile;

  @override
  ConsumerState<_FollowSection> createState() => _FollowSectionState();
}

class _FollowSectionState extends ConsumerState<_FollowSection> {
  bool _isLoading = false;

  static const Color _primary = Color(0xFFDD6A3E);

  Future<void> _sendFollowRequest() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(followServiceProvider)
          .sendRequest(widget.profile.nickname);
      ref.invalidate(memberProfileProvider(widget.profile.nickname));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('팔로우 신청 중 오류가 발생했어요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRequest(Future<void> Function() action) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await action();
      ref.invalidate(memberProfileProvider(widget.profile.nickname));
      ref.invalidate(pendingFollowRequestsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('처리 중 오류가 발생했어요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: _primary),
        ),
      );
    }

    switch (widget.profile.relationStatus) {
      case RelationStatus.none:
        return Center(
          child: FilledButton.icon(
            onPressed: _sendFollowRequest,
            icon: const Icon(Icons.person_add_rounded, size: 18),
            label: const Text('팔로우 신청'),
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );

      case RelationStatus.pendingSent:
        return Center(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule_rounded, size: 16, color: Color(0xFF999999)),
                SizedBox(width: 6),
                Text(
                  '신청 보냄',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
        );

      case RelationStatus.pendingReceived:
        return _PendingReceivedActions(
          nickname: widget.profile.nickname,
          onHandle: _handleRequest,
        );

      case RelationStatus.friend:
        return Center(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded,
                    size: 16, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  '친구',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }
}

// PENDING_RECEIVED: requests 목록에서 followId 찾아 수락/거절 버튼 표시
class _PendingReceivedActions extends ConsumerWidget {
  const _PendingReceivedActions({
    required this.nickname,
    required this.onHandle,
  });

  final String nickname;
  final Future<void> Function(Future<void> Function()) onHandle;

  static const Color _primary = Color(0xFFDD6A3E);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(pendingFollowRequestsProvider);

    return requestsAsync.when(
      loading: () => const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
        ),
      ),
      error: (_, __) => const Center(
        child: Text(
          '신청 정보를 불러오지 못했어요.',
          style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
        ),
      ),
      data: (requests) {
        final matched = requests.where((r) => r.nickname == nickname).toList();
        if (matched.isEmpty) {
          return const Center(
            child: Text(
              '신청 정보를 찾을 수 없어요.',
              style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
            ),
          );
        }
        final followId = matched.first.followId;
        final service = ref.read(followServiceProvider);
        return Center(
          child: Column(
            children: [
              const Text(
                '이 멤버가 팔로우를 신청했어요.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF8C857F),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton(
                    onPressed: () =>
                        onHandle(() => service.accept(followId)),
                    style: FilledButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('수락'),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () =>
                        onHandle(() => service.reject(followId)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF666666),
                      side: const BorderSide(color: Color(0xFFCCCCCC)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('거절'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
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
        color: const Color(0xFFFBF1EC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEBD9CC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFDD6A3E), size: 22),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF8C857F),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F1A17),
            ),
          ),
        ],
      ),
    );
  }
}
