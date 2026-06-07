import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'models/run_card_data.dart';
import 'social_providers.dart';

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
  final VoidCallback? onJoinPressed;
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
      debugPrint('[RoomDetail] getDetail raw json keys: ${json.keys.toList()}');
      debugPrint('[RoomDetail] content field: ${json['content']}');
      final detail = RunCardData.fromServerJson(json);
      debugPrint('[RoomDetail] parsed body: ${detail.body}');
      if (mounted) setState(() => _detail = detail);
    } catch (e) {
      debugPrint('[RoomDetail] _fetchDetail error: $e');
      // 실패 시 목록에서 받은 card 데이터로 표시
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
          _RealMiniMap(card: _card),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: _DetailCard(card: _card),
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
                onJoinPressed: widget.onJoinPressed,
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
    required this.onJoinPressed,
    required this.onEnterLivePressed,
    required this.onLeavePressed,
    required this.onUpdatePressed,
    required this.onDeletePressed,
  });

  final RunCardData card;
  final Color pointOrange;
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
        onPressed: onJoinPressed,
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
        child: const Text('참여하기'),
      ),
    );
  }
}

class _RealMiniMap extends StatelessWidget {
  const _RealMiniMap({required this.card});

  final RunCardData card;

  @override
  Widget build(BuildContext context) {
    final target = LatLng(card.latitude, card.longitude);
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
  const _DetailCard({required this.card});

  final RunCardData card;

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
              _LabeledLine(
                icon: Icons.group_rounded,
                label: '참여자',
                value: card.participantNicknames.join(', '),
                iconColor: const Color(0xFFB33010),
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
