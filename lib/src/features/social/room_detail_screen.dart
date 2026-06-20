import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';

import '../../common/widgets/character_sphere_widget.dart';
import '../../core/character/character_style.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_map_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/error_messages.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/storage_keys.dart';
import '../../core/shell/tab_providers.dart';
import '../../core/storage/shared_prefs_provider.dart';
import '../../core/storage/token_storage.dart';
import '../../core/utils/app_snack_bar.dart';
import '../../core/utils/jwt_utils.dart';
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
  RunCardData? _detail;
  bool _isJoining = false;
  // nickname → coreColorCode
  Map<String, String> _participantColors = {};
  String? _myNickname;

  @override
  void initState() {
    super.initState();
    _myNickname = ref.read(sharedPreferencesProvider).getString(StorageKeys.myNickname);
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    final groupId = widget.card.groupId;
    if (groupId == null) return;
    try {
      final json =
          await ref.read(groupApiProvider).getDetail(groupId: groupId);
      _logger.d('[RoomDetail] raw json: $json');
      final pair = await ref.read(tokenStorageProvider).read();
      final myMemberId = memberIdFromAccessToken(pair?.accessToken);
      final detail = RunCardData.fromServerJson(json, myMemberId: myMemberId);
      _logger.d('[RoomDetail] lat=${detail.latitude} lng=${detail.longitude} isHost=${detail.isHost} isParticipating=${detail.isParticipating}');
      if (mounted) setState(() => _detail = detail);

      // 참여자 색상 비동기 로드
      _fetchParticipantColors(groupId);
    } catch (e, st) {
      _logger.e('[RoomDetail] _fetchDetail failed', error: e, stackTrace: st);
      if (mounted) AppSnackBar.error(context, ErrorMessages.groupDetailLoadFailed);
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
      backgroundColor: AppColors.dScreen,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: EdgeInsets.only(left: AppSpacing.sm),
          child: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.35),
              foregroundColor: Colors.white,
            ),
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18.r),
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
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  0,
                  AppSpacing.screenHorizontal,
                  AppSpacing.verticalLg,
                ),
                child: _DetailCard(card: _card, colorMap: _participantColors, myNickname: _myNickname),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.sm,
                AppSpacing.screenHorizontal,
                AppSpacing.verticalMd,
              ),
              child: _BottomActions(
                card: _card,
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
    required this.isJoining,
    required this.onJoinPressed,
    required this.onEnterLivePressed,
    required this.onLeavePressed,
    required this.onUpdatePressed,
    required this.onDeletePressed,
  });

  final RunCardData card;
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
            height: 52.h,
            child: FilledButton(
              onPressed: onEnterLivePressed,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.socialAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                textStyle: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: const Text('실시간 러닝 입장'),
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52.h,
                  child: OutlinedButton(
                    onPressed: onUpdatePressed,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.socialAccent,
                      side: BorderSide(color: AppColors.socialAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      textStyle: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: const Text('수정'),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: SizedBox(
                  height: 52.h,
                  child: FilledButton(
                    onPressed: onDeletePressed,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      textStyle: TextStyle(
                        fontSize: 17.sp,
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
            height: 52.h,
            child: FilledButton(
              onPressed: onEnterLivePressed,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.socialAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                textStyle: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: const Text('실시간 러닝 입장'),
            ),
          ),
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: OutlinedButton(
              onPressed: onLeavePressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.dMuted,
                side: BorderSide(color: AppColors.dLine2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                textStyle: TextStyle(
                  fontSize: 17.sp,
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
      height: 52.h,
      child: FilledButton(
        onPressed: isJoining ? null : onJoinPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.socialAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        child: isJoining
            ? SizedBox(
                width: 20.r,
                height: 20.r,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text('참여하기'),
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
      height: 250.h,
      width: double.infinity,
      child: GoogleMap(
        style: AppMapStyles.darkWarm,
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
  const _DetailCard({required this.card, required this.colorMap, this.myNickname});

  final RunCardData card;
  final Map<String, String> colorMap;
  final String? myNickname;

  @override
  Widget build(BuildContext context) {
    final timeRange = '${card.time}  ~  ${card.effectiveEndTime}';

    return Material(
      color: AppColors.dCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: const BorderSide(color: AppColors.dLine, width: 1),
      ),
      shadowColor: Colors.black.withValues(alpha: 0.4),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              card.title,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w900,
                color: AppColors.dText,
                height: 1.25,
              ),
            ),
            SizedBox(height: AppSpacing.verticalMd),
            _InfoRow(
              icon: Icons.schedule_rounded,
              text: timeRange,
            ),
            SizedBox(height: 10.h),
            _InfoRow(
              icon: Icons.straighten_rounded,
              text: '목표 거리 ${card.effectiveTargetDistance}',
            ),
            SizedBox(height: 10.h),
            _InfoRow(
              icon: Icons.groups_rounded,
              text: '현재 참여 인원 ${card.currentMembers} / ${card.maxMembers}명',
            ),
            SizedBox(height: AppSpacing.verticalMd + 4.h),
            Divider(height: 1, color: AppColors.dLine),
            SizedBox(height: AppSpacing.verticalMd),
            _LabeledLine(
              icon: Icons.place_rounded,
              label: '장소명',
              value: card.effectivePlaceName,
              iconColor: AppColors.dAccent,
            ),
            SizedBox(height: 14.h),
            _LabeledLine(
              icon: Icons.location_on_rounded,
              label: '주소',
              value: card.effectiveDetailAddress,
              iconColor: AppColors.dAccent,
            ),
            if (card.hostNickname != null) ...[
              SizedBox(height: 14.h),
              _LabeledLine(
                icon: Icons.person_rounded,
                label: '호스트',
                value: card.hostNickname!,
                iconColor: AppColors.dAccent,
              ),
            ],
            if (card.participantNicknames.isNotEmpty) ...[
              SizedBox(height: 14.h),
              _ParticipantList(
                nicknames: card.participantNicknames,
                hostNickname: card.hostNickname,
                colorMap: colorMap,
                myNickname: myNickname,
              ),
            ],
            SizedBox(height: AppSpacing.verticalMd),
            Text(
              '모집 내용',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.dMuted,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              card.effectiveBody,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.dMuted,
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
        Icon(icon, size: 20.r, color: AppColors.dMuted),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.dText,
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
        Icon(icon, size: 22.r, color: iconColor),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dMuted,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dText,
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
    this.myNickname,
  });

  final List<String> nicknames;
  final String? hostNickname;
  final Map<String, String> colorMap;
  final String? myNickname;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.group_rounded, size: 22.r, color: AppColors.dAccent),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '참여자',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dMuted,
                ),
              ),
              SizedBox(height: 8.h),
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
                    isSelf: myNickname != null && name == myNickname,
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

class _ParticipantChip extends ConsumerWidget {
  const _ParticipantChip({
    required this.nickname,
    required this.isHost,
    required this.characterStyle,
    this.isSelf = false,
  });

  final String nickname;
  final bool isHost;
  final CharacterStyle characterStyle;
  final bool isSelf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        if (isSelf) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          ref.read(currentTabProvider.notifier).switchTo(AppTabs.profile);
        } else {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => MemberProfileScreen(nickname: nickname),
            ),
          );
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CharacterSphereWidget(style: characterStyle, size: 36.r),
              if (isHost)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    size: 16.r,
                    color: Colors.amber.shade600,
                  ),
                ),
            ],
          ),
          SizedBox(width: 6.w),
          Text(
            nickname,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.dText,
            ),
          ),
        ],
      ),
    );
  }
}
