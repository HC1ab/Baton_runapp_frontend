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
import 'share_nrc_bar_widget.dart';

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
                          : _buildMapBackground(),     // 차지1·차지2: 지도 스냅샷
                    ),
                  ),

                  // ── 우측 상단 브랜드 태그 ───────────────────────────────────
                  Positioned(
                    top: 24.r,
                    right: 0,
                    child: _BatonBrandTag(tagStyle: config.tagStyle),
                  ),

                  // ── 차지 1 ─────────────────────────────────────────────────
                  if (config.cardStyle == CardStyle.baton1)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ShareNrcBarWidget(data: data, config: config),
                    )

                  // ── 차지 2 (baton3) ─────────────────────────────────────────
                  else if (config.cardStyle == CardStyle.baton3)
                    _Baton2Layout(data: data)

                  // ── 자유 1 / 자유 2 — 드래그 배치 ───────────────────────────
                  else ...[
                    if (config.showRoute && data.path.length >= 2)
                      DraggableRouteWidget(
                        path: data.path,
                        config: config,
                        canvasSize: canvasSize,
                      ),
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

  Widget _buildStatItem(StatItemConfig stat, Size canvasSize, ShareOverlayConfig cfg) {
    final alignment = Alignment(stat.dx * 2 - 1, stat.dy * 2 - 1);
    return Align(
      alignment: alignment,
      child: DraggableStatWidget(
        stat: stat,
        canvasSize: canvasSize,
        isSelected: cfg.selectedStatId == stat.id,
        value: _value(stat.id),
      ),
    );
  }

  // 자유1·자유2 배경: 갤러리 이미지 > 다크 단색
  Widget _buildDarkBackground() {
    if (backgroundImage != null) return Image.file(backgroundImage!, fit: BoxFit.cover);
    return Container(color: const Color(0xFF2C2420));
  }

  // 차지1·차지2 배경: 갤러리 이미지 > 지도 스냅샷 > 다크 단색
  Widget _buildMapBackground() {
    if (backgroundImage != null) return Image.file(backgroundImage!, fit: BoxFit.cover);
    if (data.mapSnapshot != null) return Image.memory(data.mapSnapshot!, fit: BoxFit.cover);
    return Container(color: const Color(0xFF1A1612));
  }
}

// ── 차지 2 정적 레이아웃 ─────────────────────────────────────────────────────

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

// ── 우측 상단 브랜드 태그 (Garmin 스타일) ─────────────────────────────────────

class _BatonBrandTag extends StatelessWidget {
  const _BatonBrandTag({required this.tagStyle});
  final TagStyle tagStyle;

  @override
  Widget build(BuildContext context) {
    final isDark = tagStyle == TagStyle.dark;
    final bgColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Container(
      width: 28.r,
      padding: EdgeInsets.symmetric(vertical: 12.r),
      decoration: BoxDecoration(
        color: bgColor,
      ),
      alignment: Alignment.center,
      child: RotatedBox(
        quarterTurns: 1,
        child: Text(
          'BATON',
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: textColor,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

