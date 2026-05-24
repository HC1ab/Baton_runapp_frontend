import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';

class MyRoomScreen extends ConsumerStatefulWidget {
  const MyRoomScreen({super.key});

  @override
  ConsumerState<MyRoomScreen> createState() => _MyRoomScreenState();
}

class _MyRoomScreenState extends ConsumerState<MyRoomScreen> {
  int _selectedTab = 0;
  int _selectedColorIdx = 0;

  static const List<Color?> _coreColors = [
    Color(0xFFBB6B4D), // dark coral
    Color(0xFFE8936A), // salmon
    Color(0xFF8CB87A), // sage green
    Color(0xFF87B3D3), // sky blue
    Color(0xFFE8C55A), // yellow
    Color(0xFFB39BC8), // lavender
    Color(0xFF6BB8A6), // teal
    null,              // locked
  ];

  static const List<String> _tabs = ['Core Colors', 'Aura', 'Titles'];

  Color get _selectedColor =>
      _coreColors[_selectedColorIdx] ?? AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.verticalSm,
            AppSpacing.screenHorizontal,
            AppSpacing.verticalXl,
          ),
          children: [
            _buildAppBar(),
            SizedBox(height: AppSpacing.xs),
            _buildSubtitle(),
            SizedBox(height: AppSpacing.verticalLg),
            _buildHeroSphere(),
            SizedBox(height: AppSpacing.verticalMd),
            _buildEquippedTitle(),
            SizedBox(height: AppSpacing.verticalMd),
            _buildShopBanner(),
            SizedBox(height: AppSpacing.verticalMd),
            _buildTabSelector(),
            SizedBox(height: AppSpacing.verticalMd),
            _buildTabContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Text(
      'My Room',
      style: AppTextStyles.headlineMedium.copyWith(
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'Customize your core sphere and identity.',
      style: AppTextStyles.bodySmall.copyWith(
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildHeroSphere() {
    final double size = 180.r;
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Base — color target
            // TODO: replace child with Image.asset('assets/character_base.png', fit: BoxFit.contain)
            ColorFiltered(
              colorFilter: ColorFilter.mode(_selectedColor, BlendMode.srcATop),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
            // 2. Shadow — dark shading (fixed, multiply blend)
            // TODO: Image.asset('assets/character_shadow.png', fit: BoxFit.contain)
            const SizedBox.shrink(),
            // 3. Highlight — bright highlight (fixed)
            // TODO: Image.asset('assets/character_highlight.png', fit: BoxFit.contain)
            const SizedBox.shrink(),
            // 4. Outline (fixed)
            // TODO: Image.asset('assets/character_outline.png', fit: BoxFit.contain)
            const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _buildEquippedTitle() {
    return Column(
      children: [
        Text(
          'EQUIPPED TITLE',
          textAlign: TextAlign.center,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'Dawn Runner',
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineLarge.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildShopBanner() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 14.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: 20.r,
            ),
          ),
          SizedBox(width: AppSpacing.sm + AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Baton Shop',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'GET EXCLUSIVE ITEMS',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.white,
            size: 24.r,
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
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
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  _tabs[index],
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent() {
    return switch (_selectedTab) {
      0 => _buildCoreColorGrid(),
      _ => _buildComingSoon(),
    };
  }

  Widget _buildCoreColorGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12.h,
        crossAxisSpacing: 12.w,
        childAspectRatio: 1,
      ),
      itemCount: _coreColors.length,
      itemBuilder: (context, index) {
        final color = _coreColors[index];
        final isSelected = _selectedColorIdx == index;
        final isLocked = color == null;

        return GestureDetector(
          onTap: isLocked
              ? null
              : () => setState(() => _selectedColorIdx = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isLocked ? AppColors.divider : color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(
                      color: AppColors.textPrimary,
                      width: 2.5,
                    )
                  : null,
            ),
            child: isSelected
                ? Icon(Icons.check_rounded, color: Colors.white, size: 24.r)
                : isLocked
                    ? Icon(
                        Icons.lock_rounded,
                        color: AppColors.textSecondary,
                        size: 18.r,
                      )
                    : null,
          ),
        );
      },
    );
  }

  Widget _buildComingSoon() {
    return SizedBox(
      height: 100.h,
      child: Center(
        child: Text(
          'Coming soon',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
