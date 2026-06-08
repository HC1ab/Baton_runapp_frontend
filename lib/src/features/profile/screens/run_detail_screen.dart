import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../run_share/models/run_share_data.dart';
import '../providers/history_providers.dart';

class RunDetailScreen extends ConsumerStatefulWidget {
  const RunDetailScreen({super.key, required this.runId});
  final int runId;

  @override
  ConsumerState<RunDetailScreen> createState() => _RunDetailScreenState();
}

class _RunDetailScreenState extends ConsumerState<RunDetailScreen> {
  GoogleMapController? _mapController;

  void _fitBoundsFromLatLngs(List<LatLng> points) {
    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLng = points.first.longitude, maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    // 경로 범위가 매우 좁을 때(제자리 운동 등) 최소 delta 확보
    const minDelta = 0.002;
    if (maxLat - minLat < minDelta) {
      final mid = (maxLat + minLat) / 2;
      minLat = mid - minDelta / 2;
      maxLat = mid + minDelta / 2;
    }
    if (maxLng - minLng < minDelta) {
      final mid = (maxLng + minLng) / 2;
      minLng = mid - minDelta / 2;
      maxLng = mid + minDelta / 2;
    }
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        72, // 충분한 여백으로 경로가 잘리지 않게
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(runDetailProvider(widget.runId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20.r),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '러닝 상세',
          style: AppTextStyles.headlineMedium.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
        actions: [
          detailAsync.whenOrNull(
            data: (detail) => IconButton(
              icon: Icon(Icons.share_rounded,
                  color: AppColors.textPrimary, size: 22.r),
              tooltip: '공유 카드',
              onPressed: () => context.push(
                AppRoutes.runShare,
                extra: RunShareData.fromDetail(detail),
              ),
            ),
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => _buildError(e),
        data: (detail) => _buildContent(detail),
      ),
    );
  }

  Widget _buildContent(RunDetailModel detail) {
    final latLngs = detail.path
        .map((p) => LatLng(p.lat, p.lng))
        .toList();

    final center = latLngs.isNotEmpty
        ? LatLng(
            latLngs.map((p) => p.latitude).reduce((a, b) => a + b) /
                latLngs.length,
            latLngs.map((p) => p.longitude).reduce((a, b) => a + b) /
                latLngs.length,
          )
        : const LatLng(37.5665, 126.9780);

    final polyline = latLngs.length >= 2
        ? {
            Polyline(
              polylineId: const PolylineId('route'),
              points: latLngs,
              color: AppColors.primary,
              width: 4,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          }
        : <Polyline>{};

    final markers = latLngs.length >= 2
        ? {
            Marker(
              markerId: const MarkerId('start'),
              position: latLngs.first,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
              infoWindow: const InfoWindow(title: '출발'),
            ),
            Marker(
              markerId: const MarkerId('end'),
              position: latLngs.last,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
              infoWindow: const InfoWindow(title: '도착'),
            ),
          }
        : <Marker>{};

    final kmSplits = _buildKmSplits(detail);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 지도 ────────────────────────────────────────────────────────
          SizedBox(
            height: 280.h,
            child: latLngs.isEmpty
                ? _buildMapPlaceholder()
                : IgnorePointer(
                    child: GoogleMap(
                      initialCameraPosition:
                          CameraPosition(target: center, zoom: 15),
                      onMapCreated: (controller) {
                        _mapController = controller;
                        if (latLngs.length >= 2) {
                          // 지도 레이아웃이 완전히 완료된 뒤 카메라 이동
                          Future.delayed(
                            const Duration(milliseconds: 300),
                            () => _fitBoundsFromLatLngs(latLngs),
                          );
                        }
                      },
                      polylines: polyline,
                      markers: markers,
                      myLocationEnabled: false,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      compassEnabled: false,
                      mapToolbarEnabled: false,
                      scrollGesturesEnabled: false,
                      zoomGesturesEnabled: false,
                      rotateGesturesEnabled: false,
                      tiltGesturesEnabled: false,
                    ),
                  ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 통계 카드 ──────────────────────────────────────────────
                _buildStatsRow(detail),
                SizedBox(height: 28.h),

                // ── km 페이스 ──────────────────────────────────────────────
                if (kmSplits.isNotEmpty) ...[
                  Text(
                    'KM SPLITS',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  ...kmSplits,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(RunDetailModel detail) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat(
            value: detail.totalDistanceKm.toStringAsFixed(2),
            label: 'KM',
            icon: Icons.straighten_rounded,
          ),
          _buildDivider(),
          _buildStat(
            value: detail.totalTimeText,
            label: 'TIME',
            icon: Icons.timer_outlined,
          ),
          _buildDivider(),
          _buildStat(
            value: detail.avgPaceText,
            label: 'PACE',
            icon: Icons.speed_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildStat({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 18.r),
        SizedBox(height: 6.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 48.h,
      color: AppColors.divider,
    );
  }

  List<Widget> _buildKmSplits(RunDetailModel detail) {
    if (detail.avgPaceSecPerKm <= 0 || detail.totalDistanceKm <= 0) return [];

    final fullKms = detail.totalDistanceKm.floor();
    final remainder = detail.totalDistanceKm - fullKms;
    final paceText = detail.avgPaceText;

    final splits = <Widget>[];
    for (int i = 1; i <= fullKms; i++) {
      splits.add(_buildSplitRow(label: '$i km', pace: paceText, isLast: i == fullKms && remainder < 0.05));
    }
    if (remainder >= 0.05) {
      splits.add(_buildSplitRow(
        label: '+${remainder.toStringAsFixed(2)} km',
        pace: paceText,
        isLast: true,
      ));
    }
    return splits;
  }

  Widget _buildSplitRow({
    required String label,
    required String pace,
    required bool isLast,
  }) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: Row(
            children: [
              Container(
                width: 8.r,
                height: 8.r,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                pace,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 4.w),
              Text(
                '/km',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, color: AppColors.divider),
      ],
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      color: AppColors.divider,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 40.r, color: AppColors.textSecondary),
            SizedBox(height: 8.h),
            Text(
              '경로 데이터가 없어요.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(Object e) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 40.r, color: AppColors.error),
            SizedBox(height: 12.h),
            Text(
              '상세 정보를 불러오지 못했어요.\n$e',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            SizedBox(height: 16.h),
            TextButton(
              onPressed: () => ref.invalidate(runDetailProvider(widget.runId)),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
