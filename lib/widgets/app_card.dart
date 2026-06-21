import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The surface card used across the dashboard: #0D0D0D fill, subtle border,
/// 22pt radius and the layered dark-mode shadow from the design tokens.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.goldGlow = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// The budget card carries an extra ambient gold glow.
  final bool goldGlow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          const BoxShadow(
            color: Color(0x99000000), // rgba(0,0,0,.6)
            blurRadius: 32,
            offset: Offset(0, 4),
          ),
          if (goldGlow)
            BoxShadow(
              color: const Color(0xFFC9A84C).withValues(alpha: 0.07),
              blurRadius: 50,
            ),
        ],
      ),
      child: child,
    );
  }
}
