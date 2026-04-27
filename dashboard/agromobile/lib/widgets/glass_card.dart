import 'package:flutter/material.dart';

import '../theme/app_radius.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color startColor;
  final Color endColor;
  final double borderOpacity;
  final double blurStrength;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.startColor = const Color(0xFF111C2E),
    this.endColor = const Color(0xFF0B1221),
    this.borderOpacity = 0.12,
    this.blurStrength = 18,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? AppRadius.cardRadius,
        border: Border.all(
          color: Colors.white.withValues(alpha: borderOpacity),
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            startColor.withValues(alpha: 0.86),
            endColor.withValues(alpha: 0.92),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: blurStrength + 10,
            offset: const Offset(0, 16),
            spreadRadius: -8,
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return cardContent;
    return GestureDetector(onTap: onTap, child: cardContent);
  }
}
