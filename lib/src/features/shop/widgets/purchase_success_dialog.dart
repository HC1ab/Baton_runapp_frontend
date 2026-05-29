import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:logger/logger.dart';

import '../../../core/character/character_provider.dart';
import '../../../core/character/character_style.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/error/app_exception.dart';
import '../../profile/services/my_room_service.dart';
import '../../profile/services/title_service.dart';
import '../services/shop_service.dart';

final _logger = Logger();

/// 구매 완료 팝업.
/// 색상 아이템: 확인(장착) + 닫기 버튼.
/// 칭호 아이템: 확인(장착) + 닫기 버튼.
/// 일반 아이템: 닫기 버튼만.
class PurchaseSuccessDialog extends ConsumerStatefulWidget {
  const PurchaseSuccessDialog({
    super.key,
    required this.item,
    required this.remainingPoints,
    this.titleId,
  });

  final ShopItem item;
  final int remainingPoints;

  /// 칭호 아이템일 때 TitleInfo.id — equipTitle 호출에 사용.
  final int? titleId;

  @override
  ConsumerState<PurchaseSuccessDialog> createState() =>
      _PurchaseSuccessDialogState();
}

class _PurchaseSuccessDialogState
    extends ConsumerState<PurchaseSuccessDialog> {
  bool _isEquipping = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final color = item.isCoreColor
        ? CharacterStylePresets.fromCode(item.code).baseColor
        : AppColors.primary;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Visual ──────────────────────────────────────────────
            item.isTitle ? _buildTitleBadge() : _buildSphere(color),
            SizedBox(height: AppSpacing.verticalMd),

            // ── Title ────────────────────────────────────────────────
            Text(
              '구매 완료!',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 6.h),

            // ── Item name ────────────────────────────────────────────
            Text(
              item.name,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.verticalSm),

            // ── Remaining points ─────────────────────────────────────
            Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt_rounded,
                      size: 14.r, color: AppColors.primary),
                  SizedBox(width: 4.w),
                  Text(
                    '잔여 ${widget.remainingPoints} pts',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.verticalLg),

            // ── Buttons ──────────────────────────────────────────────
            (item.isCoreColor || item.isTitle)
                ? Row(
                    children: [
                      Expanded(child: _closeButton()),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(child: _equipButton(color)),
                    ],
                  )
                : _closeButton(),
          ],
        ),
      ),
    );
  }

  // ── Sphere preview ───────────────────────────────────────────────────────

  Widget _buildSphere(Color color) {
    final highlight = Color.lerp(color, Colors.white, 0.55)!;
    final shadow = Color.lerp(color, Colors.black, 0.25)!;

    return Container(
      width: 110.r,
      height: 110.r,
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
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
    );
  }

  // ── Title badge preview ──────────────────────────────────────────────────

  Widget _buildTitleBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Text(
        widget.item.name,
        textAlign: TextAlign.center,
        style: AppTextStyles.headlineSmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ── Buttons ──────────────────────────────────────────────────────────────

  Widget _closeButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 13.h),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(color: AppColors.divider),
        ),
        child: Center(
          child: Text(
            '닫기',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _equipButton(Color color) {
    return GestureDetector(
      onTap: _isEquipping ? null : _onEquip,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 13.h),
        decoration: BoxDecoration(
          color: _isEquipping ? AppColors.divider : AppColors.primary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Center(
          child: _isEquipping
              ? SizedBox(
                  width: 16.r,
                  height: 16.r,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  '장착하기',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  // ── Equip logic ──────────────────────────────────────────────────────────

  Future<void> _onEquip() async {
    if (_isEquipping) return;
    setState(() => _isEquipping = true);

    try {
      if (widget.item.isTitle) {
        await _equipTitle();
      } else {
        await _equipColor();
      }
      if (mounted) Navigator.of(context).pop();
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      _logger.e('equip from shop error', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('장착에 실패했어요. 다시 시도해주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isEquipping = false);
    }
  }

  Future<void> _equipColor() async {
    final confirmedCode = await ref
        .read(myRoomServiceProvider)
        .changeCoreColor(widget.item.code);
    await ref
        .read(selectedCharacterStyleProvider.notifier)
        .setStyle(CharacterStylePresets.fromCode(confirmedCode));
    ref.invalidate(myRoomProvider);
    _logger.i('Equipped color from shop: $confirmedCode');
  }

  Future<void> _equipTitle() async {
    final titleId = widget.titleId;
    if (titleId == null) {
      _logger.w('equipTitle called but titleId is null — item: ${widget.item.code}');
      throw const UnknownException();
    }
    final result =
        await ref.read(titleServiceProvider).equipTitle(titleId);
    ref.invalidate(myRoomProvider);
    _logger.i('Equipped title from shop: ${result.name} (id: ${result.titleId})');
  }
}
