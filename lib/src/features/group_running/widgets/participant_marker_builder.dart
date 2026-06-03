import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';

final _logger = Logger();

/// Builds a Google Maps [BytesMapBitmap] for a group run participant.
///
/// Renders:
///   - Character sphere (grey for other participants)
///   - Nickname text below (omitted if null)
///   - Title text below nickname (omitted if null)
Future<BytesMapBitmap?> buildParticipantMarkerBitmap({
  required String? nickname,
  String? titleName,
  Color sphereColor = const Color(0xFF9E9E9E), // grey default for others
}) async {
  try {
    final dpr =
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;

    // --- Sizes ---
    const sphereLogical = 56.0;
    const nickFontLogical = 12.0;
    const titleFontLogical = 10.0;
    const lineGapLogical = 3.0;

    final spherePx = (sphereLogical * dpr).round();

    // Measure text widths (worst-case estimation; actual clip won't matter)
    final double nickHeightPx =
        nickname != null ? (nickFontLogical * dpr * 1.4) : 0;
    final double titleHeightPx =
        titleName != null ? (titleFontLogical * dpr * 1.4) : 0;
    final double gapPx = (lineGapLogical * dpr);

    final double totalHeightPx = spherePx +
        (nickname != null ? gapPx + nickHeightPx : 0) +
        (titleName != null ? gapPx + titleHeightPx : 0);

    // Canvas width: sphere size or text area (estimate 120px logical)
    final double canvasWidthPx =
        [spherePx.toDouble(), 120.0 * dpr].reduce((a, b) => a > b ? a : b);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, canvasWidthPx, totalHeightPx),
    );

    final cx = canvasWidthPx / 2;
    final r = spherePx / 2.0;
    final sphereCenter = Offset(cx, r);

    // --- 1. Base sphere ---
    canvas.drawCircle(sphereCenter, r - 1, Paint()..color = sphereColor);

    // --- 2. Shadow radial gradient ---
    canvas.drawCircle(
      sphereCenter,
      r - 1,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx + r * 0.2, r + r * 0.2),
          r * 1.3,
          [
            Colors.black.withValues(alpha: 0),
            Colors.black.withValues(alpha: 0.18),
            Colors.black.withValues(alpha: 0.45),
          ],
          [0.0, 0.7, 1.0],
        ),
    );

    // --- 3. Highlight specular ---
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - r * 0.15, r * 0.70),
        width: r * 0.85,
        height: r * 0.68,
      ),
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx - r * 0.15, r * 0.70),
          r * 0.42,
          [
            Colors.white.withValues(alpha: 0.75),
            Colors.white.withValues(alpha: 0.25),
            Colors.white.withValues(alpha: 0),
          ],
          [0.0, 0.5, 1.0],
        ),
    );

    // --- 4. Outline ---
    final hsl = HSLColor.fromColor(sphereColor);
    final outlineColor =
        hsl.withLightness((hsl.lightness - 0.25).clamp(0.0, 1.0)).toColor();
    const strokeW = 2.5;
    canvas.drawCircle(
      sphereCenter,
      r - 1 - (strokeW * dpr / 2),
      Paint()
        ..color = outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW * dpr,
    );

    // --- 5. Nickname text ---
    double textY = spherePx.toDouble() + gapPx;
    if (nickname != null) {
      final nickPainter = _makePainter(
        nickname,
        fontSize: nickFontLogical * dpr,
        color: const Color(0xFF1A1612),
        bold: true,
      );
      nickPainter.layout(maxWidth: canvasWidthPx);
      nickPainter.paint(
        canvas,
        Offset(cx - nickPainter.width / 2, textY),
      );
      textY += nickHeightPx + gapPx;
    }

    // --- 6. Title text ---
    if (titleName != null) {
      final titlePainter = _makePainter(
        titleName,
        fontSize: titleFontLogical * dpr,
        color: const Color(0xFF8A8480),
        bold: false,
      );
      titlePainter.layout(maxWidth: canvasWidthPx);
      titlePainter.paint(
        canvas,
        Offset(cx - titlePainter.width / 2, textY),
      );
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(
      canvasWidthPx.round(),
      totalHeightPx.round(),
    );
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return null;

    return BytesMapBitmap(
      bytes.buffer.asUint8List(),
      bitmapScaling: MapBitmapScaling.none,
    );
  } catch (e) {
    _logger.w('buildParticipantMarkerBitmap failed', error: e);
    return null;
  }
}

TextPainter _makePainter(
  String text, {
  required double fontSize,
  required Color color,
  required bool bold,
}) {
  return TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontSize: fontSize,
        color: color,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        shadows: const [
          Shadow(
            color: Colors.white,
            blurRadius: 4,
            offset: Offset(0, 0),
          ),
        ],
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  );
}
