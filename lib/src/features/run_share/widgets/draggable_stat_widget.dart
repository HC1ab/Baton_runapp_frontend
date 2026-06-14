import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../models/stat_item_config.dart';
import '../providers/run_share_provider.dart';

/// 드래그 이동 + 리사이즈 핸들 + 탭 선택 가능한 개별 스탯 위젯.
/// [canvasSize]를 받아 픽셀 delta → 비율 변환에 사용.
/// [prefixIcon]이 있으면 수치 왼쪽에 아이콘 표시 (NRC 스타일용).
/// [label]이 있으면 수치 위에 작은 한글 레이블 표시 (한글 스타일용).
class DraggableStatWidget extends ConsumerWidget {
  const DraggableStatWidget({
    super.key,
    required this.stat,
    required this.canvasSize,
    required this.isSelected,
    required this.value,
    this.prefixIcon,
    this.label,
    this.sublabel,
  });

  final StatItemConfig stat;
  final Size canvasSize;
  final bool isSelected;
  final String value;

  /// NRC 스타일: 수치 왼쪽에 표시할 아이콘
  final IconData? prefixIcon;

  /// 한글 스타일: 수치 위에 표시할 한글 레이블 (거리 / 시간 / 평균 페이스)
  final String? label;

  /// dark/orange 스타일: 수치 아래에 표시할 한글 서브라벨
  final String? sublabel;

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
            child: sublabel != null
                ? _SublabelStatContent(
                    sublabel: sublabel!,
                    value: value,
                    stat: stat,
                  )
                : label != null
                ? _KoreanStatContent(
                    label: label!,
                    value: value,
                    stat: stat,
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (prefixIcon != null) ...[
                        _NrcIcon(
                          icon: prefixIcon!,
                          size: (stat.fontSize * 0.75).clamp(12.0, 48.0),
                          color: stat.color.withValues(alpha: 0.85),
                        ),
                        SizedBox(width: (stat.fontSize * 0.2).clamp(3.0, 10.0)),
                      ],
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: stat.fontSize,
                          fontWeight: FontWeight.w600,
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
                    ],
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

// ── NRC 아이콘 (Icon.shadows 대신 Stack+ImageFiltered — drag 중 shadow 동기화) ──

class _NrcIcon extends StatelessWidget {
  const _NrcIcon({
    required this.icon,
    required this.size,
    required this.color,
  });

  final IconData icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // shadow 레이어 — 독립 위젯이므로 drag 중에도 icon과 함께 이동 보장
          Positioned(
            top: 1,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Icon(icon, color: Colors.black38, size: size),
            ),
          ),
          // 실제 아이콘
          Icon(icon, color: color, size: size),
        ],
      ),
    );
  }
}

// ── 한글 스타일 레이블 + 수치 ─────────────────────────────────────────────────

class _KoreanStatContent extends StatelessWidget {
  const _KoreanStatContent({
    required this.label,
    required this.value,
    required this.stat,
  });

  final String label;
  final String value;
  final StatItemConfig stat;

  @override
  Widget build(BuildContext context) {
    final labelSize = (stat.fontSize * 0.38).clamp(11.0, 20.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: labelSize,
            fontWeight: FontWeight.w600,
            color: stat.color.withValues(alpha: 0.75),
            letterSpacing: 0.5,
            height: 1.2,
            shadows: const [
              Shadow(color: Colors.black38, blurRadius: 6),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: stat.fontSize,
            fontWeight: FontWeight.w600,
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
      ],
    );
  }
}

// ── 서브라벨 (dark/orange): 값 크게, 아래 작은 설명 ─────────────────────────────

class _SublabelStatContent extends StatelessWidget {
  const _SublabelStatContent({
    required this.sublabel,
    required this.value,
    required this.stat,
  });

  final String sublabel;
  final String value;
  final StatItemConfig stat;

  @override
  Widget build(BuildContext context) {
    final sublabelSize = (stat.fontSize * 0.32).clamp(10.0, 16.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: stat.fontSize,
            fontWeight: FontWeight.w700,
            color: stat.color,
            letterSpacing: -1,
            height: 1.0,
            shadows: const [
              Shadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
        ),
        Text(
          sublabel,
          style: TextStyle(
            fontSize: sublabelSize,
            fontWeight: FontWeight.w500,
            color: stat.color.withValues(alpha: 0.65),
            letterSpacing: 0.2,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
