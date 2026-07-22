import 'package:flutter/widgets.dart';

enum BadgeEntranceAnimation { none, fromLeft, fromRight }

class OnboardingSlide {
  final String title;
  final String description;
  final String image;
  final List<FloatingBadge>? badges;

  OnboardingSlide({
    required this.title,
    required this.description,
    required this.image,
    this.badges,
  });
}

class FloatingBadge {
  final IconData? icon;
  final String? svgPath;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final bool animate;
  final double? width;
  final double? height;
  final BadgeEntranceAnimation entranceAnimation;

  FloatingBadge({
    this.icon,
    this.svgPath,
    this.top,
    this.left,
    this.right,
    this.bottom,
    this.animate = true,
    this.width,
    this.height,
    this.entranceAnimation = BadgeEntranceAnimation.none,
  });
}
