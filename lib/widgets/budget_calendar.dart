import 'package:flutter/material.dart';

import '../state/expense_store.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

/// Monthly budget calendar. Over-budget days are tinted red, today is gold
/// with a ring outline. The grid starts on Monday to match the design.
class BudgetCalendar extends StatelessWidget {
  const BudgetCalendar({super.key, required this.store});

  final ExpenseStore store;

  static const _headers = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December' //
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = now.day;
    final overDays = store.overBudgetDays;

    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstWeekday = DateTime(now.year, now.month, 1).weekday; // 1=Mon
    final leadingBlanks = firstWeekday - 1;

    // Build up to 35 cells (5 rows × 7).
    final cells = <Widget>[];
    for (var i = 0; i < 35; i++) {
      final dayNum = i - leadingBlanks + 1;
      if (dayNum < 1 || dayNum > daysInMonth) {
        cells.add(const SizedBox.shrink());
        continue;
      }
      cells.add(_dayCell(dayNum, dayNum == today, overDays.contains(dayNum)));
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_months[now.month - 1]} ${now.year}',
                  style: AppText.sectionTitle),
              Row(
                children: [
                  if (overDays.isNotEmpty)
                    Text('${overDays.length} over budget',
                        style: AppText.label(12, AppColors.red)),
                  const SizedBox(width: 10),
                  const Text('‹ ',
                      style: TextStyle(color: AppColors.textGhost, fontSize: 16)),
                  const Text('›',
                      style: TextStyle(color: Color(0xFF777777), fontSize: 16)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final h in _headers)
                Expanded(
                  child: Center(
                    child: Text(h,
                        style: AppText.label(10, AppColors.textGhost,
                            weight: FontWeight.w500)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            childAspectRatio: 1.05,
            children: cells,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _legend(AppColors.red, 'Over budget'),
              const SizedBox(width: 16),
              _legend(AppColors.gold, 'Today'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dayCell(int day, bool isToday, bool isOver) {
    final Color bg = isToday
        ? AppColors.goldCell
        : isOver
            ? AppColors.redCell
            : Colors.transparent;
    final Color fg = isToday
        ? AppColors.gold
        : isOver
            ? AppColors.red
            : AppColors.textSecondary;
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: isToday
            ? Border.all(color: AppColors.goldRing, width: 1.5)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        '$day',
        style: AppText.label(12, fg,
            weight: (isToday || isOver) ? FontWeight.w600 : FontWeight.w400),
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: AppText.label(10, const Color(0xFF444444))),
      ],
    );
  }
}
