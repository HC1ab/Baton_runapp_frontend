import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';

import '../../common/widgets/character_sphere_widget.dart';
import '../../core/character/character_style.dart';
import '../group_running/services/group_run_api_service.dart';
import '../profile/screens/member_profile_screen.dart';
import 'models/run_card_data.dart';
import 'social_providers.dart';

final _logger = Logger();

class RoomDetailScreen extends ConsumerStatefulWidget {
  const RoomDetailScreen({
    super.key,
    required this.card,
    this.onJoinPressed,
    this.onEnterLivePressed,
    this.onLeavePressed,
    this.onUpdatePressed,
    this.onDeletePressed,
  });

  final RunCardData card;
  final Future<void> Function()? onJoinPressed;
  final VoidCallback? onEnterLivePressed;
  final VoidCallback? onLeavePressed;
  final VoidCallback? onUpdatePressed;
  final VoidCallback? onDeletePressed;

  @override
  ConsumerState<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends ConsumerState<RoomDetailScreen> {
  static const Color _pointOrange = Color(0xFFF7673B);
  static const Color _pageBg = Color(0xFFF4F4F4);

  RunCardData? _detail;
  bool _isJoining = false;
  // nickname → coreColorCode
  Map<String, String> _participantColors = {};

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    final groupId = widget.card.groupId;
    if (groupId == null) return;
    try {
      final json =
          await ref.read(groupApiProvider).getDetail(groupId: groupId);
      _logger.d('[RoomDetail] raw json: $json');
      var detail = RunCardData.fromServerJson(json);
      _logger.d('[RoomDetail] lat=${detail.latitude} lng=${detail.longitude}');
      // GroupDetail 응답에 isHost 필드 없음 → 목록에서 이미 판별된 값 유지
      detail = detail.copyWith(isHost: widget.card.isHost);
      // 서버가 좌표를 반환하지 않으면 목록/생성 시 저장된 좌표 유지
      if (detail.latitude == null && widget.card.latitude != null) {
        detail = detail.copyWith(
          latitude: widget.card.latitude,
          longitude: widget.card.longitude,
        );
      }
      if (mounted) setState(() => _detail = detail);

      // 참여자 색상 비동기 로드
      _fetchParticipantColors(groupId);
    } catch (e, st) {
      _logger.e('[RoomDetail] _fetchDetail failed', error: e, stackTrace: st);
    }
  }

  Future<void> _fetchParticipantColors(int groupId) async {
    try {
      final infoMap = await ref
          .read(groupRunApiServiceProvider)
          .fetchGroupMemberColors(groupId);
      final colors = <String, String>{};
      for (final entry in infoMap.entries) {
        final code = entry.value.coreColorCode;
        if (code != null) colors[entry.value.nickname] = code;
      }
      if (mounted) setState(() => _participantColors = colors);
    } catch (e) {
      _logger.w('[RoomDetail] _fetchParticipantColors failed', error: e);
    }
  }

  RunCardData get _card => _detail ?? widget.card;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.35),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_card.latitude != null && _card.longitude != null)
            _RealMiniMap(card: _card)
          else
            const _MapPlaceholder(),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: _DetailCard(card: _card, colorMap: _participantColors),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: _BottomActions(
                card: _card,
                pointOrange: _pointOrange,
                isJoining: _isJoining,
                onJoinPressed: widget.onJoinPressed == null
                    ? null
                    : () async {
                        if (_isJoining) return;
                        setState(() => _isJoining = true);
                        try {
                          await widget.onJoinPressed!();
                          if (mounted) await _fetchDetail();
                        } finally {
                          if (mounted) setState(() => _isJoining = false);
                        }
                      },
                onEnterLivePressed: widget.onEnterLivePressed,
                onLeavePressed: widget.onLeavePressed,
                onUpdatePressed: widget.onUpdatePressed,
                onDeletePressed: widget.onDeletePressed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.card,
    required this.pointOrange,
    required this.isJoining,
    required this.onJoinPressed,
    required this.onEnterLivePressed,
    required this.onLeavePressed,
    required this.onUpdatePressed,
    required this.onDeletePressed,
  });

  final RunCardData card;
  final Color pointOrange;
  final bool isJoining;
  final VoidCallback? onJoinPressed;
  final VoidCallback? onEnterLivePressed;
  final VoidCallback? onLeavePressed;
  final VoidCallback? onUpdatePressed;
  final VoidCallback? onDeletePressed;

  @override
  Widget build(BuildContext context) {
    if (card.isHost) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: onEnterLivePressed,
              style: FilledButton.styleFrom(
                backgroundColor: pointOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: const Text('실시간 러닝 입장'),
            ),
          ),
          const SizedBox(height: 10),
          Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: onUpdatePressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: pointOrange,
                  side: BorderSide(color: pointOrange),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: const Text('수정'),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: onDeletePressed,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD64545),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: const Text('삭제'),
              ),
            ),
          ),
        ],
          ),
        ],
      );
    }

    if (card.isParticipating) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: onEnterLivePressed,
              style: FilledButton.styleFrom(
                backgroundColor: pointOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: const Text('실시간 러닝 입장'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: onLeavePressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF666666),
                side: const BorderSide(color: Color(0xFFCCCCCC)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: const Text('나가기'),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: isJoining ? null : onJoinPressed,
        style: FilledButton.styleFrom(
          backgroundColor: pointOrange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        child: isJoining
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text('참여하기'),
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      width: double.infinity,
      color: const Color(0xFFE8E8E8),
      child: const Center(
        child: Icon(Icons.map_outlined, size: 48, color: Color(0xFFBBBBBB)),
      ),
    );
  }
}

class _RealMiniMap extends StatelessWidget {
  const _RealMiniMap({required this.card});

  final RunCardData card;

  @override
  Widget build(BuildContext context) {
    final target = LatLng(card.latitude!, card.longitude!);

    return SizedBox(
      height: 250,
      width: double.infinity,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: target,
          zoom: 15,
        ),
        zoomGesturesEnabled: false,
        scrollGesturesEnabled: false,
        tiltGesturesEnabled: false,
        rotateGesturesEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        myLocationButtonEnabled: false,
        markers: {
          Marker(
            markerId: const MarkerId('room_detail_spot'),
            position: target,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange),
          ),
        },
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.card, required this.colorMap});

  final RunCardData card;
  final Map<String, String> colorMap;

  @override
  Widget build(BuildContext context) {
    final timeRange =
        '${card.time}  ~  ${card.effectiveEndTime}';

    return Material(
      color: Colors.white,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              card.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A1A1A),
                height: 1.25,
              ),
            ),
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.schedule_rounded,
              text: timeRange,
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.straighten_rounded,
              text: '목표 거리 ${card.effectiveTargetDistance}',
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.groups_rounded,
              text:
                  '현재 참여 인원 ${card.currentMembers} / ${card.maxMembers}명',
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 16),
            _LabeledLine(
              icon: Icons.place_rounded,
              label: '장소명',
              value: card.effectivePlaceName,
              iconColor: const Color(0xFFB33010),
            ),
            const SizedBox(height: 14),
            _LabeledLine(
              icon: Icons.location_on_rounded,
              label: '주소',
              value: card.effectiveDetailAddress,
              iconColor: const Color(0xFFB33010),
            ),
            if (card.hostNickname != null) ...[
              const SizedBox(height: 14),
              _LabeledLine(
                icon: Icons.person_rounded,
                label: '호스트',
                value: card.hostNickname!,
                iconColor: const Color(0xFFB33010),
              ),
            ],
            if (card.participantNicknames.isNotEmpty) ...[
              const SizedBox(height: 14),
              _ParticipantList(
                nicknames: card.participantNicknames,
                hostNickname: card.hostNickname,
                colorMap: colorMap,
              ),
            ],
            const SizedBox(height: 20),
            const Text(
              '모집 내용',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              card.effectiveBody,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2C2C2C),
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF666666)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
        ),
      ],
    );
  }
}

class _LabeledLine extends StatelessWidget {
  const _LabeledLine({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF888888),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F1F1F),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _ParticipantList
// ---------------------------------------------------------------------------

class _ParticipantList extends StatelessWidget {
  const _ParticipantList({
    required this.nicknames,
    required this.hostNickname,
    required this.colorMap,
  });

  final List<String> nicknames;
  final String? hostNickname;
  final Map<String, String> colorMap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.group_rounded, size: 22, color: Color(0xFFB33010)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '참여자',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF888888),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: nicknames.map((name) {
                  final isHost = name == hostNickname;
                  final colorCode = colorMap[name] ?? 'CORE_ORANGE';
                  return _ParticipantChip(
                    nickname: name,
                    isHost: isHost,
                    characterStyle: CharacterStylePresets.fromCode(colorCode),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ParticipantChip extends StatelessWidget {
  const _ParticipantChip({
    required this.nickname,
    required this.isHost,
    required this.characterStyle,
  });

  final String nickname;
  final bool isHost;
  final CharacterStyle characterStyle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MemberProfileScreen(nickname: nickname),
        ),
      ),
      child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CharacterSphereWidget(style: characterStyle, size: 36),
            if (isHost)
              Positioned(
                top: -6,
                right: -6,
                child: Icon(
                  Icons.workspace_premium_rounded,
                  size: 16,
                  color: Colors.amber.shade600,
                ),
              ),
          ],
        ),
        const SizedBox(width: 6),
        Text(
          nickname,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F1F1F),
          ),
        ),
      ],
      ),
    );
  }
}
