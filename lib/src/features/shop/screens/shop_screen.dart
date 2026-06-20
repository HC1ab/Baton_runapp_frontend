import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:logger/logger.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/error_messages.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/utils/app_snack_bar.dart';
import '../../../core/myroom/my_room_service.dart';
import '../services/shop_service.dart';
import '../widgets/purchase_success_dialog.dart';
import '../widgets/shop_item_card.dart';

final _logger = Logger();

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  int? _purchasingItemId;
  int _selectedTab = 0;

  static const List<String> _tabs = ['Colors', 'Auras', 'Booster'];

  @override
  Widget build(BuildContext context) {
    final points = ref.watch(userPointsProvider);

    return Scaffold(
      backgroundColor: AppColors.dScreen,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(points),
            Expanded(
              child: ref.watch(shopItemsProvider).when(
                    loading: _buildLoading,
                    error: _buildError,
                    data: _buildContent,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(int points) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.verticalSm,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36.r,
              height: 36.r,
              decoration: BoxDecoration(
                color: AppColors.dCard2,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.dLine, width: 1),
              ),
              child: Icon(
                Icons.arrow_back_ios_rounded,
                size: 16.r,
                color: AppColors.dText,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Text(
            'Shop',
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          _buildPointsBadge(points),
        ],
      ),
    );
  }

  Widget _buildPointsBadge(int points) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18.r,
            height: 18.r,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bolt_rounded, color: Colors.white, size: 11.r),
          ),
          SizedBox(width: 6.w),
          Text(
            '$points pts',
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── States ────────────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildError(Object e, StackTrace _) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ErrorMessages.shopLoadError,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.dMuted,
            ),
          ),
          SizedBox(height: 12.h),
          TextButton(
            onPressed: () => ref.invalidate(shopItemsProvider),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<ShopItem> items) {
    final filtered = switch (_selectedTab) {
      0 => items.where((i) => i.isCoreColor).toList(),
      1 => items.where((i) => i.isAura).toList(),
      _ => items.where((i) => i.isInventory).toList(),
    };

    // itemCount: 2 — [0] 탭 셀렉터, [1] 아이템 그리드
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.verticalMd,
      ),
      itemCount: 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.verticalMd),
            child: _buildTabSelector(),
          );
        }
        return _buildItemGrid(filtered);
      },
    );
  }

  // ── Tab Selector ─────────────────────────────────────────────────────────

  Widget _buildTabSelector() {
    return Container(
      padding: EdgeInsets.all(5.r),
      decoration: BoxDecoration(
        color: AppColors.dCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: AppColors.dLine, width: 1),
      ),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final selected = _selectedTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: 8.h),
                decoration: BoxDecoration(
                  color: selected ? AppColors.dAccent : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  _tabs[index],
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? const Color(0xFF160D06)
                        : AppColors.dMuted,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Item Grid ────────────────────────────────────────────────────────────

  Widget _buildItemGrid(List<ShopItem> items) {
    if (items.isEmpty) {
      return SizedBox(
        height: 120.h,
        child: Center(
          child: Text(
            '판매 중인 상품이 없어요.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.dMuted,
            ),
          ),
        ),
      );
    }

    // owned 여부 + hex 색상: myRoomProvider에서 조회
    final myRoomAsync = ref.watch(myRoomProvider);
    final ownedCodes = myRoomAsync.maybeWhen(
      data: (r) => r.colors.where((c) => c.owned).map((c) => c.code).toSet(),
      orElse: () => <String>{},
    );
    final hexMap = myRoomAsync.maybeWhen(
      data: (r) => {for (final c in r.colors) c.code: c.hex},
      orElse: () => <String, String>{},
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12.h,
        crossAxisSpacing: 12.w,
        childAspectRatio: 0.78,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isOwned = ownedCodes.contains(item.code);

        return ShopItemCard(
          item: item,
          isOwned: isOwned,
          isPurchasing: _purchasingItemId == item.itemId,
          hexColor: hexMap[item.code],
          onBuy: () => _onPurchase(item),
        );
      },
    );
  }

  // ── Purchase ─────────────────────────────────────────────────────────────

  Future<void> _onPurchase(ShopItem item) async {
    if (_purchasingItemId != null) return;
    setState(() => _purchasingItemId = item.itemId);

    try {
      final result = await ref.read(shopServiceProvider).purchase(item.itemId);
      if (!mounted) return;

      ref.read(userPointsProvider.notifier).set(result.currentTotalPoints);

      // hex map 구매 전 캡처 (invalidate 전)
      final hexMap = ref.read(myRoomProvider).maybeWhen(
        data: (r) => {for (final c in r.colors) c.code: c.hex},
        orElse: () => <String, String>{},
      );

      ref.invalidate(myRoomProvider);

      _logger.i(
          'Purchased: ${item.name}, pts left: ${result.currentTotalPoints}');

      if (mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: true,
          builder: (_) => PurchaseSuccessDialog(
            item: item,
            remainingPoints: result.currentTotalPoints,
            hexColor: hexMap[item.code],
          ),
        );
      }
    } on AppException catch (e) {
      if (mounted) {
        AppSnackBar.error(context, e.message);
      }
    } catch (e) {
      _logger.e('purchase unexpected error', error: e);
      if (mounted) {
        AppSnackBar.error(context, ErrorMessages.purchaseFailed);
      }
    } finally {
      if (mounted) setState(() => _purchasingItemId = null);
    }
  }
}
