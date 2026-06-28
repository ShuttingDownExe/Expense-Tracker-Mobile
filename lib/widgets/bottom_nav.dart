import 'dart:ui';

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Floating "liquid glass" bottom bar — a translucent, blurred pill that hovers
/// above the screen bottom (Apple-style). It holds the Dashboard and History
/// icons flanking the central gold "+" action.
///
/// For the frosted-glass blur to show the content behind it, the screen must
/// set `extendBody: true` on its Scaffold so the body renders under this bar.
class BottomNav extends StatelessWidget {
  const BottomNav({super.key, required this.onAdd});

  /// Opens the add-expense flow when the central "+" is tapped.
  final VoidCallback onAdd;

  static const double _height = 68;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Padding(
      // Float the pill: inset from the sides and lifted off the bottom edge
      // (clearing the home indicator).
      padding: EdgeInsets.fromLTRB(28, 0, 28, 10 + bottomInset),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_height / 2),
        child: BackdropFilter(
          // The actual frosted-glass blur of whatever scrolls behind it.
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            height: _height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_height / 2),
              // Faint translucent fill + a soft top highlight gives the glassy
              // sheen over the blur.
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.10),
                  Colors.white.withValues(alpha: 0.04),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.14),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(child: _item(Icons.home_outlined, active: true)),
                _addButton(),
                Expanded(child: _item(Icons.history)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(IconData icon, {bool active = false}) {
    final color = active ? AppColors.gold : AppColors.textSecondary;
    return Icon(icon, size: 30, color: color);
  }

  /// The central gold "+" — its own glassy gold circle inside the pill.
  Widget _addButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC9A84C).withValues(alpha: 0.45),
              blurRadius: 18,
            ),
          ],
        ),
        child: Material(
          color: AppColors.gold,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onAdd,
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 54,
              height: 54,
              child: Icon(Icons.add, color: Colors.black, size: 32),
            ),
          ),
        ),
      ),
    );
  }
}
