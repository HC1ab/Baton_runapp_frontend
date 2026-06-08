import 'package:flutter/material.dart';

/// 공유 카드 스탯 1개의 개별 설정.
/// dx/dy → 캔버스 중심 기준 비율 [0.0, 1.0]
class StatItemConfig {
  const StatItemConfig({
    required this.id,
    required this.dx,
    required this.dy,
    required this.fontSize,
    required this.color,
    this.visible = true,
  });

  /// 'distance' | 'duration' | 'pace'
  final String id;

  /// 캔버스 내 중심 x 비율 [0.0, 1.0]
  final double dx;

  /// 캔버스 내 중심 y 비율 [0.0, 1.0]
  final double dy;

  final double fontSize;
  final Color color;
  final bool visible;

  StatItemConfig copyWith({
    String? id,
    double? dx,
    double? dy,
    double? fontSize,
    Color? color,
    bool? visible,
  }) {
    return StatItemConfig(
      id: id ?? this.id,
      dx: dx ?? this.dx,
      dy: dy ?? this.dy,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      visible: visible ?? this.visible,
    );
  }
}
