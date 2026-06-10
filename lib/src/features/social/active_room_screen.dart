import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_map_styles.dart';
import '../../core/shell/tab_providers.dart';
import '../../core/constants/app_routes.dart';
import '../group_running/providers/run_location_provider.dart';
import 'models/run_card_data.dart';

/// 그룹 러닝 활성 중 소셜 탭에 표시되는 현재 방 전용 화면.
/// 피드 대신 전체 영역을 차지하며 수정/삭제/나가기 액션을 제공한다.
class ActiveRoomScreen extends ConsumerWidget {
  const ActiveRoomScreen({
    super.key,
    required this.card,
    this.onUpdatePressed,
    this.onDeletePressed,
    this.onLeavePressed,
  });

  final RunCardData card;
  final VoidCallback? onUpdatePressed;
  final VoidCallback? onDeletePressed;
  final VoidCallback? onLeavePressed;

  static const Color _pageBg = AppColors.dScreen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connState = ref.watch(
      runLocationProvider.select((s) => s.connectionState),
    );

    return Scaffold(
      backgroundColor: _pageBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 미니맵 (방 지정 위치 기준) ─────────────────────────────────────
          _ActiveMiniMap(card: card),

          // ── 방 정보 카드 ──────────────────────────────────────────────────
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
                child: _ActiveDetailCard(card: card, connectionState: connState),
              ),
            ),
          ),

          // ── 하단 버튼 ────────────────────────────────────────────────────
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
              child: _ActiveBottomActions(
                card: card,
                onUpdatePressed: onUpdatePressed,
                onDeletePressed: onDeletePressed,
                onLeavePressed: onLeavePressed,
                onGoToRun: () =>
                    ref.read(currentTabProvider.notifier).switchTo(AppTabs.running),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ActiveMiniMap — 방 지정 위치에 마커
// ---------------------------------------------------------------------------

class _ActiveMiniMap extends StatelessWidget {
  const _ActiveMiniMap({required this.card});

  final RunCardData card;

  @override
  Widget build(BuildContext context) {
    final target = LatLng(card.latitude, card.longitude);

    return SizedBox(
      height: 220.h,
      width: double.infinity,
      child: GoogleMap(
        style: AppMapStyles.darkWarm,
        initialCameraPosition: CameraPosition(target: target, zoom: 15),
        zoomGesturesEnabled: false,
        scrollGesturesEnabled: false,
        tiltGesturesEnabled: false,
        rotateGesturesEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        myLocationButtonEnabled: false,
        markers: {
          Marker(
            markerId: const MarkerId('active_room_spot'),
            position: target,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange),
          ),
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ActiveDetailCard — 방 정보
// ---------------------------------------------------------------------------

class _ActiveDetailCard extends StatelessWidget {
  const _ActiveDetailCard({
    required this.card,
    required this.connectionState,
  });

  final RunCardData card;
  final RunLocationConnectionState connectionState;

  @override
  Widget build(BuildContext context) {
    final timeRange = '${card.time}  ~  ${card.effectiveEndTime}';
    final connLabel = switch (connectionState) {
      RunLocationConnectionState.connected => ('연결됨', const Color(0xFF34C759)),
      RunLocationConnectionState.connecting => ('연결 중', const Color(0xFFFFCC00)),
      RunLocationConnectionState.error => ('연결 오류', const Color(0xFFFF3B30)),
      RunLocationConnectionState.idle => ('대기 중', const Color(0xFFAAAAAA)),
    };

    return Material(
      color: AppColors.dCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
        side: const BorderSide(color: AppColors.dLine, width: 1),
      ),
      shadowColor: Colors.black.withValues(alpha: 0.4),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목 + 연결 상태 뱃지
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    card.title,
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.dText,
                      height: 1.25,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: connLabel.$2.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    connLabel.$1,
                    style: TextStyle(
                      color: connLabel.$2,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            _InfoRow(icon: Icons.schedule_rounded, text: timeRange),
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
            SizedBox(height: 20.h),
            Divider(height: 1, color: AppColors.dLine),
            SizedBox(height: 16.h),
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
            if (card.effectiveBody.isNotEmpty) ...[
              SizedBox(height: 20.h),
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
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.dMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
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
                  color: AppColors.dMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
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
// _ActiveBottomActions — 호스트/참가자 버튼
// ---------------------------------------------------------------------------

class _ActiveBottomActions extends StatelessWidget {
  const _ActiveBottomActions({
    required this.card,
    required this.onGoToRun,
    this.onUpdatePressed,
    this.onDeletePressed,
    this.onLeavePressed,
  });

  final RunCardData card;
  final VoidCallback onGoToRun;
  final VoidCallback? onUpdatePressed;
  final VoidCallback? onDeletePressed;
  final VoidCallback? onLeavePressed;

  static const Color _pointOrange = AppColors.socialAccent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 러닝 화면으로 이동 버튼 (공통)
        SizedBox(
          height: 52.h,
          child: FilledButton.icon(
            onPressed: onGoToRun,
            icon: const Icon(Icons.directions_run_rounded),
            label: const Text('러닝 화면으로'),
            style: FilledButton.styleFrom(
              backgroundColor: _pointOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
              textStyle: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        SizedBox(height: 10.h),
        // 호스트: 수정 + 삭제 / 참가자: 나가기
        if (card.isHost)
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52.h,
                  child: OutlinedButton(
                    onPressed: onUpdatePressed,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _pointOrange,
                      side: const BorderSide(color: _pointOrange),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
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
                      backgroundColor: const Color(0xFFD64545),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
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
          )
        else
          SizedBox(
            height: 52.h,
            child: OutlinedButton(
              onPressed: onLeavePressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.dMuted,
                side: const BorderSide(color: AppColors.dLine2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                textStyle: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: const Text('방 나가기'),
            ),
          ),
      ],
    );
  }
}
