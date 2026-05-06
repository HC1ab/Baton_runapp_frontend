import 'package:flutter/material.dart';

import '../../group_running/models/group_running_models.dart';
import '../../group_running/repositories/group_running_repository.dart';

class SocialGroupRunningScreen extends StatefulWidget {
  const SocialGroupRunningScreen({super.key});

  @override
  State<SocialGroupRunningScreen> createState() => _SocialGroupRunningScreenState();
}

class _SocialGroupRunningScreenState extends State<SocialGroupRunningScreen> {
  final GroupRunningRepository _repository = GroupRunningRepository();
  late Future<GroupPageResponse> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.fetchGroupRunningList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<GroupPageResponse>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<GroupPageResponse> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<GroupRunningItem> list = snapshot.data?.content ?? <GroupRunningItem>[];
          final List<GroupRunningItem> items = list.isEmpty ? _fallbackGroups : list;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            itemCount: items.length + 1,
            itemBuilder: (BuildContext context, int index) {
              if (index == 0) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 18),
                  child: _SocialHeader(),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _SocialGroupCard(item: items[index - 1]),
              );
            },
          );
        },
      ),
    );
  }
}

class _SocialHeader extends StatelessWidget {
  const _SocialHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'COMMUNITY FEED',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: Color(0xFFB04823),
          ),
        ),
        SizedBox(height: 6),
        Text(
          '소셜',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
          ),
        ),
      ],
    );
  }
}

class _SocialGroupCard extends StatelessWidget {
  const _SocialGroupCard({required this.item});

  final GroupRunningItem item;

  @override
  Widget build(BuildContext context) {
    final bool highlight = item.currentParticipants >= item.maxParticipants - 1;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: highlight
            ? const LinearGradient(
                colors: <Color>[Color(0xFFB93404), Color(0xFFE76C40)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: highlight ? null : Colors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: highlight
                        ? const <Color>[Color(0xFFFFB38E), Color(0xFFFF8D61)]
                        : const <Color>[Color(0xFFFF7C49), Color(0xFFE04D16)],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 28,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    color: highlight ? Colors.white : const Color(0xFF222228),
                  ),
                ),
              ),
              _PeopleChip(
                current: item.currentParticipants,
                max: item.maxParticipants,
                inverse: highlight,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Icon(
                Icons.schedule_rounded,
                size: 17,
                color: highlight ? const Color(0xFFFFD4C4) : const Color(0xFF555960),
              ),
              const SizedBox(width: 6),
              Text(
                _format(item.startTime),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: highlight ? const Color(0xFFFFDCCE) : const Color(0xFF555960),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Icon(
                Icons.place_rounded,
                size: 18,
                color: highlight ? const Color(0xFFFFD4C4) : const Color(0xFFB03D17),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _fakeLocation[item.groupId] ?? '부산 러닝 포인트',
                  style: TextStyle(
                    fontSize: 16,
                    color: highlight ? Colors.white : const Color(0xFF7A2F16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Text(
                '호스트 ${item.hostNickname}',
                style: TextStyle(
                  color: highlight ? const Color(0xFFFFDCCE) : const Color(0xFF8B8B90),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: highlight ? Colors.white : const Color(0xFFC74612),
                  foregroundColor: highlight ? const Color(0xFFB03A14) : Colors.white,
                ),
                onPressed: () {},
                child: const Text('참여하기'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PeopleChip extends StatelessWidget {
  const _PeopleChip({
    required this.current,
    required this.max,
    required this.inverse,
  });

  final int current;
  final int max;
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: inverse ? Colors.white.withValues(alpha: 0.24) : const Color(0xFFF0F1F3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$current/$max명',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: inverse ? Colors.white : const Color(0xFF303038),
        ),
      ),
    );
  }
}

String _format(DateTime value) {
  final DateTime t = value.toLocal();
  final String month = t.month.toString().padLeft(2, '0');
  final String day = t.day.toString().padLeft(2, '0');
  final String hour = t.hour.toString().padLeft(2, '0');
  final String minute = t.minute.toString().padLeft(2, '0');
  return '$month/$day $hour:$minute';
}

const Map<int, String> _fakeLocation = <int, String>{
  1: '구서동 온천천 러닝 코스',
  2: '금정천 산책로',
  3: '센텀시티 해변 러닝 루트',
  4: '광안리 야간 롱런 코스',
};

final List<GroupRunningItem> _fallbackGroups = <GroupRunningItem>[
  GroupRunningItem(
    groupId: 1,
    title: '구서동 러닝 뛸 사람',
    hostNickname: 'ProteinSu',
    currentParticipants: 1,
    maxParticipants: 4,
    startTime: DateTime(2026, 3, 27, 16),
    status: 'RECRUITING',
    createdAt: DateTime(2026, 3, 29, 17, 2, 21),
  ),
  GroupRunningItem(
    groupId: 2,
    title: '금정천 5K 저녁 러닝',
    hostNickname: 'JinRunner',
    currentParticipants: 3,
    maxParticipants: 6,
    startTime: DateTime(2026, 5, 5, 19, 30),
    status: 'RECRUITING',
    createdAt: DateTime(2026, 5, 4, 20, 10),
  ),
  GroupRunningItem(
    groupId: 3,
    title: '센텀 브릿지 템포런',
    hostNickname: 'MinaPace',
    currentParticipants: 5,
    maxParticipants: 8,
    startTime: DateTime(2026, 5, 6, 6, 40),
    status: 'RECRUITING',
    createdAt: DateTime(2026, 5, 4, 20, 20),
  ),
  GroupRunningItem(
    groupId: 4,
    title: '주말 롱런 12K 크루',
    hostNickname: 'BlueTrack',
    currentParticipants: 7,
    maxParticipants: 10,
    startTime: DateTime(2026, 5, 9, 8, 0),
    status: 'RECRUITING',
    createdAt: DateTime(2026, 5, 4, 20, 30),
  ),
];