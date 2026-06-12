import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/widgets/character_sphere_widget.dart';
import '../../../core/character/character_style.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

class GroupRunCard extends StatelessWidget {
  const GroupRunCard({
    super.key,
    required this.title,
    required this.time,
    required this.location,
    required this.currentMembers,
    required this.maxMembers,
    this.isHighlighted = false,
    this.participantColorCodes = const [],
    this.hostNickname,
    this.roomImageUrl,
    this.onJoinPressed,
  });

  final String title;
  final String time;
  final String location;
  final int currentMembers;
  final int maxMembers;
  final bool isHighlighted;
  final List<String> participantColorCodes;
  /// 방장 닉네임. 왼쪽 위 구체 표시용.
  /// TODO: API에 hostColorCode 추가되면 실제 색상 적용.
  final String? hostNickname;
  final String? roomImageUrl;
  final VoidCallback? onJoinPressed;

  static const Color _highlightedBackground = AppColors.cardHighlighted;
  static const Color _pointOrange = AppColors.socialAccent;

  @override
  Widget build(BuildContext context) {
    final cardBackground = isHighlighted ? _highlightedBackground : AppColors.dCard;
    final primaryTextColor = isHighlighted ? Colors.white : AppColors.dText;
    final secondaryTextColor =
        isHighlighted ? Colors.white.withValues(alpha: 0.85) : AppColors.dMuted;
    final dividerColor = isHighlighted
        ? Colors.white.withValues(alpha: 0.24)
        : AppColors.dLine;
    final badgeBackground = isHighlighted
        ? Colors.white.withValues(alpha: 0.18)
        : AppColors.dCard2;
    final joinButtonColor = isHighlighted ? Colors.white.withValues(alpha: 0.16) : _pointOrange;
    final joinButtonTextColor = Colors.white;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md * 0.7),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(24.r),
        border: isHighlighted
            ? null
            : Border.all(color: AppColors.dLine, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RoomHeader(
                title: title,
                titleColor: primaryTextColor,
                subtitleColor: secondaryTextColor,
                time: time,
                hostColorCode: 'CORE_ORANGE',
                isHighlighted: isHighlighted,
              ),
              SizedBox(width: 12.w),
              _MemberBadge(
                currentMembers: currentMembers,
                maxMembers: maxMembers,
                backgroundColor: badgeBackground,
                textColor: primaryTextColor,
              ),
            ],
          ),
          SizedBox(height: 7.h),
          Row(
            children: [
              Icon(Icons.location_on_rounded, size: 16.r, color: secondaryTextColor),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Divider(height: 1, thickness: 1, color: dividerColor),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: _ParticipantStack(
                  // 방장은 위쪽 구체로 표시되므로 나머지 참여자만 (currentMembers - 1).
                  // TODO: API에 participants[{coreColorCode}] 추가되면 실제 색상 반영.
                  colorCodes: participantColorCodes.isEmpty
                      ? List.filled((currentMembers - 1).clamp(0, 3), 'CORE_ORANGE')
                      : participantColorCodes
                          .skip(1)
                          .take(3)
                          .toList(),
                  borderColor: cardBackground,
                ),
              ),
              SizedBox(
                height: 26.h,
                child: FilledButton(
                  onPressed: onJoinPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: joinButtonColor,
                    foregroundColor: joinButtonTextColor,
                    disabledBackgroundColor: joinButtonColor.withValues(alpha: 0.5),
                    disabledForegroundColor: joinButtonTextColor.withValues(alpha: 0.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
                    textStyle: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('참여하기'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoomHeader extends StatelessWidget {
  const _RoomHeader({
    required this.title,
    required this.titleColor,
    required this.subtitleColor,
    required this.time,
    required this.hostColorCode,
    required this.isHighlighted,
  });

  final String title;
  final Color titleColor;
  final Color subtitleColor;
  final String time;
  /// TODO: API에 hostColorCode 추가되면 실제 값 사용. 현재 항상 'CORE_ORANGE'.
  final String hostColorCode;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final hostStyle = CharacterStylePresets.fromCode(hostColorCode);
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34.r,
            height: 34.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isHighlighted
                    ? Colors.white.withValues(alpha: 0.40)
                    : AppColors.dLine2,
                width: 1.5,
              ),
            ),
            child: ClipOval(
              child: CharacterSphereWidget(style: hostStyle, size: 34.r),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.access_time_filled_rounded, size: 14.r, color: subtitleColor),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        time,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                          color: subtitleColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberBadge extends StatelessWidget {
  const _MemberBadge({
    required this.currentMembers,
    required this.maxMembers,
    required this.backgroundColor,
    required this.textColor,
  });

  final int currentMembers;
  final int maxMembers;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        '$currentMembers/$maxMembers명',
        style: TextStyle(
          color: textColor,
          fontSize: 13.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ParticipantStack extends StatelessWidget {
  const _ParticipantStack({
    required this.colorCodes,
    required this.borderColor,
  });

  final List<String> colorCodes;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final visibleCount = colorCodes.length.clamp(0, 3);
    if (visibleCount == 0) {
      return SizedBox(height: 22.h);
    }

    return SizedBox(
      height: 22.r,
      width: 22.r + ((visibleCount - 1) * 13.r),
      child: Stack(
        children: List.generate(visibleCount, (index) {
          final style =
              CharacterStylePresets.fromCode(colorCodes[index]);
          return Positioned(
            left: index * 13.r,
            child: Container(
              width: 22.r,
              height: 22.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: ClipOval(
                child: CharacterSphereWidget(
                  style: style,
                  size: 22.r,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

