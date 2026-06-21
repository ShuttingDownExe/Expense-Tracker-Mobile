import 'package:flutter/material.dart';

import '../state/expense_store.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

/// "Spent Today" budget widget with the counter animation (0 → spend over
/// 1600ms, ease-out cubic) and the progress bar that grows with it.
class BudgetCard extends StatefulWidget {
  const BudgetCard({super.key, required this.store});

  final ExpenseStore store;

  @override
  State<BudgetCard> createState() => _BudgetCardState();
}

class _BudgetCardState extends State<BudgetCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    // 500ms delay after mount, matching the design.
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final spent = store.spentToday;
    final budget = store.budget;

    return AppCard(
      goldGlow: true,
      child: AnimatedBuilder(
        animation: _curve,
        builder: (context, _) {
          final t = _curve.value;
          final animatedSpent = spent * t;
          final pct =
              budget <= 0 ? 0.0 : (animatedSpent / budget).clamp(0.0, 1.0);
          final pctLabel = (pct * 100).round();
          final remaining = budget - animatedSpent;
          final isOver = animatedSpent > budget;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('SPENT TODAY', style: AppText.cardHeading),
                  Text('Budget ₹${store.formatInr(budget)}',
                      style: AppText.label(11, AppColors.textFaint)),
                ],
              ),
              const SizedBox(height: 6),
              // Big gold amount with ₹ prefix.
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('₹',
                      style: AppText.display(24)
                          .copyWith(color: AppColors.goldHalf, letterSpacing: 0)),
                  const SizedBox(width: 5),
                  Text(store.formatInr(animatedSpent.round()),
                      style: AppText.display(54)),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Text('of ₹${store.formatInr(budget)} budget',
                      style: AppText.label(12, AppColors.textFaint)),
                  const SizedBox(width: 8),
                  Container(
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                          color: AppColors.textGhost, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(
                    isOver
                        ? '↑ ₹${store.formatInr(remaining.abs().round())} over budget'
                        : '↓ ₹${store.formatInr(remaining.round())} remaining',
                    style: AppText.label(
                        12, isOver ? AppColors.red : AppColors.green),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Progress bar.
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: Stack(
                  children: [
                    Container(height: 3, color: const Color(0xFF1A1A1A)),
                    FractionallySizedBox(
                      widthFactor: pct,
                      child: Container(
                        height: 3,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.goldDeep, AppColors.gold],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 7),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$pctLabel% used',
                      style: AppText.label(11, AppColors.textGhost)),
                  Text('${_daysLeftInMonth()} days left',
                      style: AppText.label(11, AppColors.textGhost)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  int _daysLeftInMonth() {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    return lastDay - now.day;
  }
}
