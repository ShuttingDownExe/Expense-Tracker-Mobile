import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Neo-Brutalist card container matching the Stitch Raw Ledger design system:
/// stark white surface, 0px border radius, 4px solid black border, and 4px hard black offset shadow.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.backgroundColor = AppColors.surfaceWhite,
    this.borderColor = AppColors.borderBlack,
    this.borderWidth = 4.0,
    this.shadowColor = AppColors.borderBlack,
    this.shadowOffset = const Offset(4, 4),
    this.goldGlow = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final Color shadowColor;
  final Offset shadowOffset;
  final bool goldGlow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            offset: shadowOffset,
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}
