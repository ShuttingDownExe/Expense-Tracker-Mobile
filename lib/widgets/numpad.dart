import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 3×4 Neo-Brutalist numeric keypad (1–9, ., 0, ⌫) for amount entry:
/// sharp 0px corners, 2px solid black borders, and 3px hard black offset shadows.
class Numpad extends StatelessWidget {
  const Numpad({
    super.key,
    required this.onKey,
    required this.onBackspace,
  });

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
    final isBackspace = label == '⌫';

    return Container(
      decoration: BoxDecoration(
        color: isBackspace ? AppColors.surfaceContainer : AppColors.surfaceWhite,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.borderBlack, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.borderBlack,
            offset: Offset(3, 3),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.primaryRed.withValues(alpha: 0.2),
          child: Container(
            alignment: Alignment.center,
            child: Text(
              label,
              style: isBackspace
                  ? const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)
                  : AppText.headlineSm(color: AppColors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
