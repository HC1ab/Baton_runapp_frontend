import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../models/lap_record_model.dart';
import '../../models/run_record_model.dart';

/// 우→좌 스와이프로 슬라이드 인되는 러닝 정보 풀스크린 패널.
/// 러닝 중이 아니면 메트릭을 숨기고 안내 문구만 표시.
class RunningInfoPanel extends StatelessWidget {
  const RunningInfoPanel({
    super.key,
    required this.record,
    required this.onClose,
  });

  final RunRecordModel record;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
          onClose();
        }
      },
      child: Container(
        color: const Color(0xF0141416),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: AppSpacing.verticalMd),

                // ── 헤더 ─────────────────────────────────────────────────────
                Row(
                  children: [
                    Text(
                      '러닝 정보',
                      style: AppTextStyles.headlineLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onClose,
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.dMuted,
                        size: 28.r,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: AppSpacing.verticalLg),

                if (!record.isRunning)
                  Expanded(
                    child: Center(
                      child: Text(
                        '러닝을 시작하면\n정보가 표시됩니다',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.dMuted,
                          height: 1.6,
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoRow(
                            label: '거리',
                            value:
                                '${(record.distanceMeters / 1000).toStringAsFixed(2)} km',
                          ),
                          _Divider(),
                          _InfoRow(
                            label: '시간',
                            value: _formatDuration(record.duration),
                          ),
                          _Divider(),
                          _InfoRow(
                            label: '현재 페이스',
                            value: record.formattedCurrentPace,
                          ),
                          _Divider(),
                          _InfoRow(
                            label: '평균 페이스',
                            value: record.formattedAveragePace,
                          ),
                          if (record.laps.isNotEmpty) ...[
                            _Divider(),
                            SizedBox(height: AppSpacing.verticalMd),
                            Text(
                              '랩',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.dMuted,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: AppSpacing.sm),
                            ...record.laps.reversed.map(
                              (lap) => _LapItem(lap: lap),
                            ),
                          ],
                          if (record.spotPoints > 0) ...[
                            _Divider(),
                            _InfoRow(
                              label: '스팟 포인트',
                              value:
                                  '${record.checkedInSpotIds.length}개 · +${record.spotPoints}P',
                              valueColor: AppColors.dAccentBright,
                            ),
                          ],
                          SizedBox(height: bottomPadding + AppSpacing.verticalLg),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.verticalMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.dMuted,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.headlineMedium.copyWith(
              color: valueColor ?? Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      color: AppColors.dLine,
      height: 1,
      thickness: 1,
    );
  }
}

class _LapItem extends StatelessWidget {
  const _LapItem({required this.lap});
  final LapRecord lap;

  @override
  Widget build(BuildContext context) {
    final m = lap.duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = lap.duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final pace = lap.duration.inSeconds > 0 && lap.distanceMeters > 0
        ? Duration(
            seconds: (lap.duration.inSeconds / (lap.distanceMeters / 1000))
                .round(),
          )
        : null;
    final paceStr = pace != null
        ? "${pace.inMinutes}'${(pace.inSeconds.remainder(60)).toString().padLeft(2, '0')}\""
        : '--';

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          Text(
            '${lap.lapNumber}',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.dMuted),
          ),
          SizedBox(width: AppSpacing.md),
          Text(
            '${(lap.distanceMeters / 1000).toStringAsFixed(2)} km',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
          ),
          const Spacer(),
          Text(
            '$m:$s',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
          ),
          SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 52.w,
            child: Text(
              paceStr,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.dMuted),
            ),
          ),
        ],
      ),
    );
  }
}
