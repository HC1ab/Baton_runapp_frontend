import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

import '../../../common/widgets/character_sphere_widget.dart';
import '../../../common/widgets/rarity_title_badge.dart';
import '../../../core/character/character_provider.dart';
import '../../../core/character/character_style.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/storage_keys.dart';
import '../constants/title_presets.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/utils/app_snack_bar.dart';
import '../services/my_room_service.dart';
import '../services/profile_service.dart';
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

  static const List<String> _tabs = [
    '코어 색상',
    '오라',
    '칭호',
    '인벤토리'
  ];

  @override
  Widget build(BuildContext context) {
    final currentStyle = ref.watch(selectedCharacterStyleProvider);

    return Scaffold(
      backgroundColor: AppColors.dScreen,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(22.w, 8.h, 22.w, 110.h),
          children: [
            _buildTitle(),
            SizedBox(height: 24.h),
            _buildHeroSphere(currentStyle),
            SizedBox(height: 20.h),
            _buildEquippedTitle(),
            SizedBox(height: 22.h),
            _buildShopBanner(),
            SizedBox(height: 22.h),
            _buildTabSelector(),
            SizedBox(height: 20.h),
            _buildTabContent(currentStyle),
          ],
        ),
      ),
    );
  }

  // ── Title ─────────────────────────────────────────────────────────────────

  Widget _buildTitle() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.only(right: 10.w, top: 4.h, bottom: 4.h),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.dText,
              size: 22.r,
            ),
          ),
        ),
        Text(
          '마이 룸',
          style: TextStyle(
            color: AppColors.dText,
            fontSize: 30.sp,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
      ],
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
          error: (_, _) => const SizedBox.shrink(),
          data: (myRoom) {
            final equipped =
                myRoom.titles.cast<MyRoomTitleItem?>().firstWhere(
                      (t) => t?.name == myRoom.equippedTitle,
                      orElse: () => null,
                    );
            return Column(
              children: [
                Text(
                  '장착된 칭호',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.dFaint,
                    fontSize: 11.sp,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 10.h),
                RarityTitleBadge(
                  title: myRoom.equippedTitle,
                  rarity: equipped?.rarity ?? 'NORMAL',
                  fontSize: 16.sp,
                ),
              ],
            );
          },
        );
  }

  Widget _buildShopBanner() {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.shop),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              AppColors.dAccent,
              Color(0xFFD9622A),
              AppColors.dAccentDeep,
            ],
          ),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          children: [
            Container(
              width: 44.r,
              height: 44.r,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(13.r),
              ),
              child: Icon(Icons.storefront_rounded,
                  color: Colors.white, size: 22.r),
            ),
            SizedBox(width: 13.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '상점',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '전용 아이템 구매하기',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.white, size: 24.r),
          ],
        ),
      ),
    );
  }

  // ── Tab Selector ────────────────────────────────────────────────────────

  Widget _buildTabSelector() {
    return Container(
      padding: EdgeInsets.all(5.r),
      decoration: BoxDecoration(
        color: AppColors.dCard,
        borderRadius: BorderRadius.circular(999.r),
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
                padding: EdgeInsets.symmetric(vertical: 9.h),
                decoration: BoxDecoration(
                  color: selected ? AppColors.dAccent : Colors.transparent,
                  borderRadius: BorderRadius.circular(999.r),
                ),
                child: Text(
                  _tabs[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w700,
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

  // ── Tab Content ─────────────────────────────────────────────────────────

  Widget _buildTabContent(CharacterStyle currentStyle) {
    return switch (_selectedTab) {
      0 => _buildCoreColorSection(currentStyle),
      2 => _buildTitlesSection(),
      _ => _buildComingSoon(),
    };
  }

  // ── Core Color Tab ───────────────────────────────────────────────────────

  Widget _buildCoreColorSection(CharacterStyle currentStyle) {
    return ref.watch(myRoomProvider).when(
          loading: () => SizedBox(
            height: 120.h,
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.dAccent),
            ),
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
        mainAxisSpacing: 15.h,
        crossAxisSpacing: 15.w,
        childAspectRatio: 1,
      ),
      itemCount: CharacterStylePresets.all.length,
      itemBuilder: (context, index) {
        final style = CharacterStylePresets.all[index];

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
              : () => isOwned ? _onColorTap(style) : _showLockedMessage(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isOwned ? style.baseColor : AppColors.dCard2,
              shape: BoxShape.circle,
              // Selected: inner screen ring + outer white ring (per redesign).
              boxShadow: isSelected
                  ? [
                      const BoxShadow(
                        color: Colors.white,
                        spreadRadius: 5,
                      ),
                      const BoxShadow(
                        color: AppColors.dScreen,
                        spreadRadius: 3,
                      ),
                    ]
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
                        ? Icon(Icons.lock_rounded,
                            color: AppColors.dFaint, size: 18.r)
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
            style: TextStyle(color: AppColors.dMuted, fontSize: 13.sp),
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

  Future<void> _onColorTap(CharacterStyle style) async {
    if (ref.read(selectedCharacterStyleProvider) == style) return;
    if (_isChangingColor) return;

    setState(() => _isChangingColor = true);
    try {
      final service = ref.read(myRoomServiceProvider);
      final confirmedCode = await service.changeCoreColor(style.code);
      if (!mounted) return;
      await ref
          .read(selectedCharacterStyleProvider.notifier)
          .setStyle(CharacterStylePresets.fromCode(confirmedCode));
      _logger.i('Core color changed: $confirmedCode');
    } on AppException catch (e) {
      if (mounted) {
        AppSnackBar.error(context, e.message);
      }
    } catch (e) {
      _logger.e('changeCoreColor unexpected error', error: e);
      if (mounted) {
        AppSnackBar.error(context, '색상 변경에 실패했어요. 다시 시도해주세요.');
      }
    } finally {
      if (mounted) setState(() => _isChangingColor = false);
    }
  }

  void _showLockedMessage() {
    AppSnackBar.info(context, '상점에서 구매 후 사용할 수 있어요.');
  }

  // ── Titles Tab ───────────────────────────────────────────────────────────

  Widget _buildTitlesSection() {
    return ref.watch(myRoomProvider).when(
          loading: () => SizedBox(
            height: 120.h,
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.dAccent),
            ),
          ),
          error: (e, _) => SizedBox(
            height: 120.h,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '칭호 목록을 불러오지 못했어요.',
                  style: TextStyle(color: AppColors.dMuted, fontSize: 13.sp),
                ),
                SizedBox(height: 8.h),
                TextButton(
                  onPressed: () => ref.invalidate(myRoomProvider),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
          data: (myRoom) {
            final titles = myRoom.titles;
            if (titles.isEmpty) {
              return SizedBox(
                height: 100.h,
                child: Center(
                  child: Text(
                    '칭호가 없어요.',
                    style:
                        TextStyle(color: AppColors.dMuted, fontSize: 13.sp),
                  ),
                ),
              );
            }
            return Column(
              children: titles
                  .map((t) => _buildTitleItem(t, myRoom.equippedTitle))
                  .toList(),
            );
          },
        );
  }

  Widget _buildTitleItem(MyRoomTitleItem title, String equippedTitle) {
    final isEquipped = equippedTitle == title.name;
    final isOwned = title.owned;
    final rarityColor = _rarityColor(title.rarity);
    final preset = TitlePresets.all.where((t) => t.id == title.titleId).firstOrNull;
    // 보너스 비율은 백엔드(allTitlesProvider)의 실제 값을 사용.
    // (TitlePresets는 비율이 0.0으로 하드코딩돼 있어 칩이 항상 +0%로 떴음)
    final titleInfo = ref
        .watch(allTitlesProvider)
        .value
        ?.where((t) => t.id == title.titleId)
        .firstOrNull;

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: GestureDetector(
        onTap: !isOwned || _isEquippingTitle || isEquipped
            ? null
            : () => _onEquipTitle(title),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: isEquipped
                ? AppColors.dAccent.withValues(alpha: 0.10)
                : !isOwned
                    ? AppColors.dCard2
                    : AppColors.dCard,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: isEquipped ? AppColors.dAccent : AppColors.dLine,
              width: isEquipped ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: Container(
                  width: 10.r,
                  height: 10.r,
                  decoration: BoxDecoration(
                    color: isOwned ? rarityColor : AppColors.dFaint,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title.name,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: isOwned
                                  ? AppColors.dText
                                  : AppColors.dMuted,
                            ),
                          ),
                        ),
                        Text(
                          title.rarity,
                          style: TextStyle(
                            color: isOwned ? rarityColor : AppColors.dFaint,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    if (title.description.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        title.description,
                        style: TextStyle(
                          color: AppColors.dFaint,
                          fontSize: 10.5.sp,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (preset != null) ...[
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          _BonusChip(
                            label: 'EXP',
                            value: titleInfo?.expBonusRatio ?? 0,
                            color: AppColors.dGold,
                            owned: isOwned,
                          ),
                          SizedBox(width: 6.w),
                          _BonusChip(
                            label: '포인트',
                            value: titleInfo?.pointBonusRatio ?? 0,
                            color: AppColors.dTitleBlue,
                            owned: isOwned,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              if (isEquipped)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: AppColors.dAccent,
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                  child: Text(
                    '착용',
                    style: TextStyle(
                      color: const Color(0xFF160D06),
                      fontWeight: FontWeight.w800,
                      fontSize: 9.sp,
                    ),
                  ),
                )
              else if (!isOwned)
                Icon(Icons.lock_rounded, size: 16.r, color: AppColors.dFaint)
              else
                Padding(
                  padding: EdgeInsets.only(top: 2.h),
                  child: Icon(Icons.chevron_right_rounded,
                      size: 20.r, color: AppColors.dMuted),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _rarityColor(String rarity) => switch (rarity) {
        'RARE' => AppColors.dTitleBlue,
        'EPIC' => AppColors.dAccentBright,
        'LEGENDARY' => AppColors.dGold,
        _ => AppColors.dMuted,
      };

  Future<void> _onEquipTitle(MyRoomTitleItem title) async {
    if (_isEquippingTitle) return;
    setState(() => _isEquippingTitle = true);
    try {
      await ref.read(titleServiceProvider).equipTitle(title.titleId);
      if (!mounted) return;
      // titleId → titleCode 변환 (TitlePresets는 id와 1:1 대응)
      final preset = TitlePresets.all.where((t) => t.id == title.titleId).firstOrNull;
      if (preset != null) {
        final prefs = ref.read(sharedPreferencesProvider);
        await prefs.setString(StorageKeys.equippedTitleCode, preset.titleCode);
        ref.invalidate(myEquippedTitleNameProvider);
      }
      ref.invalidate(myRoomProvider);
      ref.invalidate(profileProvider);
      _logger.i('Title equipped: ${title.name} (id=${title.titleId})');
    } on AppException catch (e) {
      if (mounted) {
        AppSnackBar.error(context, e.message);
      }
    } catch (e) {
      _logger.e('equipTitle unexpected error', error: e);
      if (mounted) {
        AppSnackBar.error(context, '칭호 장착에 실패했어요. 다시 시도해주세요.');
      }
    } finally {
      if (mounted) setState(() => _isEquippingTitle = false);
    }
  }

  // ── Coming Soon ──────────────────────────────────────────────────────────

  Widget _buildComingSoon() {
    return SizedBox(
      height: 100.h,
      child: Center(
        child: Text(
          '준비 중',
          style: TextStyle(color: AppColors.dMuted, fontSize: 14.sp),
        ),
      ),
    );
  }
}

// ── 보너스 칩 ─────────────────────────────────────────────────────────────────

class _BonusChip extends StatelessWidget {
  const _BonusChip({
    required this.label,
    required this.value,
    required this.color,
    required this.owned,
  });

  final String label;
  final double value;
  final Color color;
  final bool owned;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = owned ? color : AppColors.dFaint;
    final pct = value * 100;
    final text = pct == 0
        ? '$label +0%'
        : '$label +${pct % 1 == 0 ? pct.toInt() : pct.toStringAsFixed(1)}%';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: effectiveColor.withValues(alpha: 0.30)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9.5.sp,
          fontWeight: FontWeight.w700,
          color: effectiveColor,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
