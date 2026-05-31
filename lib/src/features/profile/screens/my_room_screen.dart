import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

import '../../../common/widgets/character_sphere_widget.dart';
import '../../../core/character/character_provider.dart';
import '../../../core/character/character_style.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/error/app_exception.dart';
import '../constants/title_presets.dart';
import '../services/my_room_service.dart';
import '../services/title_service.dart';

final _logger = Logger();

class MyRoomScreen extends ConsumerStatefulWidget {
  const MyRoomScreen({super.key});

  @override
  ConsumerState<MyRoomScreen> createState() => _MyRoomScreenState();
}

class _MyRoomScreenState extends ConsumerState<MyRoomScreen> {
  int _selectedTab = 0;
  bool _isChangingColor = false;
  bool _isEquippingTitle = false;

  static const List<String> _tabs = ['Core Colors', 'Aura', 'Titles'];

  @override
  Widget build(BuildContext context) {
    final currentStyle = ref.watch(selectedCharacterStyleProvider);

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
            _buildHeroSphere(currentStyle),
            SizedBox(height: AppSpacing.verticalMd),
            _buildEquippedTitle(),
            SizedBox(height: AppSpacing.verticalMd),
            _buildShopBanner(),
            SizedBox(height: AppSpacing.verticalMd),
            _buildTabSelector(),
            SizedBox(height: AppSpacing.verticalMd),
            _buildTabContent(currentStyle),
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

  Widget _buildHeroSphere(CharacterStyle style) {
    return Center(
      child: CharacterSphereWidget(style: style),
    );
  }

  Widget _buildEquippedTitle() {
    return ref.watch(myRoomProvider).when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (myRoom) => Column(
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
            myRoom.equippedTitle.isEmpty ? 'No Title' : myRoom.equippedTitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineLarge.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopBanner() {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.shop),
      child: _buildShopBannerContent(),
    );
  }

  Widget _buildShopBannerContent() {
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

  Widget _buildTabContent(CharacterStyle currentStyle) {
    return switch (_selectedTab) {
      0 => _buildCoreColorSection(currentStyle),
      2 => _buildTitleSection(),
      _ => _buildComingSoon(),
    };
  }

  // ── Core Color Tab ──────────────────────────────────────────────────────

  Widget _buildCoreColorSection(CharacterStyle currentStyle) {
    return ref.watch(myRoomProvider).when(
      loading: () => SizedBox(
        height: 120.h,
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => _buildColorError(),
      data: (myRoom) => _buildColorGrid(currentStyle, myRoom.colors),
    );
  }

  Widget _buildColorGrid(
    CharacterStyle currentStyle,
    List<MyRoomColorItem> apiColors,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12.h,
        crossAxisSpacing: 12.w,
        childAspectRatio: 1,
      ),
      itemCount: CharacterStylePresets.all.length,
      itemBuilder: (context, index) {
        final style = CharacterStylePresets.all[index];

        // API 응답에서 owned 상태 조회 — 없으면 CORE_ORANGE만 기본 소유
        final apiColor = apiColors.cast<MyRoomColorItem?>().firstWhere(
              (c) => c?.code == style.code,
              orElse: () => null,
            );
        final isOwned = apiColor?.owned ??
            (style.code == CharacterStylePresets.orange.code);
        final isSelected = currentStyle == style;

        return GestureDetector(
          onTap: _isChangingColor
              ? null
              : () => isOwned
                  ? _onColorTap(style)
                  : _showLockedMessage(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isOwned ? style.baseColor : AppColors.divider,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(
                      color: AppColors.textPrimary,
                      width: 2.5,
                    )
                  : null,
            ),
            child: _isChangingColor && isSelected
                ? Padding(
                    padding: EdgeInsets.all(10.r),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : isSelected
                    ? Icon(Icons.check_rounded, color: Colors.white, size: 24.r)
                    : !isOwned
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

  Widget _buildColorError() {
    return SizedBox(
      height: 120.h,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '색상 정보를 불러오지 못했어요.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          TextButton(
            onPressed: () => ref.invalidate(myRoomProvider),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  // ── Color Change ────────────────────────────────────────────────────────

  Future<void> _onColorTap(CharacterStyle style) async {
    // 이미 선택된 색상이면 무시
    if (ref.read(selectedCharacterStyleProvider) == style) return;
    if (_isChangingColor) return;

    setState(() => _isChangingColor = true);
    try {
      final service = ref.read(myRoomServiceProvider);
      final confirmedCode = await service.changeCoreColor(style.code);
      await ref
          .read(selectedCharacterStyleProvider.notifier)
          .setStyle(CharacterStylePresets.fromCode(confirmedCode));
      _logger.i('Core color changed: $confirmedCode');
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      _logger.e('changeCoreColor unexpected error', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('색상 변경에 실패했어요. 다시 시도해주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isChangingColor = false);
    }
  }

  void _showLockedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Baton Shop에서 구매 후 사용할 수 있어요.')),
    );
  }

  // ── Titles Tab ───────────────────────────────────────────────────────────

  Widget _buildTitleSection() {
    final titles = ref.watch(allTitlesProvider);
    return ref.watch(myRoomProvider).when(
      loading: () => SizedBox(
        height: 80.h,
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => SizedBox(
        height: 80.h,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '칭호 정보를 불러오지 못했어요.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8.h),
            TextButton(
              onPressed: () => ref.invalidate(myRoomProvider),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
      data: (myRoom) => _buildTitleList(titles, myRoom.equippedTitle),
    );
  }

  Widget _buildTitleList(List<TitleInfo> titles, String equippedTitle) {
    return Column(
      children: [
        for (final title in titles) ...[
          _buildTitleItem(title, title.name == equippedTitle),
          SizedBox(height: 10.h),
        ],
      ],
    );
  }

  Widget _buildTitleItem(TitleInfo title, bool isEquipped) {
    final icon = TitlePresets.iconFor(title.titleCode);
    final subtitle = TitlePresets.subtitleFor(title.titleCode);

    return GestureDetector(
      onTap: _isEquippingTitle ? null : () => _onTitleTap(title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: isEquipped
              ? AppColors.primary.withValues(alpha: 0.07)
              : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isEquipped
                ? AppColors.primary.withValues(alpha: 0.22)
                : AppColors.divider,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Icon ──────────────────────────────────────────────────
            Container(
              width: 38.r,
              height: 38.r,
              decoration: BoxDecoration(
                color: isEquipped
                    ? AppColors.primary.withValues(alpha: 0.14)
                    : AppColors.backgroundLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 18.r,
                color: isEquipped
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
            SizedBox(width: AppSpacing.sm),

            // ── Name + subtitle ────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.name,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isEquipped
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),

            // ── Right badge ────────────────────────────────────────────
            if (_isEquippingTitle && isEquipped)
              SizedBox(
                width: 18.r,
                height: 18.r,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            else if (isEquipped)
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  'ACTIVE',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 10.sp,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _onTitleTap(TitleInfo title) async {
    if (_isEquippingTitle) return;
    setState(() => _isEquippingTitle = true);
    try {
      await ref.read(titleServiceProvider).equipTitle(title.id);
      ref.invalidate(myRoomProvider);
      _logger.i('Equipped title: ${title.name}');
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
      _logger.e('equipTitle error', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('칭호 장착에 실패했어요. 다시 시도해주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isEquippingTitle = false);
    }
  }

  // ── Coming Soon ─────────────────────────────────────────────────────────

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
