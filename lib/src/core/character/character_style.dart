import 'package:flutter/material.dart';

/// Immutable character style definition.
/// Manages character color independently from AppColors / theme.
class CharacterStyle {
  const CharacterStyle({
    required this.id,
    required this.name,
    required this.baseColor,
    this.isLocked = false,
  });

  /// Unique identifier — used for persistence key.
  final String id;

  /// Display name shown in UI.
  final String name;

  /// Applied to sphere_base.svg via ColorFilter.mode(BlendMode.srcATop).
  final Color baseColor;

  /// Locked styles are not selectable until unlocked (e.g. via Baton Shop).
  final bool isLocked;

  @override
  bool operator ==(Object other) =>
      other is CharacterStyle && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// All available character style presets.
/// Add new styles here — no other file needs changing.
abstract final class CharacterStylePresets {
  static const darkCoral = CharacterStyle(
    id: 'dark_coral',
    name: 'Dark Coral',
    baseColor: Color(0xFFBB6B4D),
  );

  static const salmon = CharacterStyle(
    id: 'salmon',
    name: 'Salmon',
    baseColor: Color(0xFFE8936A),
  );

  static const sageGreen = CharacterStyle(
    id: 'sage_green',
    name: 'Sage Green',
    baseColor: Color(0xFF8CB87A),
  );

  static const skyBlue = CharacterStyle(
    id: 'sky_blue',
    name: 'Sky Blue',
    baseColor: Color(0xFF87B3D3),
  );

  static const yellow = CharacterStyle(
    id: 'yellow',
    name: 'Yellow',
    baseColor: Color(0xFFE8C55A),
  );

  static const lavender = CharacterStyle(
    id: 'lavender',
    name: 'Lavender',
    baseColor: Color(0xFFB39BC8),
  );

  static const teal = CharacterStyle(
    id: 'teal',
    name: 'Teal',
    baseColor: Color(0xFF6BB8A6),
  );

  static const exclusive = CharacterStyle(
    id: 'exclusive',
    name: 'Exclusive',
    baseColor: Color(0xFF888888),
    isLocked: true,
  );

  /// Ordered list for palette display.
  static const List<CharacterStyle> all = [
    darkCoral,
    salmon,
    sageGreen,
    skyBlue,
    yellow,
    lavender,
    teal,
    exclusive,
  ];

  /// Default style applied on first launch.
  static const CharacterStyle defaultStyle = darkCoral;

  /// Find preset by [id]. Returns [defaultStyle] if not found.
  static CharacterStyle fromId(String id) {
    return all.firstWhere(
      (s) => s.id == id,
      orElse: () => defaultStyle,
    );
  }
}
