import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/onboarding_model.dart';

class FloatingBadgeCard extends StatelessWidget {
  final FloatingBadge badge;

  const FloatingBadgeCard({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: badge.width,
      height: badge.height,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: badge.svgPath != null
          ? SvgPicture.asset(badge.svgPath!, fit: BoxFit.contain)
          : Center(
              child: Icon(badge.icon, color: const Color(0xFF023E8A), size: 28),
            ),
    );
  }
}
