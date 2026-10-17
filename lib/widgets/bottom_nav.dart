import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 3-Tab Neo-Brutalist Bottom Navigation matching the Stitch "Daily Budget Tracker" design:
/// 4px solid black top border, stark background, active tab in solid primary red with white text,
/// and inactive tabs in black text with vertical dividing borders.
class BottomNav extends StatelessWidget {
  const BottomNav({
    super.key,
    required this.onAdd,
    this.currentIndex = 0,
    this.onTabSelected,
  });

  /// Opens the add-expense flow when the central "+" / ADD is tapped.
  final VoidCallback onAdd;
  final int currentIndex;
  final ValueChanged<int>? onTabSelected;

  static const double _height = 70;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      height: _height + bottomInset,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.bgLight,
        border: Border(
          top: BorderSide(color: AppColors.borderBlack, width: 4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tab 0: DASHBOARD
          Expanded(
            child: _tabItem(
              index: 0,
              icon: Icons.grid_view,
              label: 'DASHBOARD',
              isActive: currentIndex == 0,
              onTap: () => onTabSelected?.call(0),
              showRightBorder: true,
            ),
          ),

          // Tab 1: ADD (Central action)
          Expanded(
            child: _tabItem(
              index: 1,
              icon: Icons.add,
              label: 'ADD',
              isActive: currentIndex == 1,
              onTap: onAdd,
              showRightBorder: true,
              isHighlight: true,
            ),
          ),

          // Tab 2: LOG (Transactions)
          Expanded(
            child: _tabItem(
              index: 2,
              icon: Icons.receipt_long,
              label: 'LOG',
              isActive: currentIndex == 2,
              onTap: () => onTabSelected?.call(2),
              showRightBorder: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required bool showRightBorder,
    bool isHighlight = false,
  }) {
    final Color bg = isActive ? AppColors.primaryRed : Colors.transparent;
    final Color fg = isActive ? AppColors.onPrimary : AppColors.textPrimary;

    return Material(
      color: bg,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.primaryRed.withValues(alpha: 0.2),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              right: showRightBorder
                  ? const BorderSide(color: AppColors.borderBlack, width: 2)
                  : BorderSide.none,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 26, color: fg),
              const SizedBox(height: 3),
              Text(
                label,
                style: AppText.labelBold(11, fg, spacing: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
