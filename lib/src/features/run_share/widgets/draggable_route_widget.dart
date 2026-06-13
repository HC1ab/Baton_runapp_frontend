import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../models/run_share_data.dart';
import '../models/share_overlay_config.dart';
import '../providers/run_share_provider.dart';

/// 드래그 이동 + 리사이즈 핸들 + 탭 선택 가능한 글로우 경로 위젯.
class DraggableRouteWidget extends ConsumerWidget {
  const DraggableRouteWidget({
    super.key,
    required this.path,
    required this.config,
    required this.canvasSize,
  });

  final List<SharePathPoint> path;
  final ShareOverlayConfig config;
  final Size canvasSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(runShareProvider.notifier);
    final isSelected = config.routeSelected;

    final routeW = canvasSize.width * config.routeScale;
    final routeH = canvasSize.height * config.routeScale;
    final left = config.routeOffsetX * canvasSize.width - routeW / 2;
    final top = config.routeOffsetY * canvasSize.height - routeH / 2;

    return Positioned(
      left: left,
      top: top,
      width: routeW,
      height: routeH,
      child: GestureDetector(
        onTap: () => notifier.selectRoute(),
        onPanUpdate: (d) => notifier.moveRoute(
          d.delta.dx / canvasSize.width,
          d.delta.dy / canvasSize.height,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── 경로 페인터 — 전체 영역 채움 ─────────────────────────────────
            Positioned.fill(
              child: CustomPaint(
                painter: _RoutePathPainter(
                  path: path,
                  color: config.routeColor,
                  strokeWidth: config.routeStrokeWidth,
                ),
              ),
            ),

            // ── 선택 테두리 ──────────────────────────────────────────────────
            if (isSelected)
              Positioned(
                left: 0,
                top: 0,
                right: 14.r,
                bottom: 14.r,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),

            // ── 리사이즈 핸들 ────────────────────────────────────────────────
            if (isSelected)
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onPanUpdate: (d) => notifier.scaleRoute(d.delta.dy),
                  child: Container(
                    width: 22.r,
                    height: 22.r,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.open_in_full_rounded,
                      size: 12.r,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── 경로 Painter (균일 패딩) ───────────────────────────────────────────────────

class _RoutePathPainter extends CustomPainter {
  const _RoutePathPainter({
    required this.path,
    this.color = AppColors.dAccent,
    this.strokeWidth = 3.0,
  });

  final List<SharePathPoint> path;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (path.length < 2) return;

    double minLat = path.first.lat, maxLat = path.first.lat;
    double minLng = path.first.lng, maxLng = path.first.lng;
    for (final p in path) {
      if (p.lat < minLat) minLat = p.lat;
      if (p.lat > maxLat) maxLat = p.lat;
      if (p.lng < minLng) minLng = p.lng;
      if (p.lng > maxLng) maxLng = p.lng;
    }

    final dLat = maxLat - minLat;
    final dLng = maxLng - minLng;

    const pad = 0.10;
    final drawW = size.width * (1 - pad * 2);
    final drawH = size.height * (1 - pad * 2);
    final originX = size.width * pad;
    final originY = size.height * pad;

    final scaleX = dLng < 1e-8 ? 1.0 : drawW / dLng;
    final scaleY = dLat < 1e-8 ? 1.0 : drawH / dLat;
    final scale = math.min(scaleX, scaleY);

    final usedW = dLng < 1e-8 ? 0.0 : dLng * scale;
    final usedH = dLat < 1e-8 ? 0.0 : dLat * scale;
    final offsetX = originX + (drawW - usedW) / 2;
    final offsetY = originY + (drawH - usedH) / 2;

    Offset toCanvas(SharePathPoint p) {
      final x = dLng < 1e-8 ? size.width / 2 : offsetX + (p.lng - minLng) * scale;
      final y = dLat < 1e-8 ? originY + drawH / 2 : offsetY + (maxLat - p.lat) * scale;
      return Offset(x, y);
    }

    final pts = path.map(toCanvas).toList();
    final routePath = Path();
    routePath.moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      routePath.lineTo(pts[i].dx, pts[i].dy);
    }

    // 외부 글로우
    canvas.drawPath(routePath, Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));

    // 내부 글로우
    canvas.drawPath(routePath, Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 2.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

    // 코어 라인
    canvas.drawPath(routePath, Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);

    _drawDot(canvas, pts.first, color);
    _drawDot(canvas, pts.last, color);
  }

  void _drawDot(Canvas canvas, Offset center, Color c) {
    canvas.drawCircle(center, 6, Paint()..color = Colors.white);
    canvas.drawCircle(center, 4, Paint()..color = c);
  }

  @override
  bool shouldRepaint(_RoutePathPainter old) =>
      old.path != path || old.color != color || old.strokeWidth != strokeWidth;
}
