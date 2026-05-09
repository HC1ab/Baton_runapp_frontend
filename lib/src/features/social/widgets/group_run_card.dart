import 'package:flutter/material.dart';

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

  static const Color _highlightedBackground = Color(0xFFBA3B10);
  static const Color _pointOrange = Color(0xFFF7673B);
  static const Color _darkText = Color(0xFF1E1E1E);
  static const Color _lightBadgeBackground = Color(0xFFF0F0F0);

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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(24),
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
              const SizedBox(width: 12),
              _MemberBadge(
                currentMembers: currentMembers,
                maxMembers: maxMembers,
                backgroundColor: badgeBackground,
                textColor: primaryTextColor,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.location_on_rounded, size: 16, color: secondaryTextColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, thickness: 1, color: dividerColor),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ParticipantStack(
                  imageUrls: participantImageUrls,
                  borderColor: cardBackground,
                ),
              ),
              SizedBox(
                height: 36,
                child: FilledButton(
                  onPressed: onJoinPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: joinButtonColor,
                    foregroundColor: joinButtonTextColor,
                    disabledBackgroundColor: joinButtonColor.withValues(alpha: 0.5),
                    disabledForegroundColor: joinButtonTextColor.withValues(alpha: 0.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    textStyle: const TextStyle(
                      fontSize: 14,
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
            size: 48,
            imageUrl: roomImageUrl,
            fallbackColor: isHighlighted
                ? Colors.white.withValues(alpha: 0.20)
                : const Color(0xFFF7673B),
            iconColor: Colors.white,
            iconSize: 20,
          ),
          const SizedBox(width: 10),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.access_time_filled_rounded, size: 14, color: subtitleColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        time,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$currentMembers/$maxMembers명',
        style: TextStyle(
          color: textColor,
          fontSize: 13,
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
      return const SizedBox(height: 32);
    }

    return SizedBox(
      height: 32,
      width: 32 + ((visibleCount - 1) * 18),
      child: Stack(
        children: List.generate(visibleCount, (index) {
          return Positioned(
            left: index * 18,
            child: _CircularImage(
              size: 32,
              imageUrl: imageUrls[index],
              fallbackColor: Colors.grey.shade300,
              iconColor: Colors.grey.shade700,
              iconSize: 16,
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
