import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final Widget? floatingActionButton;
  final bool resizeToAvoidBottomInset;
  final bool applySafeArea;
  final double bottomInset;

  const AppScaffold({
    super.key,
    required this.body,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset = true,
    this.applySafeArea = true,
    this.bottomInset = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final child = Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: body,
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      floatingActionButton: floatingActionButton,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [
                    Color(0xFF111827),
                    AppColors.bgDark,
                    Color(0xFF0B1020),
                  ]
                : const [
                    Color(0xFFF7F5FF),
                    AppColors.bgLight,
                    Color(0xFFF3FBFF),
                  ],
            stops: const [0, 0.45, 1],
          ),
        ),
        child: applySafeArea ? SafeArea(child: child) : child,
      ),
    );
  }
}
