import 'package:flutter/material.dart';

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
    this.startColor = const Color(0xFF111C2E), // More neutral dark blue
    this.endColor = const Color(0xFF0B1221), // Darker shade
    this.borderOpacity = 0.1,
    this.blurStrength = 16,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Wrap in GestureDetector if onTap is provided
    Widget cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(borderOpacity),
          width: 1.0,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            startColor.withOpacity(0.85),
            endColor.withOpacity(0.90),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: cardContent,
      );
    }
    return cardContent;
  }
}
