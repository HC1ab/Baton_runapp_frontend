import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/run_share_data.dart';
import '../models/share_overlay_config.dart';
import '../models/stat_item_config.dart';
import '../providers/run_share_provider.dart';
import 'draggable_route_widget.dart';
import 'draggable_stat_widget.dart';

class ShareCanvasWidget extends ConsumerWidget {
  const ShareCanvasWidget({
    super.key,
    required this.repaintKey,
    required this.data,
    required this.config,
    this.backgroundImage,
  });

  final GlobalKey repaintKey;
  final RunShareData data;
  final ShareOverlayConfig config;
  final File? backgroundImage;

  // 자유1/자유2 드래그 모드에서 사용하는 값 포맷
  String _value(String id) => switch (id) {
        'distance' => data.distanceText,
        'duration' => data.durationText,
        _ => data.paceText,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(runShareProvider.notifier);
    final isFreestyle = config.cardStyle == CardStyle.freestyle ||
        config.cardStyle == CardStyle.baton2;

    return RepaintBoundary(
      key: repaintKey,
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final canvasSize =
                  Size(constraints.maxWidth, constraints.maxHeight);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // ── 배경 ────────────────────────────────────────────────────
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => notifier.selectStat(null),
                      child: isFreestyle
                          ? _buildDarkBackground()     // 자유1·자유2: 다크 단색
                          : _buildMapBackground(),     // BATON1·BATON2: 지도 스냅샷
                    ),
                  ),

                  // ── BATON 2 정적 레이아웃 ──────────────────────────────────
                  if (config.cardStyle == CardStyle.baton3)
                    _Baton2Layout(data: data)
                  else ...[
                    if (config.showRoute && data.path.length >= 2)
                      DraggableRouteWidget(
                        path: data.path,
                        config: config,
                        canvasSize: canvasSize,
                      ),
                    // ── 스탯 (freestyle/nrc/korean/baton1/baton2 드래그 가능) ─
                    for (final stat in config.stats)
                      if (stat.visible)
                        _buildStatItem(stat, canvasSize, config),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// NRC 스타일: stat id → 아이콘
  IconData? _nrcIcon(String id) => switch (id) {
        'duration' => Icons.timer_outlined,
        'pace' => Icons.speed_outlined,
        _ => null,
      };

  /// 한글 스타일: stat id → 한글 레이블
  String? _koreanLabel(String id) => switch (id) {
        'distance' => '거리',
        'duration' => '시간',
        'pace' => '평균 페이스',
        _ => null,
      };

  Widget _buildStatItem(
    StatItemConfig stat,
    Size canvasSize,
    ShareOverlayConfig config,
  ) {
    final alignment = Alignment(stat.dx * 2 - 1, stat.dy * 2 - 1);
    return Align(
      alignment: alignment,
      child: DraggableStatWidget(
        stat: stat,
        canvasSize: canvasSize,
        isSelected: config.selectedStatId == stat.id,
        value: _value(stat.id),
        prefixIcon: config.cardStyle == CardStyle.nrc ? _nrcIcon(stat.id) : null,
        label: config.cardStyle == CardStyle.korean ? _koreanLabel(stat.id) : null,
      ),
    );
  }

  // 자유1·자유2 배경: 갤러리 이미지 > 다크 단색
  Widget _buildDarkBackground() {
    if (backgroundImage != null) return Image.file(backgroundImage!, fit: BoxFit.cover);
    return Container(color: const Color(0xFF2C2420));
  }

  // BATON1·BATON2 배경: 갤러리 이미지 > 지도 스냅샷 > 다크 단색
  Widget _buildMapBackground() {
    if (backgroundImage != null) return Image.file(backgroundImage!, fit: BoxFit.cover);
    if (data.mapSnapshot != null) return Image.memory(data.mapSnapshot!, fit: BoxFit.cover);
    return Container(color: const Color(0xFF1A1612));
  }
}

// ── BATON 2 정적 레이아웃 ─────────────────────────────────────────────────────

class _Baton2Layout extends StatelessWidget {
  const _Baton2Layout({required this.data});
  final RunShareData data;

  @override
  Widget build(BuildContext context) {
    const shadow = [Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 2))];

    return Stack(
      children: [
        // 상단 대형 거리 + 킬로미터 라벨
        Positioned(
          top: 44.r,
          left: 20.r,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.distanceShortText,
                style: TextStyle(
                  fontSize: 80.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.0,
                  letterSpacing: -2,
                  shadows: shadow,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '킬로미터',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.80),
                  shadows: shadow,
                ),
              ),
            ],
          ),
        ),

        // 하단 페이스 | 시간
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 22.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatCell(value: data.paceText, label: '평균 페이스', shadow: shadow),
                SizedBox(width: 20.w),
                Container(width: 1, height: 36.h, color: Colors.white.withValues(alpha: 0.30)),
                SizedBox(width: 20.w),
                _StatCell(value: data.durationShortText, label: '시간', shadow: shadow),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label, required this.shadow});
  final String value;
  final String label;
  final List<Shadow> shadow;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.1,
            shadows: shadow,
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.65),
            shadows: shadow,
          ),
        ),
      ],
    );
  }
}

