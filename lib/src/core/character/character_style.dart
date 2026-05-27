import 'package:flutter/material.dart';

/// Immutable character style definition.
/// [code] matches the backend CORE_* code used for API calls and persistence.
class CharacterStyle {
  const CharacterStyle({
    required this.code,
    required this.name,
    required this.baseColor,
  });

  /// Backend code (e.g. CORE_RED). Used as storage key and API value.
  final String code;

  /// Display name shown in UI.
  final String name;

  /// Applied to sphere_base.svg via ColorFilter.mode(BlendMode.srcATop).
  /// Owned/locked status is managed by the API — not stored here.
  final Color baseColor;

  @override
  bool operator ==(Object other) =>
      other is CharacterStyle && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

/// All available character style presets.
/// Hex values are defined here as constants; owned status comes from API.
/// Add new styles here only — no other file needs changing.
abstract final class CharacterStylePresets {
  static const orange = CharacterStyle(
    code: 'CORE_ORANGE',
    name: '주황색 코어',
    baseColor: Color(0xFFF57C00),
  );

  static const red = CharacterStyle(
    code: 'CORE_RED',
    name: '빨간색 코어',
    baseColor: Color(0xFFE53935),
  );

  static const yellow = CharacterStyle(
    code: 'CORE_YELLOW',
    name: '노란색 코어',
    baseColor: Color(0xFFF9A825),
  );

  static const green = CharacterStyle(
    code: 'CORE_GREEN',
    name: '초록색 코어',
    baseColor: Color(0xFF43A047),
  );

  static const blue = CharacterStyle(
    code: 'CORE_BLUE',
    name: '파란색 코어',
    baseColor: Color(0xFF1E88E5),
  );

  static const navy = CharacterStyle(
    code: 'CORE_NAVY',
    name: '남색 코어',
    baseColor: Color(0xFF283593),
  );

  static const purple = CharacterStyle(
    code: 'CORE_PURPLE',
    name: '보라색 코어',
    baseColor: Color(0xFF8E24AA),
  );

  static const black = CharacterStyle(
    code: 'CORE_BLACK',
    name: '검은색 코어',
    baseColor: Color(0xFF212121),
  );

  /// Ordered list for palette display.
  static const List<CharacterStyle> all = [
    orange,
    red,
    yellow,
    green,
    blue,
    navy,
    purple,
    black,
  ];

  /// Default style — CORE_ORANGE (기본 지급).
  static const CharacterStyle defaultStyle = orange;

  /// Find preset by backend [code]. Returns [defaultStyle] if not found.
  static CharacterStyle fromCode(String code) {
    return all.firstWhere(
      (s) => s.code == code,
      orElse: () => defaultStyle,
    );
  }
}
