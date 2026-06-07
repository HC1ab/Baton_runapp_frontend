import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/widgets/character_sphere_widget.dart';
import '../../../core/character/character_style.dart';
import '../../social/models/follow_member_model.dart';
import '../../social/services/follow_service.dart';
import '../providers/friends_providers.dart';
import 'member_profile_screen.dart';
import '../services/member_profile_service.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const Color _primary = Color(0xFFDD6A3E);
  static const Color _bg = Color(0xFFF4F4F4);
  static const Color _textPrimary = Color(0xFF1F1A17);
  static const Color _textSub = Color(0xFF8C857F);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: _primary,
        ),
        title: const Text(
          '친구',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: _primary,
          unselectedLabelColor: _textSub,
          indicatorColor: _primary,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: '팔로워'),
            Tab(text: '팔로잉'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FollowerTab(primary: _primary, bg: _bg, textSub: _textSub),
          _FollowingTab(primary: _primary, bg: _bg, textSub: _textSub),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 팔로워 탭 — 맞팔 여부 판단 후 팔로우 신청 버튼 표시
// ---------------------------------------------------------------------------

class _FollowerTab extends ConsumerWidget {
  const _FollowerTab({
    required this.primary,
    required this.bg,
    required this.textSub,
  });

  final Color primary;
  final Color bg;
  final Color textSub;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followersAsync = ref.watch(followersProvider);
    final followingsAsync = ref.watch(followingsProvider);

    // followings 로딩 중이어도 팔로워 목록은 표시. followingIds만 비어있을 뿐.
    final followingIds = followingsAsync.whenOrNull(
          data: (list) => list.map((m) => m.memberId).toSet(),
        ) ??
        const <int>{};

    return RefreshIndicator(
      color: primary,
      onRefresh: () async {
        ref.invalidate(followersProvider);
        ref.invalidate(followingsProvider);
      },
      child: followersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFDD6A3E)),
        ),
        error: (e, _) => _buildError(
          ref,
          onRetry: () {
            ref.invalidate(followersProvider);
            ref.invalidate(followingsProvider);
          },
        ),
        data: (list) => list.isEmpty
            ? _buildEmpty('아직 팔로워가 없어요.')
            : ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final member = list[i];
                  final alreadyFollowing =
                      followingIds.contains(member.memberId);
                  return _FriendTile(
                    member: member,
                    trailingMode: alreadyFollowing
                        ? _TrailingMode.mutualBadge
                        : _TrailingMode.followButton,
                    onDelete: null,
                  );
                },
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 팔로잉 탭 — 삭제 가능
// ---------------------------------------------------------------------------

class _FollowingTab extends ConsumerWidget {
  const _FollowingTab({
    required this.primary,
    required this.bg,
    required this.textSub,
  });

  final Color primary;
  final Color bg;
  final Color textSub;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followingsAsync = ref.watch(followingsProvider);

    return RefreshIndicator(
      color: primary,
      onRefresh: () async => ref.invalidate(followingsProvider),
      child: followingsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFDD6A3E)),
        ),
        error: (e, _) => _buildError(
          ref,
          onRetry: () => ref.invalidate(followingsProvider),
        ),
        data: (list) => list.isEmpty
            ? _buildEmpty('팔로잉하는 친구가 없어요.')
            : ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                itemCount: list.length,
                itemBuilder: (context, i) => _FriendTile(
                  member: list[i],
                  trailingMode: _TrailingMode.deleteButton,
                  onDelete: () => _confirmDelete(context, ref, list[i]),
                ),
              ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    FollowMemberModel member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('팔로잉 삭제'),
        content: Text('${member.nickname}님을 팔로잉 목록에서 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFD64545)),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      await ref.read(followServiceProvider).deleteFollow(member.followId);
      ref.invalidate(followingsProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('삭제에 실패했어요. 다시 시도해주세요.')),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// trailing 모드
// ---------------------------------------------------------------------------

enum _TrailingMode { followButton, mutualBadge, deleteButton }

// ---------------------------------------------------------------------------
// 공통 친구 타일
// ---------------------------------------------------------------------------

class _FriendTile extends ConsumerStatefulWidget {
  const _FriendTile({
    required this.member,
    required this.trailingMode,
    required this.onDelete,
  });

  final FollowMemberModel member;
  final _TrailingMode trailingMode;
  final VoidCallback? onDelete;

  @override
  ConsumerState<_FriendTile> createState() => _FriendTileState();
}

class _FriendTileState extends ConsumerState<_FriendTile> {
  bool _requestSent = false;
  bool _requesting = false;

  static const Color _primary = Color(0xFFDD6A3E);
  static const Color _textSub = Color(0xFF8C857F);

  Future<void> _sendFollowRequest() async {
    if (_requesting || _requestSent) return;
    setState(() => _requesting = true);

    try {
      await ref
          .read(followServiceProvider)
          .sendRequest(widget.member.nickname);
      if (!mounted) return;
      setState(() {
        _requesting = false;
        _requestSent = true;
      });
      // followings 목록 갱신 — 신청 수락 전이므로 실제 반영은 수락 후
      ref.invalidate(followingsProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() => _requesting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('팔로우 신청에 실패했어요. 다시 시도해주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorAsync =
        ref.watch(memberColorCodeProvider(widget.member.memberId));
    final colorCode = colorAsync.when(
      data: (c) => c ?? 'CORE_ORANGE',
      loading: () => 'CORE_ORANGE',
      error: (_, __) => 'CORE_ORANGE',
    );
    final style = CharacterStylePresets.fromCode(colorCode);

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
      leading: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                MemberProfileScreen(nickname: widget.member.nickname),
          ),
        ),
        child: CharacterSphereWidget(style: style, size: 44.r),
      ),
      title: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                MemberProfileScreen(nickname: widget.member.nickname),
          ),
        ),
        child: Text(
          widget.member.nickname,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F1A17),
          ),
        ),
      ),
      trailing: _buildTrailing(),
    );
  }

  Widget? _buildTrailing() {
    switch (widget.trailingMode) {
      case _TrailingMode.deleteButton:
        return IconButton(
          onPressed: widget.onDelete,
          icon: const Icon(Icons.person_remove_rounded),
          color: _textSub,
          tooltip: '팔로잉 삭제',
        );

      case _TrailingMode.mutualBadge:
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            '맞팔',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: _primary,
            ),
          ),
        );

      case _TrailingMode.followButton:
        if (_requestSent) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              '신청됨',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: _textSub,
              ),
            ),
          );
        }
        return _requesting
            ? SizedBox(
                width: 20.r,
                height: 20.r,
                child: const CircularProgressIndicator(
                  color: _primary,
                  strokeWidth: 2,
                ),
              )
            : TextButton(
                onPressed: _sendFollowRequest,
                style: TextButton.styleFrom(
                  foregroundColor: _primary,
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.r),
                    side: const BorderSide(color: _primary),
                  ),
                  textStyle: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('팔로우'),
              );
    }
  }
}

// ---------------------------------------------------------------------------
// 공통 헬퍼
// ---------------------------------------------------------------------------

Widget _buildError(WidgetRef ref, {required VoidCallback onRetry}) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '목록을 불러오지 못했어요.',
          style: TextStyle(color: Color(0xFF8C857F), fontSize: 14),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDD6A3E),
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

Widget _buildEmpty(String message) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.people_outline_rounded,
          size: 48,
          color: Color(0xFFCCCCCC),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          style: const TextStyle(
            color: Color(0xFF8C857F),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}
