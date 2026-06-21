import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Bottom tab bar with the floating gold "+" FAB that opens the add-expense
/// flow. Only Home is wired up; the other tabs are visual placeholders that
/// match the design.
class BottomNav extends StatelessWidget {
  const BottomNav({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      decoration: const BoxDecoration(
        color: AppColors.bgBlack,
        border: Border(top: BorderSide(color: AppColors.bgSurface2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _item(Icons.home_outlined, 'Home', active: true),
          _item(Icons.bar_chart, 'Stats'),
          _fab(),
          _item(Icons.history, 'History'),
          _item(Icons.person_outline, 'You'),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String label, {bool active = false}) {
    final color = active ? AppColors.gold : AppColors.textDark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 3),
        Text(label,
            style: AppText.label(10, color,
                weight: active ? FontWeight.w500 : FontWeight.w400)),
      ],
    );
  }

  Widget _fab() {
    return GestureDetector(
      onTap: onAdd,
      child: Transform.translate(
        offset: const Offset(0, -28),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.gold,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.bgBlack, width: 3),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFFC9A84C).withValues(alpha: 0.35),
                  blurRadius: 20),
              const BoxShadow(
                  color: Color(0x80000000), blurRadius: 16, offset: Offset(0, 4)),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.black, size: 24),
        ),
      ),
    );
  }
}
