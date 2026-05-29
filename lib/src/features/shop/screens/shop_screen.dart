import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:logger/logger.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/error/app_exception.dart';
import '../../profile/services/my_room_service.dart';
import '../../profile/services/title_service.dart';
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
  int _selectedTab = 0;
  int? _purchasingItemId;

  static const _tabs = ['All Items', 'Sphere Colors', 'Sphere Shapes'];

  @override
  Widget build(BuildContext context) {
    final points = ref.watch(userPointsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
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

  // ── Header ──────────────────────────────────────────────────────────────

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
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_rounded,
                size: 16.r,
                color: AppColors.textPrimary,
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

  // ── States ───────────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildError(Object e, StackTrace _) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '상품 목록을 불러오지 못했어요.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
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
    final filtered = _filteredItems(items);

    return ListView(
      padding: EdgeInsets.only(bottom: AppSpacing.verticalXl),
      children: [
        // Weekly Special
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
          child: _buildWeeklySpecial(),
        ),
        SizedBox(height: AppSpacing.verticalSm),

        // Info Banners
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
          child: _buildInfoBanners(),
        ),
        SizedBox(height: AppSpacing.verticalMd),

        // Tab Selector
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
          child: _buildTabSelector(),
        ),
        SizedBox(height: AppSpacing.verticalMd),

        // Item Grid
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
          child: _buildItemGrid(filtered),
        ),

        // Progress Banner
        if (items.isNotEmpty) ...[
          SizedBox(height: AppSpacing.verticalMd),
          Padding(
            padding:
                EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
            child: _buildProgressBanner(items),
          ),
        ],
      ],
    );
  }

  // ── Weekly Special Card ──────────────────────────────────────────────────

  Widget _buildWeeklySpecial() {
    return Container(
      height: 120.h,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight,
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circle (background accent)
          Positioned(
            right: -20.w,
            top: -20.h,
            child: Container(
              width: 100.r,
              height: 100.r,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 10.w,
            bottom: -30.h,
            child: Container(
              width: 80.r,
              height: 80.r,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  'WEEKLY SPECIAL',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    fontSize: 9.sp,
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Solar Flare Aura',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6.h),
              Row(
                children: [
                  Icon(Icons.bolt_rounded, color: Colors.white, size: 16.r),
                  SizedBox(width: 2.w),
                  Text(
                    '1,200 pts',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Info Banners ─────────────────────────────────────────────────────────

  Widget _buildInfoBanners() {
    return Column(
      children: [
        _buildStreakBanner(),
        SizedBox(height: 10.h),
        _buildMysteryBox(),
      ],
    );
  }

  Widget _buildStreakBanner() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 12.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Streak',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '5 Days · 1.2× Points Multiplier',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.local_fire_department_rounded,
            color: AppColors.warning,
            size: 28.r,
          ),
        ],
      ),
    );
  }

  Widget _buildMysteryBox() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 12.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mystery Box',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Unlock a random shape',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(
              '400 pts',
              style: AppTextStyles.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab Selector ─────────────────────────────────────────────────────────

  Widget _buildTabSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final selected = _selectedTab == index;
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 8.h,
                ),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  boxShadow: [
                    BoxShadow(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.3)
                          : Colors.black.withValues(alpha: 0.05),
                      blurRadius: selected ? 8 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _tabs[index],
                  style: AppTextStyles.labelSmall.copyWith(
                    color: selected ? Colors.white : AppColors.textSecondary,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
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
            '상품이 없어요.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    // Check owned status from MyRoom colors
    final myRoomAsync = ref.watch(myRoomProvider);
    final ownedCodes = myRoomAsync.maybeWhen(
      data: (r) => r.colors.where((c) => c.owned).map((c) => c.code).toSet(),
      orElse: () => <String>{},
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
        final isOwned =
            item.isCoreColor && ownedCodes.contains(item.code);

        return ShopItemCard(
          item: item,
          isOwned: isOwned,
          isPurchasing: _purchasingItemId == item.itemId,
          onBuy: () => _onPurchase(item),
        );
      },
    );
  }

  // ── Progress Banner ──────────────────────────────────────────────────────

  Widget _buildProgressBanner(List<ShopItem> items) {
    // Show the most expensive item as a goal
    final goal = items.reduce(
      (a, b) => a.price > b.price ? a : b,
    );
    final points = ref.read(userPointsProvider);
    final diff = goal.price - points;

    if (diff <= 0) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 12.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 32.r,
            height: 32.r,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.directions_run_rounded,
              color: AppColors.success,
              size: 16.r,
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You\'re $diff pts away',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Keep running to unlock \'${goal.name}\'!',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab Filter ───────────────────────────────────────────────────────────

  List<ShopItem> _filteredItems(List<ShopItem> items) {
    return switch (_selectedTab) {
      0 => items, // All Items
      1 => items.where((i) => i.isCoreColor).toList(), // Sphere Colors
      2 => items.where((i) => !i.isCoreColor).toList(), // Sphere Shapes
      _ => items,
    };
  }

  // ── Purchase ─────────────────────────────────────────────────────────────

  Future<void> _onPurchase(ShopItem item) async {
    if (_purchasingItemId != null) return;
    setState(() => _purchasingItemId = item.itemId);

    try {
      final result =
          await ref.read(shopServiceProvider).purchase(item.itemId);

      // Update points
      ref.read(userPointsProvider.notifier).set(result.currentTotalPoints);

      // Refresh MyRoom if color item (owned status changes)
      if (item.isCoreColor) {
        ref.invalidate(myRoomProvider);
      }

      _logger.i('Purchased: ${item.name}, pts left: ${result.currentTotalPoints}');

      // 칭호 아이템: titleCode → TitleInfo.id 조회
      int? titleId;
      if (item.isTitle) {
        final titles = ref.read(allTitlesProvider);
        titleId = titles
            .cast<TitleInfo?>()
            .firstWhere(
              (t) => t?.titleCode == item.code,
              orElse: () => null,
            )
            ?.id;
        if (titleId == null) {
          _logger.w('titleId not found for code: ${item.code}');
        }
      }

      if (mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: true,
          builder: (_) => PurchaseSuccessDialog(
            item: item,
            remainingPoints: result.currentTotalPoints,
            titleId: titleId,
          ),
        );
      }
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
      _logger.e('purchase unexpected error', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('구매에 실패했어요. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _purchasingItemId = null);
    }
  }
}
