import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/character/character_style.dart';

/// Sphere-shaped character widget rendered with 4 SVG layers.
///
/// Layer order (bottom → top):
///   1. sphere_base.svg    — color target (ColorFiltered with style.baseColor)
///   2. sphere_shadow.svg  — fixed dark shading
///   3. sphere_highlight.svg — fixed bright specular
///   4. sphere_outline.svg — fixed outline
///
/// When SVG assets are not yet present, each layer falls back to a
/// transparent [SizedBox] so the widget renders without errors.
class CharacterSphereWidget extends StatelessWidget {
  const CharacterSphereWidget({
    super.key,
    required this.style,
    this.size,
  });

  final CharacterStyle style;

  /// Diameter in logical pixels. Defaults to 180.r if null.
  final double? size;

  @override
  Widget build(BuildContext context) {
    final double diameter = size ?? 180.r;
    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Base — color target
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              style.baseColor,
              BlendMode.srcATop,
            ),
            child: _SvgLayer(
              asset: 'assets/character/sphere_base.svg',
              fallback: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: style.baseColor,
                ),
              ),
            ),
          ),

          // 2. Shadow — dark shading (fixed)
          const _SvgLayer(asset: 'assets/character/sphere_shadow.svg'),

          // 3. Highlight — bright specular (fixed)
          const _SvgLayer(asset: 'assets/character/sphere_highlight.svg'),

          // 4. Outline (fixed)
          const _SvgLayer(asset: 'assets/character/sphere_outline.svg'),
        ],
      ),
    );
  }
}

/// Single SVG layer with transparent fallback when asset is missing.
class _SvgLayer extends StatelessWidget {
  const _SvgLayer({
    required this.asset,
    this.fallback,
  });

  final String asset;

  /// Widget shown when the SVG asset fails to load.
  /// Defaults to [SizedBox.shrink] (transparent).
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      fit: BoxFit.contain,
      // ignore: deprecated_member_use
      placeholderBuilder: (_) => fallback ?? const SizedBox.shrink(),
    );
  }
}
