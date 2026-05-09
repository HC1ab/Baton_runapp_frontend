import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../common/widgets/app_bottom_nav_bar.dart';
import 'create_room_screen.dart';
import 'models/run_card_data.dart';
import 'room_detail_screen.dart';
import 'social_providers.dart';
import 'widgets/group_run_card.dart';

class SocialFeedScreen extends ConsumerStatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  ConsumerState<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends ConsumerState<SocialFeedScreen> {
  late final List<RunCardData> _cards;

  static const Color _pointOrange = Color(0xFFF7673B);

  @override
  void initState() {
    super.initState();
    _cards = List<RunCardData>.from(_dummyCards);
  }

  Future<void> _openCreateScreen() async {
    final created = await Navigator.of(context).push<RunCardData>(
      MaterialPageRoute<RunCardData>(
        builder: (_) => const CreateRoomScreen(),
      ),
    );
    if (!mounted || created == null) return;
    setState(() {
      _cards.insert(0, created);
    });
  }

  Future<void> _joinGroup(RunCardData card) async {
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
      setState(() {
        final idx = _cards.indexOf(card);
        if (idx >= 0) {
          _cards[idx] = _cards[idx].copyWith(
            isParticipating: true,
            currentMembers: (_cards[idx].currentMembers + 1).clamp(0, _cards[idx].maxMembers),
          );
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('그룹 참여가 완료됐습니다.')),
      );
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
      setState(() {
        final idx = _cards.indexOf(card);
        if (idx >= 0) {
          _cards[idx] = _cards[idx].copyWith(
            isParticipating: false,
            currentMembers: (_cards[idx].currentMembers - 1).clamp(0, _cards[idx].maxMembers),
          );
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('그룹에서 나갔습니다.')),
      );
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
      setState(() {
        _cards.remove(card);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('그룹이 삭제됐습니다.')),
      );
      Navigator.of(context).maybePop();
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
      setState(() {
        final idx = _cards.indexOf(card);
        if (idx >= 0) {
          _cards[idx] = _cards[idx].copyWith(maxMembers: value);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('그룹 정보가 수정됐습니다.')),
      );
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
                child: ListView.builder(
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    final card = cards[index];
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
                                builder: (_) =>
                                    RoomDetailScreen(
                                      card: card,
                                      onJoinPressed: () => _joinGroup(card),
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
                            isHighlighted: index == 2,
                            participantImageUrls: card.participantImageUrls,
                            onJoinPressed: card.isHost || card.isParticipating
                                ? null
                                : () => _joinGroup(card),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateScreen,
        backgroundColor: _pointOrange,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.edit),
        label: const Text('+ 모집하기'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 2,
        onTap: (_) {},
      ),
    );
  }
}

const List<RunCardData> _dummyCards = [
  RunCardData(
    groupId: 1,
    isHost: true,
    isParticipating: true,
    title: '반포 한강공원 야간 러닝',
    time: '오늘 오후 8:00',
    location: '반포 한강공원 편의점 앞',
    latitude: 35.1631,
    longitude: 129.0536,
    currentMembers: 4,
    maxMembers: 8,
    participantImageUrls: ['', '', ''],
    endTimeLabel: '오늘 오후 9:30',
    targetDistance: '5km',
    placeName: '반포 한강공원',
    detailAddress: '서울특별시 서초구 반포동 115-5 (반포한강공원 내)',
    body:
        '편하게 5km 정도 뛰어요.\n초보도 환영합니다. 페이스는 천천히 맞춰 갈게요.\n집결은 반포대교 쪽에서 합니다.',
  ),
  RunCardData(
    groupId: 2,
    isParticipating: true,
    title: '올림픽공원 5km 편런',
    time: '내일 오전 7:30',
    location: '평화의광장 조형물 아래',
    latitude: 35.1587,
    longitude: 129.1604,
    currentMembers: 2,
    maxMembers: 5,
    participantImageUrls: ['', ''],
    endTimeLabel: '내일 오전 8:30',
    targetDistance: '5km',
    placeName: '올림픽공원 평화의광장',
    detailAddress: '서울특별시 송파구 올림픽로 424 (평화의광장)',
    body: '아침 공기 마시며 가볍게 달려요.\n스트레칭 10분 후 출발합니다.',
  ),
  RunCardData(
    groupId: 3,
    title: '초보자 환영! 동네 한바퀴',
    time: '오늘 오후 6:00',
    location: '성수역 3번 출구',
    latitude: 35.1532,
    longitude: 129.1186,
    currentMembers: 7,
    maxMembers: 8,
    participantImageUrls: ['', '', ''],
    endTimeLabel: '오늘 오후 7:00',
    targetDistance: '3km',
    placeName: '성수역 인근',
    detailAddress: '서울특별시 성동구 성수동2가 (성수역 3번 출구 앞 집결)',
    body:
        '동네 한 바퀴만 돌아요. 대화하면서 천천히 뛰는 모임입니다.\n러닝화만 챙겨 오세요!',
  ),
];
