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

    // Exactly the rows this month needs (5 or 6) — no trailing blank row.
    final rowCount = ((leadingBlanks + daysInMonth) / 7).ceil();

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
                        style: AppText.dense(13, AppColors.red)),
                  const SizedBox(width: 10),
                  const Text('‹ ',
                      style: TextStyle(color: AppColors.textGhost, fontSize: 19)),
                  const Text('›',
                      style: TextStyle(color: Color(0xFF777777), fontSize: 19)),
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
                        style: AppText.dense(15, AppColors.textGhost,
                            weight: FontWeight.w500)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          // Manual 7-column grid: a Column of week Rows with fixed-height
          // cells. Avoids GridView, which over-sized its own height here and
          // left a dead band below the dates.
          for (var r = 0; r < rowCount; r++) ...[
            if (r > 0) const SizedBox(height: 4),
            Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(
                    child: _dayCell(
                        r * 7 + c - leadingBlanks + 1, daysInMonth, today, overDays),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
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

  static const double _cellHeight = 38;

  Widget _dayCell(int day, int daysInMonth, int today, Set<int> overDays) {
    // Leading/trailing blanks keep their slot so columns stay aligned.
    if (day < 1 || day > daysInMonth) {
      return const SizedBox(height: _cellHeight);
    }
    final isToday = day == today;
    final isOver = overDays.contains(day);
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
      height: _cellHeight,
      margin: const EdgeInsets.symmetric(horizontal: 2),
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
        style: AppText.dense(18, fg,
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
        Text(label, style: AppText.dense(13, const Color(0xFF888888))),
      ],
    );
  }
}
