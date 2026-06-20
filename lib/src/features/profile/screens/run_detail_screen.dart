import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_map_styles.dart';
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

  BitmapDescriptor? _startIcon;
  BitmapDescriptor? _endIcon;

  @override
  void initState() {
    super.initState();
    _buildMarkerIcons();
  }

  Future<void> _buildMarkerIcons() async {
    final dpr =
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    final start = await _dotMarker(AppColors.dRouteStart, dpr);
    final end = await _dotMarker(AppColors.dRouteEnd, dpr);
    if (!mounted) return;
    setState(() {
      _startIcon = start;
      _endIcon = end;
    });
  }

  /// A filled colored dot ringed by the dark background color — matches the
  /// redesign's start (green) / end (red) route markers.
  Future<BitmapDescriptor> _dotMarker(Color color, double dpr) async {
    const logical = 22.0; // logical px
    final size = logical * dpr;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);

    // soft outer glow
    canvas.drawCircle(
      center,
      size / 2,
      Paint()..color = color.withValues(alpha: 0.28),
    );
    // bg-colored ring
    canvas.drawCircle(
      center,
      size / 2 - 1.5 * dpr,
      Paint()..color = AppColors.dScreen,
    );
    // colored core
    canvas.drawCircle(
      center,
      size / 2 - 4.5 * dpr,
      Paint()..color = color,
    );

    final img =
        await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      imagePixelRatio: dpr,
    );
  }

  void _fitBoundsFromLatLngs(List<LatLng> points) {
    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLng = points.first.longitude, maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
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
        64,
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
      backgroundColor: AppColors.dScreen,
      appBar: AppBar(
        backgroundColor: AppColors.dScreen,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.dText, size: 20.r),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '러닝 상세',
          style: AppTextStyles.headlineMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.dText,
          ),
        ),
        centerTitle: false,
        actions: [
          detailAsync.whenOrNull(
            data: (detail) => IconButton(
              icon: Icon(Icons.share_rounded,
                  color: AppColors.dText, size: 22.r),
              tooltip: '공유 카드',
              onPressed: () async {
                final router = GoRouter.of(context);
                final snapshot = await _mapController?.takeSnapshot();
                if (!mounted) return;
                router.push(
                  AppRoutes.runShare,
                  extra: RunShareData.fromDetail(
                    detail,
                    mapSnapshot: snapshot,
                  ),
                );
              },
            ),
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.dAccent),
        ),
        error: (e, _) => _buildError(e),
        data: (detail) => _buildContent(detail),
      ),
    );
  }

  Widget _buildContent(RunDetailModel detail) {
    final latLngs = detail.path.map((p) => LatLng(p.lat, p.lng)).toList();
    final mapHeight = MediaQuery.of(context).size.height * 0.46;

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
              color: AppColors.dAccent,
              width: 5,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
              jointType: JointType.round,
            ),
          }
        : <Polyline>{};

    final markers = latLngs.length >= 2
        ? {
            Marker(
              markerId: const MarkerId('start'),
              position: latLngs.first,
              icon: _startIcon ??
                  BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen),
              anchor: const Offset(0.5, 0.5),
            ),
            Marker(
              markerId: const MarkerId('end'),
              position: latLngs.last,
              icon: _endIcon ??
                  BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed),
              anchor: const Offset(0.5, 0.5),
            ),
          }
        : <Marker>{};

    final kmSplits = _buildKmSplits(detail);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Map header ────────────────────────────────────────────────────
        SizedBox(
          height: mapHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: latLngs.isEmpty
                    ? _buildMapPlaceholder()
                    : IgnorePointer(
                        child: GoogleMap(
                          style: AppMapStyles.darkWarm,
                          initialCameraPosition:
                              CameraPosition(target: center, zoom: 15),
                          onMapCreated: (controller) {
                            _mapController = controller;
                            if (latLngs.length >= 2) {
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
              // 날짜 칩
              if (detail.startedAt != null)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 56.h,
                  left: 16.w,
                  child: _DateChip(date: detail.startedAt!),
                ),
            ],
          ),
        ),

        // ── Scroll body ───────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(22.w, 20.h, 22.w, 32.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsCard(detail),
                SizedBox(height: 26.h),
                if (kmSplits.isNotEmpty) ...[
                  Text(
                    'KM SPLITS',
                    style: TextStyle(
                      color: AppColors.dFaint,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  ...kmSplits,
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(RunDetailModel detail) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      decoration: BoxDecoration(
        color: AppColors.dCard,
        borderRadius: BorderRadius.circular(26.r),
        border: Border.all(color: AppColors.dLine, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStat(
              value: detail.totalDistanceKm.toStringAsFixed(2),
              label: 'KM',
              icon: Icons.straighten_rounded,
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildStat(
              value: detail.totalTimeText,
              label: 'TIME',
              icon: Icons.timer_outlined,
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildStat(
              value: detail.avgPaceText,
              label: 'PACE',
              icon: Icons.speed_rounded,
            ),
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
        Icon(icon, color: AppColors.dAccent, size: 18.r),
        SizedBox(height: 10.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 21.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.dText,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.dFaint,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 44.h,
      color: AppColors.dLine,
    );
  }

  List<Widget> _buildKmSplits(RunDetailModel detail) {
    if (detail.avgPaceSecPerKm <= 0 || detail.totalDistanceKm <= 0) return [];

    final fullKms = detail.totalDistanceKm.floor();
    final remainder = detail.totalDistanceKm - fullKms;
    final paceText = detail.avgPaceText;

    final splits = <Widget>[];
    for (int i = 1; i <= fullKms; i++) {
      splits.add(_buildSplitRow(label: '$i km', pace: paceText));
    }
    if (remainder >= 0.05) {
      splits.add(_buildSplitRow(
        label: '+${remainder.toStringAsFixed(2)} km',
        pace: paceText,
      ));
    }
    return splits;
  }

  Widget _buildSplitRow({required String label, required String pace}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 9.r,
                height: 9.r,
                decoration: const BoxDecoration(
                  color: AppColors.dAccent,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dText,
                ),
              ),
              const Spacer(),
              Text(
                pace,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dAccent,
                ),
              ),
              SizedBox(width: 4.w),
              Text(
                '/km',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.dMuted,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Container(height: 1, color: AppColors.dLine),
        ],
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      color: AppColors.dCard,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 40.r, color: AppColors.dFaint),
            SizedBox(height: 8.h),
            Text(
              '경로 데이터가 없어요.',
              style: TextStyle(color: AppColors.dMuted, fontSize: 13.sp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(Object e) {
    return SafeArea(
      child: Stack(
        children: [
          Positioned(
            top: 8.h,
            left: 16.w,
            child: _GlassBackButton(onTap: () => Navigator.of(context).pop()),
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.all(24.r),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 40.r, color: AppColors.dRouteEnd),
                  SizedBox(height: 12.h),
                  Text(
                    '상세 정보를 불러오지 못했어요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.dMuted, fontSize: 13.sp),
                  ),
                  SizedBox(height: 16.h),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(runDetailProvider(widget.runId)),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassBackButton extends StatelessWidget {
  const _GlassBackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.r),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 42.r,
            height: 42.r,
            decoration: BoxDecoration(
              color: const Color(0xB31E1E21), // card @ 0.7
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: AppColors.dLine, width: 1),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.dText,
              size: 18.r,
            ),
          ),
        ),
      ),
    );
  }
}

// ── 날짜 칩 ──────────────────────────────────────────────────────────────────

class _DateChip extends StatelessWidget {
  const _DateChip({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final label =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} '
        '${_weekday(date.weekday)}  '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: const Color(0xB31E1E21),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: AppColors.dLine, width: 1),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.dText,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }

  String _weekday(int w) => ['월', '화', '수', '목', '금', '토', '일'][w - 1];
}
