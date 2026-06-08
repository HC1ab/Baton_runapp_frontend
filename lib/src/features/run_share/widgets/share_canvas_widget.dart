import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../models/run_share_data.dart';
import '../models/share_overlay_config.dart';
import '../models/stat_item_config.dart';
import '../providers/run_share_provider.dart';
import 'draggable_stat_widget.dart';

/// 공유 카드 캔버스.
/// [repaintKey]로 RepaintBoundary를 캡처해 이미지 저장에 사용.
/// 각 스탯은 [StatItemConfig.dx/dy] 비율 좌표로 독립 배치.
class ShareCanvasWidget extends ConsumerWidget {
  const ShareCanvasWidget({
    super.key,
    required this.repaintKey,
    required this.data,
    required this.config,
    this.backgroundImage,
  });

  final GlobalKey repaintKey;
  final RunShareData data;
  final ShareOverlayConfig config;
  final File? backgroundImage;

  String _value(String id) => switch (id) {
        'distance' => data.distanceText,
        'duration' => data.durationText,
        _ => data.paceText,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(runShareProvider.notifier);

    return RepaintBoundary(
      key: repaintKey,
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final canvasSize =
                  Size(constraints.maxWidth, constraints.maxHeight);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // ── 배경 ──────────────────────────────────────────────────
                  Positioned.fill(
                    child: GestureDetector(
                      // 배경 탭 → 선택 해제
                      onTap: () => notifier.selectStat(null),
                      child: _buildBackground(),
                    ),
                  ),

                  // ── 스탯 ──────────────────────────────────────────────────
                  for (final stat in config.stats)
                    if (stat.visible)
                      _buildStatItem(stat, canvasSize, config),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    StatItemConfig stat,
    Size canvasSize,
    ShareOverlayConfig config,
  ) {
    // dx/dy [0,1] → Alignment [-1,1]
    final alignment = Alignment(stat.dx * 2 - 1, stat.dy * 2 - 1);

    return Align(
      alignment: alignment,
      child: DraggableStatWidget(
        stat: stat,
        canvasSize: canvasSize,
        isSelected: config.selectedStatId == stat.id,
        value: _value(stat.id),
      ),
    );
  }

  Widget _buildBackground() {
    if (backgroundImage != null) {
      return Image.file(backgroundImage!, fit: BoxFit.cover);
    }
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight, AppColors.primaryDark],
        ),
      ),
    );
  }
}
