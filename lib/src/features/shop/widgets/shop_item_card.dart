import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/character/character_style.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../services/shop_service.dart';

class ShopItemCard extends StatelessWidget {
  const ShopItemCard({
    super.key,
    required this.item,
    required this.isOwned,
    required this.isPurchasing,
    required this.onBuy,
    this.hexColor,
  });

  final ShopItem item;
  final bool isOwned;
  final bool isPurchasing;
  final VoidCallback onBuy;

  /// Hex color string from API (e.g. "#C85A3E"). Overrides local preset.
  final String? hexColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildSphereArea()),
          _buildInfoArea(),
        ],
      ),
    );
  }

  // ── Sphere Visual Area ──────────────────────────────────────────────────

  Widget _buildSphereArea() {
    final color = _resolveColor();

    return Stack(
      children: [
        // Background
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusLg),
            ),
          ),
        ),
        // Sphere
        Center(
          child: _buildSphere(color),
        ),
        // Badge
        Positioned(
          top: 8.h,
          left: 8.w,
          child: _buildBadge(),
        ),
        // Owned overlay
        if (isOwned)
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusLg),
              ),
            ),
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: 5.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 12.r,
                      color: AppColors.success,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Owned',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSphere(Color color) {
    final highlight = Color.lerp(color, Colors.white, 0.55)!;
    final shadow = Color.lerp(color, Colors.black, 0.25)!;

    return Container(
      width: 72.r,
      height: 72.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 0.9,
          colors: [highlight, color, shadow],
          stops: const [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge() {
    if (item.isCoreColor) {
      return _Badge(label: 'COLOR', color: const Color(0xFF00897B));
    }
    return _Badge(label: 'SPECIAL', color: AppColors.error);
  }

  // ── Info Area ───────────────────────────────────────────────────────────

  Widget _buildInfoArea() {
    return Padding(
      padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name,
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontSize: 11.sp,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 6.h),
          _buildBuyButton(),
        ],
      ),
    );
  }

  Widget _buildBuyButton() {
    if (isOwned) {
      return Text(
        'Owned',
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondary,
          fontSize: 10.sp,
        ),
      );
    }

    return GestureDetector(
      onTap: isPurchasing ? null : onBuy,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 5.h),
        decoration: BoxDecoration(
          color: isPurchasing
              ? AppColors.divider
              : AppColors.primary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: isPurchasing
            ? Center(
                child: SizedBox(
                  width: 12.r,
                  height: 12.r,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    color: Colors.white,
                    size: 12.r,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    '${_formatPrice(item.price)} pts',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 10.sp,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  Color _resolveColor() {
    // API hex 우선
    if (hexColor != null) {
      final c = _hexToColor(hexColor!);
      if (c != null) return c;
    }
    // CHAR_* → CORE_* 로 변환 후 프리셋 조회 (e.g. CHAR_RED → CORE_RED)
    final presetCode = item.code.startsWith('CHAR_')
        ? item.code.replaceFirst('CHAR_', 'CORE_')
        : item.code;
    return CharacterStylePresets.fromCode(presetCode).baseColor;
  }

  static Color? _hexToColor(String hex) {
    try {
      final cleaned = hex.replaceAll('#', '');
      final value = int.parse(
        cleaned.length == 6 ? 'FF$cleaned' : cleaned,
        radix: 16,
      );
      return Color(value);
    } catch (_) {
      return null;
    }
  }

  String _formatPrice(int price) {
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(price % 1000 == 0 ? 0 : 1)}k';
    }
    return price.toString();
  }
}

// ---------------------------------------------------------------------------
// Private Badge Widget
// ---------------------------------------------------------------------------

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 8.sp,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
