import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/widgets/character_sphere_widget.dart';
import '../../../core/character/character_style.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/follow/providers/follow_providers.dart';
import '../../../core/utils/app_snack_bar.dart';
import '../models/member_profile_model.dart';
import '../services/member_profile_service.dart';

class MemberProfileScreen extends ConsumerWidget {
  const MemberProfileScreen({super.key, required this.nickname});

  final String nickname;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(memberProfileProvider(nickname));

    return Scaffold(
      backgroundColor: AppColors.dScreen,
      appBar: AppBar(
        backgroundColor: AppColors.dScreen,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.r),
          color: AppColors.dAccent,
        ),
        title: Text(
          '멤버 프로필',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.dText,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: AppColors.primary),
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
          Text(
            '프로필을 불러오지 못했어요.',
            style: TextStyle(color: AppColors.dMuted, fontSize: 14.sp),
          ),
          SizedBox(height: 12.h),
          ElevatedButton(
            onPressed: () => ref.invalidate(memberProfileProvider(nickname)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
      color: AppColors.primary,
      onRefresh: () async => ref.invalidate(memberProfileProvider(nickname)),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          AppSpacing.sm,
          AppSpacing.screenHorizontal,
          28.h,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          switch (index) {
            case 0:
              return SizedBox(height: 12.h);
            case 1:
              return _buildHeroAvatar(ref, profile.memberId);
            case 2:
              return Padding(
                padding: EdgeInsets.only(top: 20.h),
                child: Column(
                  children: [
                    Text(
                      profile.nickname,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.dText,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      profile.equippedTitleName.isEmpty
                          ? 'No Title'
                          : profile.equippedTitleName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            case 3:
              return Padding(
                padding: EdgeInsets.only(top: 16.h),
                child: _FollowSection(profile: profile),
              );
            case 4:
              return Padding(
                padding: EdgeInsets.only(top: 20.h),
                child: _buildLevelCard(profile.level),
              );
            case 5:
              return Padding(
                padding: EdgeInsets.only(top: 14.h),
                child: Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.straighten_rounded,
                        label: '총 거리',
                        value: '${profile.totalDistance.toStringAsFixed(1)} km',
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.speed_rounded,
                        label: '평균 페이스',
                        value: profile.avgPaceText,
                      ),
                    ),
                  ],
                ),
              );
            default:
              return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  Widget _buildHeroAvatar(WidgetRef ref, int memberId) {
    final colorAsync = ref.watch(memberColorCodeProvider(memberId));
    final colorCode = colorAsync.when(
      data: (c) => c ?? 'CORE_ORANGE',
      loading: () => 'CORE_ORANGE',
      error: (_, _) => 'CORE_ORANGE',
    );
    return Center(
      child: CharacterSphereWidget(
        style: CharacterStylePresets.fromCode(colorCode),
        size: 120.r,
      ),
    );
  }

  Widget _buildLevelCard(int level) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 20.h),
      decoration: BoxDecoration(
        color: AppColors.dCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.dLine, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '러닝 레벨',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.dMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Lv.$level',
            style: TextStyle(
              fontSize: 38.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
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

  /// pendingSent 상태에서 신청 취소에 필요한 followId
  /// sendRequest() 응답에서 저장
  String? _pendingFollowId;

  Future<void> _sendFollowRequest() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final followId = await ref
          .read(followServiceProvider)
          .sendRequest(widget.profile.nickname);
      if (followId.isNotEmpty) {
        _pendingFollowId = followId;
      }
      ref.invalidate(memberProfileProvider(widget.profile.nickname));
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, '팔로우 신청 중 오류가 발생했어요.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelFollowRequest() async {
    if (_isLoading) return;
    final followId = _pendingFollowId;
    if (followId == null || followId.isEmpty) {
      // followId 없으면 취소 불가 안내
      if (mounted) {
        AppSnackBar.error(context, '앱을 재시작한 뒤 다시 시도해주세요.');
      }
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(followServiceProvider).deleteFollow(followId);
      _pendingFollowId = null;
      ref.invalidate(memberProfileProvider(widget.profile.nickname));
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, '신청 취소 중 오류가 발생했어요.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteFollow() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      // followId는 followings(내가 팔로우) OR followers(나를 팔로우) 어느 쪽에든 있을 수 있음.
      // OpenAPI: DELETE /follows/{followId} — 양쪽 모두 사용 가능.
      final followId = await _resolveFollowId();
      if (followId == null) {
        if (mounted) {
          AppSnackBar.error(context, '팔로우 정보를 찾을 수 없어요.');
        }
        return;
      }
      await ref.read(followServiceProvider).deleteFollow(followId);
      ref.invalidate(followingsProvider);
      ref.invalidate(followersProvider);
      ref.invalidate(memberProfileProvider(widget.profile.nickname));
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, '팔로우 삭제 중 오류가 발생했어요.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// followings → followers 순서로 nickname 매칭해 followId 반환.
  /// 둘 다 없으면 강제 새로고침 후 재시도. 그래도 없으면 null.
  Future<String?> _resolveFollowId() async {
    final nickname = widget.profile.nickname;

    String? findIn(List list) {
      for (final m in list) {
        if (m.nickname == nickname) return m.followId as String;
      }
      return null;
    }

    final followings = await ref.read(followingsProvider.future);
    final id1 = findIn(followings);
    if (id1 != null) return id1;

    final followers = await ref.read(followersProvider.future);
    final id2 = findIn(followers);
    if (id2 != null) return id2;

    // 캐시 miss 가능성 → 강제 새로고침
    ref.invalidate(followingsProvider);
    ref.invalidate(followersProvider);

    final freshFollowings = await ref.read(followingsProvider.future);
    final id3 = findIn(freshFollowings);
    if (id3 != null) return id3;

    final freshFollowers = await ref.read(followersProvider.future);
    return findIn(freshFollowers);
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
        AppSnackBar.error(context, '처리 중 오류가 발생했어요.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: SizedBox(
          width: 24.r,
          height: 24.r,
          child: CircularProgressIndicator(
              strokeWidth: 2.5, color: AppColors.primary),
        ),
      );
    }

    // 백엔드 follow는 대칭 시스템:
    //   A→B ACCEPTED 후 B→A 신청 시 400 ("이미 관계가 있음")
    //   → effectiveStatus는 항상 서버 값 신뢰 (none 오버라이드 제거 — 팔로우 신청 400 유발)
    //   → iActuallyFollow / theyFollowMe 는 FRIEND 케이스 배지 라벨 구분용으로만 사용.
    final followingsAsync = ref.watch(followingsProvider);
    final followersAsync = ref.watch(followersProvider);

    final iActuallyFollow = followingsAsync.whenOrNull(
          data: (list) =>
              list.any((m) => m.memberId == widget.profile.memberId),
        ) ??
        false;
    final theyFollowMe = followersAsync.whenOrNull(
          data: (list) =>
              list.any((m) => m.memberId == widget.profile.memberId),
        ) ??
        false;

    // 서버 값 그대로 사용 — 절대 none으로 강제 변환하지 않음
    final effectiveStatus = widget.profile.relationStatus;

    switch (effectiveStatus) {
      // ── 관계 없음 → 팔로우 신청 ──────────────────────────────────────────
      case RelationStatus.none:
        return Center(
          child: FilledButton.icon(
            onPressed: _sendFollowRequest,
            icon: Icon(Icons.person_add_rounded, size: 18.r),
            label: const Text('팔로우 신청'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              textStyle: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700),
            ),
          ),
        );

      // ── 신청 보냄 → 신청 취소 ────────────────────────────────────────────
      case RelationStatus.pendingSent:
        return Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: AppColors.dCard2,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 16.r, color: AppColors.dMuted),
                    SizedBox(width: 6.w),
                    Text(
                      '신청 보냄',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dMuted,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              OutlinedButton(
                onPressed: _pendingFollowId != null
                    ? _cancelFollowRequest
                    : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error),
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  textStyle:
                      TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
                ),
                child: const Text('신청 취소'),
              ),
            ],
          ),
        );

      // ── 신청 받음 → 수락 / 거절 ──────────────────────────────────────────
      case RelationStatus.pendingReceived:
        return _PendingReceivedActions(
          nickname: widget.profile.nickname,
          onHandle: _handleRequest,
        );

      // ── 친구 → 팔로잉/팔로워 배지 + 삭제 ──────────────────────────────
      // 백엔드 FRIEND = 수락된 팔로우 관계 (대칭 처리)
      // iActuallyFollow=true  → 내가 팔로우 중 → "팔로잉" / "맞팔"
      // theyFollowMe=true     → 상대가 나를 팔로우 중 → "팔로워"
      // 둘 다 false = 캐시 로딩 중 → "팔로잉"(서버 FRIEND 신뢰)
      case RelationStatus.friend:
        final badgeLabel = iActuallyFollow
            ? (theyFollowMe ? '맞팔' : '팔로잉')
            : theyFollowMe
                ? '팔로워'
                : '팔로잉';
        return Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 16.r, color: Colors.white),
                    SizedBox(width: 6.w),
                    Text(
                      badgeLabel,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              OutlinedButton(
                onPressed: _deleteFollow,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.dMuted,
                  side: BorderSide(color: AppColors.dLine2),
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  textStyle:
                      TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
                ),
                child: const Text('삭제'),
              ),
            ],
          ),
        );
    }
  }
}

// ---------------------------------------------------------------------------
// _PendingReceivedActions — 받은 신청 수락/거절
// ---------------------------------------------------------------------------

class _PendingReceivedActions extends ConsumerWidget {
  const _PendingReceivedActions({
    required this.nickname,
    required this.onHandle,
  });

  final String nickname;
  final Future<void> Function(Future<void> Function()) onHandle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(pendingFollowRequestsProvider);

    return requestsAsync.when(
      loading: () => Center(
        child: SizedBox(
          width: 20.r,
          height: 20.r,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.primary),
        ),
      ),
      error: (_, _) => Center(
        child: Text(
          '신청 정보를 불러오지 못했어요.',
          style: TextStyle(fontSize: 13.sp, color: AppColors.dMuted),
        ),
      ),
      data: (requests) {
        final matched =
            requests.where((r) => r.nickname == nickname).toList();
        if (matched.isEmpty) {
          return Center(
            child: Text(
              '신청 정보를 찾을 수 없어요.',
              style:
                  TextStyle(fontSize: 13.sp, color: AppColors.dMuted),
            ),
          );
        }
        final followId = matched.first.followId;
        final service = ref.read(followServiceProvider);
        return Center(
          child: Column(
            children: [
              Text(
                '이 멤버가 팔로우를 신청했어요.',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.dMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 10.h),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton(
                    onPressed: () =>
                        onHandle(() => service.accept(followId)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.w, vertical: 10.h),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd)),
                      textStyle: TextStyle(
                          fontSize: 14.sp, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('수락'),
                  ),
                  SizedBox(width: 10.w),
                  OutlinedButton(
                    onPressed: () =>
                        onHandle(() => service.reject(followId)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.dMuted,
                      side: BorderSide(color: AppColors.dLine2),
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.w, vertical: 10.h),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd)),
                      textStyle: TextStyle(
                          fontSize: 14.sp, fontWeight: FontWeight.w700),
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
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: AppColors.dCard2,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.dLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 22.r),
          SizedBox(height: 12.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.dMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.dText,
            ),
          ),
        ],
      ),
    );
  }
}
