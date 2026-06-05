import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:logger/logger.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/error_messages.dart';
import '../../core/constants/storage_keys.dart';
import '../../core/network/api_client.dart';
import '../../core/shell/tab_providers.dart';
import '../../core/storage/shared_prefs_provider.dart';
import '../../core/storage/token_storage.dart';
import '../../core/utils/jwt_utils.dart';
import '../group_running/providers/run_location_provider.dart';
import 'active_room_screen.dart';
import 'create_room_screen.dart';
import 'models/run_card_data.dart';
import 'room_detail_screen.dart';
import 'social_providers.dart';
import 'widgets/group_run_card.dart';

final _logger = Logger();

class SocialFeedScreen extends ConsumerStatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  ConsumerState<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends ConsumerState<SocialFeedScreen> {
  List<RunCardData> _cards = const [];
  bool _isLoading = false;
  String? _loadError;
  int? _myMemberId;

  static const Color _pointOrange = AppColors.socialAccent;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCards());
  }

  /// 서버에서 그룹 목록을 가져와 정렬한다.
  /// 내가 만든 방 / 참여 중인 방 → 맨 위로 고정.
  Future<void> _loadCards() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      // 내 memberId — JWT에서 디코드. 없으면 null로 진행.
      final pair = await ref.read(tokenStorageProvider).read();
      final token = pair?.accessToken;
      _myMemberId =
          (token != null && token.isNotEmpty) ? memberIdFromAccessToken(token) : null;

      final prefs = ref.read(sharedPreferencesProvider);
      final myNickname = prefs.getString(StorageKeys.myNickname);
      _logger.i('[SocialFeed] _loadCards() start — myMemberId=$_myMemberId myNickname=$myNickname');
      final raw = await ref.read(groupApiProvider).list();
      _logger.i('[SocialFeed] raw group list (${raw.length}): $raw');
      final cards = raw
          .map((e) => RunCardData.fromServerJson(e, myMemberId: _myMemberId, myNickname: myNickname))
          .toList();
      _logger.i('[SocialFeed] parsed cards: ${cards.map((c) => 'id=${c.groupId} isHost=${c.isHost} isParticipating=${c.isParticipating}').toList()}');

      // 정렬: host > participating > 일반.
      cards.sort((a, b) {
        int rank(RunCardData c) {
          if (c.isHost) return 0;
          if (c.isParticipating) return 1;
          return 2;
        }
        return rank(a).compareTo(rank(b));
      });

      if (!mounted) return;
      setState(() {
        _cards = cards;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      _logger.w('group list failed', error: e);
      if (!mounted) return;
      setState(() {
        _loadError = formatApiErrorMessage(e);
        _isLoading = false;
      });
    } catch (e) {
      _logger.e('group list unexpected error', error: e);
      if (!mounted) return;
      setState(() {
        _loadError = ErrorMessages.unknownError;
        _isLoading = false;
      });
    }
  }

  Future<void> _openCreateScreen() async {
    final created = await Navigator.of(context).push<RunCardData>(
      MaterialPageRoute<RunCardData>(
        builder: (_) => const CreateRoomScreen(),
      ),
    );
    if (!mounted) return;
    if (created != null) {
      // 목록 갱신 후 생성한 방으로 바로 입장.
      await _loadCards();
      if (!mounted) return;
      // 생성 직후 isHost 보장
      _openLiveRun(created.copyWith(isHost: true));
    }
  }

  void _openLiveRun(RunCardData card) {
    final groupId = card.groupId;
    if (groupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아직 서버 그룹 ID가 없는 데이터입니다.')),
      );
      return;
    }
    // 호스트면 activeHostGroupIdProvider 저장 (로그아웃 시 방 삭제용)
    if (card.isHost) {
      ref.read(activeHostGroupIdProvider.notifier).set(groupId);
    }
    // RunningScreen(Tab 0)에 그룹 진입 요청 후 탭 전환
    ref.read(pendingGroupJoinProvider.notifier).request(
          (groupId: groupId, isHost: card.isHost),
        );
    ref.read(currentTabProvider.notifier).switchTo(AppTabs.running);
  }

  Future<void> _joinGroup(RunCardData card, {bool enterLiveAfter = false}) async {
    final groupId = card.groupId;
    if (groupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아직 서버 그룹 ID가 없는 데이터입니다.')),
      );
      return;
    }
    try {
      await ref.read(groupApiProvider).join(groupId: groupId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('그룹 참여가 완료됐습니다.')),
      );
      // 서버 기준으로 정렬/하이라이트 다시 계산.
      await _loadCards();
      if (enterLiveAfter && mounted) {
        // 갱신된 목록에서 동일 groupId 카드를 찾아 진입.
        final fresh = _cards.firstWhere(
          (c) => c.groupId == groupId,
          orElse: () => card.copyWith(isParticipating: true),
        );
        _openLiveRun(fresh);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(formatApiErrorMessage(e))),
      );
    }
  }

  Future<void> _leaveGroup(RunCardData card) async {
    final groupId = card.groupId;
    if (groupId == null) return;
    try {
      await ref.read(groupApiProvider).leave(groupId: groupId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('그룹에서 나갔습니다.')),
      );
      await _loadCards();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(formatApiErrorMessage(e))),
      );
    }
  }

  Future<void> _deleteGroup(RunCardData card) async {
    final groupId = card.groupId;
    if (groupId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('그룹 삭제'),
        content: const Text('정말 이 그룹을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(groupApiProvider).delete(groupId: groupId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('그룹이 삭제됐습니다.')),
      );
      Navigator.of(context).maybePop();
      await _loadCards();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(formatApiErrorMessage(e))),
      );
    }
  }

  Future<void> _updateGroup(RunCardData card) async {
    final groupId = card.groupId;
    if (groupId == null) return;
    final controller = TextEditingController(text: card.maxMembers.toString());
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('그룹 수정'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '최대 인원',
            hintText: '예: 6',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              Navigator.of(context).pop(parsed);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
    if (value == null || value < 2 || value > 30 || !mounted) {
      if (value != null && mounted && (value < 2 || value > 30)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('최대 인원은 2~30명으로 입력해 주세요.')),
        );
      }
      return;
    }
    try {
      await ref.read(groupApiProvider).update(
            groupId: groupId,
            maxParticipants: value,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('그룹 정보가 수정됐습니다.')),
      );
      await _loadCards();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(formatApiErrorMessage(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 활성 그룹 러닝 세션 — 피드 대신 전용 화면 표시
    final locState = ref.watch(runLocationProvider);
    if (locState.isConnected && locState.groupId != null) {
      final activeGroupId = locState.groupId!;
      final card = _cards.where((c) => c.groupId == activeGroupId).firstOrNull;

      if (card == null) {
        // 카드 아직 로딩 중
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      return ActiveRoomScreen(
        card: card,
        onUpdatePressed: () => _updateGroup(card),
        onDeletePressed: () => _deleteGroup(card),
        onLeavePressed: () => _leaveGroup(card),
      );
    }

    // 일반 피드
    final cards = _cards;

    return Scaffold(
      backgroundColor: AppColors.scaffoldGrey,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.verticalSm,
            AppSpacing.screenHorizontal,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'COMMUNITY FEED',
                          style: TextStyle(
                            color: AppColors.sectionLabel,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '소셜',
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
                  Icon(Icons.notifications_rounded, color: AppColors.iconNeutral, size: 22.r),
                  SizedBox(width: 12.w),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.avatarTeal,
                    child: Icon(Icons.person_rounded, color: Colors.white, size: 18.r),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: RefreshIndicator(
                  color: _pointOrange,
                  onRefresh: _loadCards,
                  child: _buildBody(cards),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _isLoading && _cards.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _openCreateScreen,
              backgroundColor: _pointOrange,
              foregroundColor: Colors.white,
              elevation: 2,
              icon: const Icon(Icons.edit),
              label: const Text('+ 모집하기'),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // 외부 HomeScreen 네브바 높이를 내부 Scaffold에 알려줌 → FAB이 네브바 위에 배치됨
      bottomNavigationBar: SizedBox(
        height: 115.h + MediaQuery.of(context).viewPadding.bottom,
      ),
    );
  }

  /// 로딩 / 에러 / 빈 상태 / 정상 목록을 분기.
  /// RefreshIndicator는 스크롤 가능한 자식이 필요하므로 모든 분기에서
  /// AlwaysScrollableScrollPhysics를 가진 ListView/SingleChildScrollView를
  /// 반환한다.
  Widget _buildBody(List<RunCardData> cards) {
    if (_isLoading && cards.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator(color: _pointOrange)),
        ],
      );
    }

    if (_loadError != null && cards.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 40.r, color: Colors.black38),
                  const SizedBox(height: 12),
                  Text(
                    _loadError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _loadCards,
                    child: const Text('다시 시도', style: TextStyle(color: _pointOrange)),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (cards.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Icon(Icons.directions_run_rounded, size: 48.r, color: Colors.black26),
                  SizedBox(height: 12),
                  Text(
                    '아직 모집 중인 그룹이 없어요.\n+ 모집하기 버튼으로 첫 방을 열어보세요!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        // 내가 만든 방 / 참여 중인 방은 강조 색상 적용.
        final isMine = card.isHost || card.isParticipating;
        return Padding(
          padding: EdgeInsets.only(
            top: index == 0 ? 0 : 14,
            bottom: index == cards.length - 1
                ? MediaQuery.of(context).padding.bottom + 90
                : 0,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RoomDetailScreen(
                      card: card,
                      onJoinPressed: () => _joinGroup(card, enterLiveAfter: true),
                      onEnterLivePressed: () => _openLiveRun(card),
                      onLeavePressed: () => _leaveGroup(card),
                      onUpdatePressed: () => _updateGroup(card),
                      onDeletePressed: () => _deleteGroup(card),
                    ),
                  ),
                ).then((_) => _loadCards());
              },
              child: GroupRunCard(
                title: card.title,
                time: card.time,
                location: card.location,
                currentMembers: card.currentMembers,
                maxMembers: card.maxMembers,
                isHighlighted: isMine,
                participantImageUrls: card.participantImageUrls,
                onJoinPressed: isMine ? null : () => _joinGroup(card),
              ),
            ),
          ),
        );
      },
    );
  }
}
