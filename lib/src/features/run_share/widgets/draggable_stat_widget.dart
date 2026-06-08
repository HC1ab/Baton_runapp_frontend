import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../models/stat_item_config.dart';
import '../providers/run_share_provider.dart';

/// 드래그 이동 + 리사이즈 핸들 + 탭 선택 가능한 개별 스탯 위젯.
/// [canvasSize]를 받아 픽셀 delta → 비율 변환에 사용.
class DraggableStatWidget extends ConsumerWidget {
  const DraggableStatWidget({
    super.key,
    required this.stat,
    required this.canvasSize,
    required this.isSelected,
    required this.value,
  });

  final StatItemConfig stat;
  final Size canvasSize;
  final bool isSelected;
  final String value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(runShareProvider.notifier);

    return GestureDetector(
      // 탭 → 선택
      onTap: () => notifier.selectStat(stat.id),
      // 드래그 → 이동
      onPanUpdate: (details) => notifier.moveStat(
        stat.id,
        details.delta.dx / canvasSize.width,
        details.delta.dy / canvasSize.height,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        // Stack은 가장 큰 비-Positioned 자식 기준으로 크기 결정.
        // selected 시 Container에 margin 추가 → Stack 크기 확장 →
        // 핸들을 right:0/bottom:0에 배치해 hit test 범위 안에 들어오게 함.
        alignment: Alignment.topLeft,
        children: [
          // ── 스탯 텍스트 ────────────────────────────────────────────────────
          Container(
            // selected 시 핸들 영역(14.r)만큼 margin으로 Stack 확장
            margin: isSelected
                ? EdgeInsets.only(right: 14.r, bottom: 14.r)
                : null,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: isSelected
                ? BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.7),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                  )
                : null,
            child: Text(
              value,
              style: TextStyle(
                fontSize: stat.fontSize,
                fontWeight: FontWeight.w800,
                color: stat.color,
                letterSpacing: -1,
                height: 1.0,
                shadows: const [
                  Shadow(
                    color: Colors.black38,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),

          // ── 리사이즈 핸들 (선택 시만 표시) ─────────────────────────────────
          // right:0/bottom:0 → Stack 경계 안 → hit test 정상 작동
          if (isSelected)
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onPanUpdate: (details) =>
                    notifier.resizeStat(stat.id, details.delta.dy),
                child: Container(
                  width: 22.r,
                  height: 22.r,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.open_in_full_rounded,
                    size: 12.r,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
