import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import '../models/onboarding_model.dart';
import 'floating_badge_card.dart';

class OnboardingSlideWidget extends StatelessWidget {
  final OnboardingSlide slide;
  final Animation<double> badgeAnimation;

  const OnboardingSlideWidget({
    super.key,
    required this.slide,
    required this.badgeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Área de Imagen + Badges
          SizedBox(
            height: 320,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (slide.image.isNotEmpty)
                  Image.asset(slide.image, height: 300, fit: BoxFit.contain),

                if (slide.badges != null)
                  ...slide.badges!.map((badge) => _buildBadge(badge)),
              ],
            ),
          ),

          const SizedBox(height: 48),

          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Color(0xFF023E8A),
              fontFamily: 'Satoshi',
            ),
          ),

          const SizedBox(height: 16),

          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              height: 1.5,
              fontWeight: FontWeight.w400,
              fontFamily: 'Satoshi',
            ),
          ),

          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildBadge(FloatingBadge badge) {
    Widget content = FloatingBadgeCard(badge: badge);

    // Animación de entrada
    if (badge.entranceAnimation == BadgeEntranceAnimation.fromLeft) {
      content = FadeInLeft(
        duration: const Duration(milliseconds: 600),
        from: 50,
        child: content,
      );
    } else if (badge.entranceAnimation == BadgeEntranceAnimation.fromRight) {
      content = FadeInRight(
        duration: const Duration(milliseconds: 600),
        from: 50,
        child: content,
      );
    }

    // Animación de levitación
    if (badge.animate) {
      return AnimatedBuilder(
        animation: badgeAnimation,
        builder: (context, child) {
          return Positioned(
            top: badge.top,
            left: badge.left,
            right: badge.right,
            bottom: badge.bottom,
            child: Transform.translate(
              offset: Offset(0, -badgeAnimation.value),
              child: content,
            ),
          );
        },
      );
    }

    return Positioned(
      top: badge.top,
      left: badge.left,
      right: badge.right,
      bottom: badge.bottom,
      child: content,
    );
  }
}
