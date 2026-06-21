import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 3×4 custom numeric keypad (1–9, ., 0, ⌫) that drives the amount entry on
/// the add-expense screen.
///
/// Built from nested [Expanded] rows/columns (rather than a GridView) so that
/// all twelve keys always lay out and fit whatever height the parent gives —
/// no row gets clipped on shorter screens.
class Numpad extends StatelessWidget {
  const Numpad({
    super.key,
    required this.onKey,
    required this.onBackspace,
  });

  /// Called with the tapped character ('0'–'9' or '.').
  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['.', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in _rows)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  for (final key in row)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _key(key),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _key(String label) {
    final onTap = label == '⌫' ? onBackspace : () => onKey(label);
    return Material(
      color: AppColors.bgSurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.bgSurface2),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppText.label(22, AppColors.textPrimary,
                weight: FontWeight.w300),
          ),
        ),
      ),
    );
  }
}
