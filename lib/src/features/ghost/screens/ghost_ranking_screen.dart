import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/error/app_exception.dart';
import '../providers/ghost_providers.dart';
import 'ghost_record_detail_screen.dart';

/// 고스트 탭 진입 화면 — 동네별 부문(1K/3K/5K/10K) 페이스 TOP3 랭킹.
class GhostRankingScreen extends ConsumerStatefulWidget {
  const GhostRankingScreen({super.key});

  @override
  ConsumerState<GhostRankingScreen> createState() => _GhostRankingScreenState();
}

class _GhostRankingScreenState extends ConsumerState<GhostRankingScreen> {
  String _category = '1K';

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final rankingAsync = ref.watch(ghostRankingProvider(_category));
    final dong = rankingAsync.value?.dong ?? '';

    return Scaffold(
      backgroundColor: AppColors.dScreen,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 헤더 ────────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(22.w, topPadding + 8.h, 22.w, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GHOST',
                  style: TextStyle(
                    color: AppColors.dAccent,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  dong.isEmpty ? '우리 동네 랭킹' : '$dong 랭킹',
                  style: TextStyle(
                    color: AppColors.dText,
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '부문별 페이스 TOP 3 · 기록을 눌러 도전하세요',
                  style: TextStyle(
                    color: AppColors.dMuted,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // ── 부문 토글 ────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 22.w),
            child: _CategoryToggle(
              selected: _category,
              onChanged: (c) => setState(() => _category = c),
            ),
          ),
          SizedBox(height: 18.h),

          // ── 랭킹 목록 ────────────────────────────────────────────────────
          Expanded(
            child: rankingAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.dAccent),
              ),
              error: (e, _) => _buildStatus(
                icon: Icons.wrong_location_rounded,
                title: '랭킹을 불러오지 못했어요',
                subtitle: e is AppException ? e.message : '잠시 후 다시 시도해 주세요',
                onRetry: () => ref.invalidate(ghostRankingProvider(_category)),
              ),
              data: (ranking) {
                if (ranking.entries.isEmpty) {
                  return _buildStatus(
                    icon: Icons.emoji_events_outlined,
                    title: '아직 $_category 기록이 없어요',
                    subtitle: '첫 기록의 주인공이 되어보세요!',
                  );
                }
                return RefreshIndicator(
                  color: AppColors.dAccent,
                  backgroundColor: AppColors.dCard,
                  onRefresh: () async =>
                      ref.invalidate(ghostRankingProvider(_category)),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(22.w, 0, 22.w, 110.h),
                    itemCount: ranking.entries.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (_, i) {
                      final entry = ranking.entries[i];
                      return _RankCard(
                        entry: entry,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => GhostRecordDetailScreen(
                              rankingId: entry.rankingId,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatus({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onRetry,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48.r, color: AppColors.dAccent.withValues(alpha: 0.35)),
          SizedBox(height: 16.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.dText,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: 8.h),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.dMuted, fontSize: 13.sp),
            ),
          ],
          if (onRetry != null) ...[
            SizedBox(height: 16.h),
            TextButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ],
      ),
    );
  }
}

// ── 부문 토글 (1K / 3K / 5K / 10K) ──────────────────────────────────────────────
class _CategoryToggle extends StatelessWidget {
  const _CategoryToggle({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(5.r),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E21),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: AppColors.dLine2, width: 1),
      ),
      child: Row(
        children: [
          for (final c in ghostCategories) Expanded(child: _segment(c)),
        ],
      ),
    );
  }

  Widget _segment(String category) {
    final isSel = selected == category;
    return GestureDetector(
      onTap: () => onChanged(category),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(vertical: 10.h),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSel ? AppColors.dAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Text(
          category,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
            color: isSel ? Colors.white : AppColors.dMuted,
          ),
        ),
      ),
    );
  }
}

// ── 랭킹 카드 ───────────────────────────────────────────────────────────────────
class _RankCard extends StatelessWidget {
  const _RankCard({required this.entry, required this.onTap});

  final GhostRankingEntry entry;
  final VoidCallback onTap;

  static const _gold = Color(0xFFE0A437);
  static const _silver = Color(0xFFB8C0CC);
  static const _bronze = Color(0xFFCD8A56);

  Color get _rankColor => switch (entry.rankNo) {
        1 => _gold,
        2 => _silver,
        3 => _bronze,
        _ => AppColors.dFaint,
      };

  @override
  Widget build(BuildContext context) {
    final isFirst = entry.rankNo == 1;
    return InkWell(
      borderRadius: BorderRadius.circular(20.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: AppColors.dCard,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isFirst ? _gold.withValues(alpha: 0.5) : AppColors.dLine,
            width: isFirst ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // 등수 메달
            Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                color: _rankColor.withValues(alpha: 0.16),
                shape: BoxShape.circle,
                border: Border.all(color: _rankColor.withValues(alpha: 0.6)),
              ),
              alignment: Alignment.center,
              child: Text(
                '${entry.rankNo}',
                style: TextStyle(
                  color: _rankColor,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            SizedBox(width: 14.w),

            // 닉네임 + 거리
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.nickname.isEmpty ? '러너 #${entry.recordId}' : entry.nickname,
                    style: TextStyle(
                      color: AppColors.dText,
                      fontSize: 15.5.sp,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${entry.distanceKm.toStringAsFixed(2)} km',
                    style: TextStyle(
                      color: AppColors.dFaint,
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),

            // 페이스 (강조)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  entry.paceText,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '/km',
                  style: TextStyle(
                    color: AppColors.dFaint,
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(width: 4.w),
            Icon(Icons.chevron_right_rounded, color: AppColors.dFaint, size: 22.r),
          ],
        ),
      ),
    );
  }
}
