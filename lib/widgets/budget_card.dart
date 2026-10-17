import 'package:flutter/material.dart';

import '../state/expense_store.dart';
import '../theme/app_theme.dart';

/// "Today's Spend" widget matching the Stitch "Raw Ledger" Neo-Brutalist design:
/// 4px solid black border, 4px hard black shadow, top-left bolt badge,
/// giant Anton currency display, heavy-bordered progress bar, and a tilted status badge.
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
      duration: const Duration(milliseconds: 1400),
    );
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    Future.delayed(const Duration(milliseconds: 300), () {
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

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main Brutal Card
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: AppColors.borderBlack, width: 4),
            boxShadow: AppShadows.brutalBlack,
          ),
          child: AnimatedBuilder(
            animation: _curve,
            builder: (context, _) {
              final t = _curve.value;
              final animatedSpent = spent * t;
              final pct = budget <= 0
                  ? 0.0
                  : (animatedSpent / budget).clamp(0.0, 1.0);
              final pctLabel = (pct * 100).round();
              final remaining = budget - animatedSpent;
              final isOver = animatedSpent > budget;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title row
                  Container(
                    padding: const EdgeInsets.only(bottom: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                            color: AppColors.borderBlack, width: 3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "TODAY'S SPEND",
                              style: AppText.headlineSm(
                                  color: AppColors.textPrimary),
                            ),
                            Text(
                              'SPENT TODAY',
                              style: AppText.labelBold(
                                  11, AppColors.textSecondary,
                                  spacing: 1.0),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => _showEditBudgetDialog(context, store),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainer,
                              border: Border.all(
                                  color: AppColors.borderBlack, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.edit,
                                    size: 12, color: AppColors.primaryRed),
                                const SizedBox(width: 4),
                                Text(
                                  'LIMIT: ₹${store.formatInr(budget.round())}',
                                  style: AppText.labelBold(
                                      11, AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Giant Currency display
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '₹${store.formatInr(animatedSpent.round())}',
                      style: AppText.displayCurrency(58,
                          color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Limit & Percentage row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'LIMIT: ₹${store.formatInr(budget.round())}',
                        style: AppText.labelBold(
                            13, AppColors.textPrimary),
                      ),
                      Text(
                        '$pctLabel%',
                        style: AppText.labelBold(
                            14,
                            isOver
                                ? AppColors.primaryRed
                                : AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Heavy Industrial Progress Bar
                  Container(
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      border: Border.all(
                          color: AppColors.borderBlack, width: 2),
                    ),
                    child: Stack(
                      children: [
                        FractionallySizedBox(
                          widthFactor: pct,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: AppColors.primaryRed,
                              border: Border(
                                right: BorderSide(
                                    color: AppColors.borderBlack, width: 2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Tilted Brutal Status Badge
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Transform.rotate(
                      angle: -0.02,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isOver
                              ? AppColors.primaryRed
                              : AppColors.borderBlack,
                          border: Border.all(
                              color: AppColors.borderBlack, width: 2),
                          boxShadow: isOver
                              ? AppShadows.brutalBlackSm
                              : AppShadows.brutalRed,
                        ),
                        child: Text(
                          isOver
                              ? '₹${store.formatInr(remaining.abs().round())} OVER BUDGET'
                              : '₹${store.formatInr(remaining.round())} UNDER BUDGET',
                          style: AppText.bodyLg(
                              color: AppColors.onPrimary,
                              weight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // Bolt Badge pinned at top-left
        Positioned(
          top: -12,
          left: -12,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primaryRed,
              border: Border.all(color: AppColors.borderBlack, width: 2),
              boxShadow: AppShadows.brutalBlackSm,
            ),
            child: const Icon(
              Icons.bolt,
              size: 18,
              color: AppColors.onPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showEditBudgetDialog(BuildContext context, ExpenseStore store) async {
    final controller = TextEditingController(text: store.budget.round().toString());
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceWhite,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: AppColors.borderBlack, width: 3),
        ),
        title: Text(
          'SET DAILY BUDGET',
          style: AppText.headlineSm(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your daily spending limit in INR:',
              style: AppText.bodySm(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderBlack, width: 2),
                color: AppColors.bgLight,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                autofocus: true,
                style: AppText.headlineSm(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  prefixText: '₹ ',
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL', style: AppText.labelBold(13, AppColors.textPrimary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: AppColors.onPrimary,
              shape: const RoundedRectangleBorder(
                side: BorderSide(color: AppColors.borderBlack, width: 2),
              ),
            ),
            onPressed: () {
              final newBudget = double.tryParse(controller.text.trim());
              if (newBudget != null && newBudget > 0) {
                store.updateBudget(newBudget);
                Navigator.pop(ctx);
              }
            },
            child: Text('SAVE', style: AppText.labelBold(13, AppColors.onPrimary)),
          ),
        ],
      ),
    );
  }
}
