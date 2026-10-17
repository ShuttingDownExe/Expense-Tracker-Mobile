import 'package:flutter/material.dart';

import '../state/expense_store.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

/// Monthly budget calendar matching the Stitch Raw Ledger Neo-Brutalist design:
/// sharp square cells, month navigation arrows (‹ and ›), 4px black card border,
/// 4px brutal shadow, over-budget highlighting.
class BudgetCalendar extends StatefulWidget {
  const BudgetCalendar({super.key, required this.store});

  final ExpenseStore store;

  @override
  State<BudgetCalendar> createState() => _BudgetCalendarState();
}

class _BudgetCalendarState extends State<BudgetCalendar> {
  late DateTime _selectedMonth;

  static const _headers = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
  }

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    });
  }

  void _resetToCurrentMonth() {
    final now = DateTime.now();
    setState(() {
      _selectedMonth = DateTime(now.year, now.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth = _selectedMonth.year == now.year && _selectedMonth.month == now.month;
    final today = isCurrentMonth ? now.day : -1;

    final overDays = widget.store.getOverBudgetDaysFor(_selectedMonth.year, _selectedMonth.month);

    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_selectedMonth.year, _selectedMonth.month, 1).weekday; // 1=Mon
    final leadingBlanks = firstWeekday - 1;
    final rowCount = ((leadingBlanks + daysInMonth) / 7).ceil();

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row with Month Navigation Controls
          Container(
            padding: const EdgeInsets.only(bottom: 10),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.borderBlack, width: 2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _navButton(icon: Icons.chevron_left, onTap: _prevMonth, tooltip: 'Previous Month'),
                    const SizedBox(width: 8),
                    Text(
                      '${_months[_selectedMonth.month - 1].toUpperCase()} ${_selectedMonth.year}',
                      style: AppText.headlineSm(color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 8),
                    _navButton(icon: Icons.chevron_right, onTap: _nextMonth, tooltip: 'Next Month'),
                  ],
                ),
                Row(
                  children: [
                    if (!isCurrentMonth) ...[
                      GestureDetector(
                        onTap: _resetToCurrentMonth,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            border: Border.all(color: AppColors.borderBlack, width: 1.5),
                          ),
                          child: Text(
                            'TODAY',
                            style: AppText.labelBold(10, AppColors.textPrimary),
                          ),
                        ),
                      ),
                    ],
                    if (overDays.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed,
                          border: Border.all(color: AppColors.borderBlack, width: 1.5),
                        ),
                        child: Text(
                          '${overDays.length} OVER BUDGET',
                          style: AppText.labelBold(10, AppColors.onPrimary),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Day headers
          Row(
            children: [
              for (final h in _headers)
                Expanded(
                  child: Center(
                    child: Text(
                      h,
                      style: AppText.labelBold(12, AppColors.textPrimary),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),

          // Day cells grid
          for (var r = 0; r < rowCount; r++) ...[
            if (r > 0) const SizedBox(height: 4),
            Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(
                    child: _dayCell(
                      r * 7 + c - leadingBlanks + 1,
                      daysInMonth,
                      today,
                      overDays,
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),

          // Legend
          Row(
            children: [
              _legend(AppColors.primaryRed, 'OVER BUDGET'),
              const SizedBox(width: 16),
              _legend(AppColors.borderBlack, 'TODAY'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navButton({required IconData icon, required VoidCallback onTap, required String tooltip}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          border: Border.all(color: AppColors.borderBlack, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: AppColors.textPrimary),
      ),
    );
  }

  static const double _cellHeight = 32;

  Widget _dayCell(int day, int daysInMonth, int today, Set<int> overDays) {
    if (day < 1 || day > daysInMonth) {
      return const SizedBox(height: _cellHeight);
    }
    final isToday = day == today;
    final isOver = overDays.contains(day);

    Color bg = AppColors.surfaceWhite;
    Color border = AppColors.surfaceVariant;
    Color fg = AppColors.textPrimary;

    if (isToday) {
      bg = AppColors.borderBlack;
      border = AppColors.borderBlack;
      fg = AppColors.onPrimary;
    } else if (isOver) {
      bg = const Color(0xFFFFEBEE);
      border = AppColors.primaryRed;
      fg = AppColors.primaryRed;
    }

    return Container(
      height: _cellHeight,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color: border,
          width: (isToday || isOver) ? 1.5 : 1.0,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '$day',
        style: AppText.labelBold(13, fg),
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: AppColors.borderBlack, width: 1),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppText.labelBold(10, AppColors.textSecondary),
        ),
      ],
    );
  }
}
