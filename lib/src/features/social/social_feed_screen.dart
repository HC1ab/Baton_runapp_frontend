import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../../core/utils/jwt_utils.dart';
import '../group_running/screens/group_run_live_screen.dart';
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

  static const Color _pointOrange = Color(0xFFF7673B);

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

      final raw = await ref.read(groupApiProvider).list();
      final cards = raw
          .map((e) => RunCardData.fromServerJson(e, myMemberId: _myMemberId))
          .toList();

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
        _loadError = '목록을 불러오지 못했습니다.';
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
    // 생성 후에는 항상 서버 목록을 다시 fetch (test1 만든 방을 test2 도 보게).
    if (created != null) {
      await _loadCards();
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
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GroupRunLiveScreen(card: card),
      ),
    );
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
    final cards = _cards;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F4F4),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: const Text(
          '바통',
          style: TextStyle(
            color: _pointOrange,
            fontSize: 34 / 2,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_rounded, color: Color(0xFF555555)),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF1F7E8A),
              child: Icon(Icons.person_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text(
                'COMMUNITY FEED',
                style: TextStyle(
                  color: Color(0xFF8F2E1A),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '소셜',
                style: TextStyle(
                  color: Color(0xFF1F1F1F),
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
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
                  const Icon(Icons.error_outline, size: 40, color: Colors.black38),
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
        children: const [
          SizedBox(height: 120),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Icon(Icons.directions_run_rounded, size: 48, color: Colors.black26),
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
            bottom: index == cards.length - 1 ? 120 : 0,
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
                );
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

