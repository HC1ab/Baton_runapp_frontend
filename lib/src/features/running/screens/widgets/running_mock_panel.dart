import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Developer-only panel for simulating GPS movement.
/// Only rendered when _isDev is true — never shown in production builds.
class RunningMockPanel extends StatelessWidget {
  const RunningMockPanel({
    super.key,
    required this.stepMeters,
    required this.isAutoWalk,
    required this.isBusy,
    required this.onChangeStep,
    required this.onToggleAutoWalk,
    required this.onNudgeNorth,
  });

  final double stepMeters;
  final bool isAutoWalk;
  final bool isBusy;
  final ValueChanged<double> onChangeStep;
  final VoidCallback onToggleAutoWalk;
  final VoidCallback onNudgeNorth;

  // pace label helper: stepMeters is m/s → pace = 60 / (m/s * 3.6)
  String _paceLabel(double ms) {
    if (ms <= 0) return '--';
    final pace = 60 / (ms * 3.6);
    final min = pace.floor();
    final sec = ((pace - min) * 60).round();
    return "$min'${sec.toString().padLeft(2, '0')}\"";
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🛠  Mock Runner',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
              if (isAutoWalk) const _BlinkingDot(),
            ],
          ),
          SizedBox(height: AppSpacing.sm),

          // Speed label
          Text(
            '속도: ${stepMeters.toStringAsFixed(2)} m/s  (${_paceLabel(stepMeters)} /km)',
            style: AppTextStyles.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: AppSpacing.sm),

          // Speed selector
          SegmentedButton<double>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 2.77, label: Text("6'00")),
              ButtonSegment(value: 3.33, label: Text("5'00")),
              ButtonSegment(value: 4.16, label: Text("4'00")),
              ButtonSegment(value: 5.55, label: Text("3'00")),
            ],
            selected: {stepMeters},
            onSelectionChanged: isBusy ? null : (s) => onChangeStep(s.first),
          ),
          SizedBox(height: AppSpacing.sm),

          // Controls
          Row(
            children: [
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: isBusy ? null : onToggleAutoWalk,
                  style: FilledButton.styleFrom(
                    backgroundColor: isAutoWalk
                        ? scheme.errorContainer
                        : scheme.primaryContainer,
                    foregroundColor: isAutoWalk
                        ? scheme.error
                        : scheme.onPrimaryContainer,
                  ),
                  icon: Icon(
                    isAutoWalk ? Icons.pause_circle : Icons.play_circle,
                    size: 18.r,
                  ),
                  label: Text(isAutoWalk ? '중단' : '자동 이동'),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              IconButton.filledTonal(
                onPressed: isBusy ? null : onNudgeNorth,
                icon: Icon(Icons.north, size: 18.r),
                tooltip: '북쪽으로 한 걸음',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BlinkingDot extends StatefulWidget {
  const _BlinkingDot();

  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 8.r,
        height: 8.r,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
