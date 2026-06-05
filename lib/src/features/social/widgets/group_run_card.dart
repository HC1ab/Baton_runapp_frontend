import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    this.participantImageUrls = const [],
    this.roomImageUrl,
    this.onJoinPressed,
  });

  final String title;
  final String time;
  final String location;
  final int currentMembers;
  final int maxMembers;
  final bool isHighlighted;
  final List<String> participantImageUrls;
  final String? roomImageUrl;
  final VoidCallback? onJoinPressed;

  static const Color _highlightedBackground = AppColors.cardHighlighted;
  static const Color _pointOrange = AppColors.socialAccent;
  static const Color _darkText = AppColors.textPrimary;
  static const Color _lightBadgeBackground = AppColors.scaffoldGrey;

  @override
  Widget build(BuildContext context) {
    final cardBackground = isHighlighted ? _highlightedBackground : Colors.white;
    final primaryTextColor = isHighlighted ? Colors.white : _darkText;
    final secondaryTextColor = isHighlighted ? Colors.white : Colors.black54;
    final dividerColor = isHighlighted
        ? Colors.white.withValues(alpha: 0.24)
        : Colors.black12;
    final badgeBackground = isHighlighted
        ? Colors.white.withValues(alpha: 0.18)
        : _lightBadgeBackground;
    final joinButtonColor = isHighlighted ? Colors.white.withValues(alpha: 0.16) : _pointOrange;
    final joinButtonTextColor = Colors.white;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md * 0.7),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(24.r),
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
                roomImageUrl: roomImageUrl,
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
                  imageUrls: participantImageUrls,
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
    required this.roomImageUrl,
    required this.isHighlighted,
  });

  final String title;
  final Color titleColor;
  final Color subtitleColor;
  final String time;
  final String? roomImageUrl;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CircularImage(
            size: 34.r,
            imageUrl: roomImageUrl,
            fallbackColor: isHighlighted
                ? Colors.white.withValues(alpha: 0.20)
                : AppColors.socialAccent,
            iconColor: Colors.white,
            iconSize: 14.r,
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
    required this.imageUrls,
    required this.borderColor,
  });

  final List<String> imageUrls;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final visibleCount = imageUrls.length.clamp(0, 3);
    if (visibleCount == 0) {
      return SizedBox(height: 22.h);
    }

    return SizedBox(
      height: 22.r,
      width: 22.r + ((visibleCount - 1) * 13.r),
      child: Stack(
        children: List.generate(visibleCount, (index) {
          return Positioned(
            left: index * 13.r,
            child: _CircularImage(
              size: 22.r,
              imageUrl: imageUrls[index],
              fallbackColor: AppColors.scaffoldGrey,
              iconColor: AppColors.iconNeutral,
              iconSize: 11.r,
              borderColor: borderColor,
            ),
          );
        }),
      ),
    );
  }
}

class _CircularImage extends StatelessWidget {
  const _CircularImage({
    required this.size,
    required this.imageUrl,
    required this.fallbackColor,
    required this.iconColor,
    required this.iconSize,
    this.borderColor,
  });

  final double size;
  final String? imageUrl;
  final Color fallbackColor;
  final Color iconColor;
  final double iconSize;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: borderColor != null ? Border.all(color: borderColor!, width: 1.5) : null,
      ),
      child: ClipOval(
        child: hasImage
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: fallbackColor,
      alignment: Alignment.center,
      child: Icon(Icons.person_rounded, color: iconColor, size: iconSize),
    );
  }
}
