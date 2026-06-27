import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Bottom tab bar: Dashboard and History flanking the central add button.
/// The "+" button itself is a [AddExpenseFab] placed via
/// `Scaffold.floatingActionButton` (centerDocked) so its whole area is
/// tappable — see DashboardScreen.
class BottomNav extends StatelessWidget {
  const BottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      decoration: const BoxDecoration(
        color: AppColors.bgBlack,
        border: Border(top: BorderSide(color: AppColors.bgSurface2)),
      ),
      child: Row(
        children: [
          Expanded(child: _item(Icons.home_outlined, 'Dashboard', active: true)),
          const SizedBox(width: 72), // gap for the docked FAB
          Expanded(child: _item(Icons.history, 'History')),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String label, {bool active = false}) {
    final color = active ? AppColors.gold : AppColors.textDark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 26, color: color),
        const SizedBox(height: 3),
        Text(label,
            style: AppText.label(10, color,
                weight: active ? FontWeight.w500 : FontWeight.w400)),
      ],
    );
  }
}

/// The floating gold "+" button that opens the add-expense flow. Rendered as a
/// 56pt circle with a ripple, a black ring, and the gold glow from the design.
class AddExpenseFab extends StatelessWidget {
  const AddExpenseFab({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFC9A84C).withValues(alpha: 0.35),
              blurRadius: 20),
          const BoxShadow(
              color: Color(0x80000000), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Material(
        color: AppColors.gold,
        shape: const CircleBorder(
            side: BorderSide(color: AppColors.bgBlack, width: 3)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: 56,
            height: 56,
            child: Icon(Icons.add, color: Colors.black, size: 28),
          ),
        ),
      ),
    );
  }
}
