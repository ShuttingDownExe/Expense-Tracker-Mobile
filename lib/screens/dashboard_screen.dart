import 'package:flutter/material.dart';

import '../models/expense_category.dart';
import '../state/expense_store.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/budget_calendar.dart';
import '../widgets/budget_card.dart';
import '../widgets/weekly_graph.dart';
import 'add_expense_screen.dart';
import 'transaction_log_screen.dart';

/// Screen 1 — Dashboard & Navigation Hub matching the Stitch "Daily Budget Tracker" (Raw Ledger) design.
/// Features a brutalist header, 3-tab navigation, Today's Spend card, Alerts & Subscriptions card,
/// Weekly Trend graph, Recent Entries list, and the Transaction Log tab.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.store, this.onSignOut});

  final ExpenseStore store;
  final Future<void> Function()? onSignOut;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    widget.store.load();
  }

  Future<void> _openAddExpense() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(store: widget.store),
        fullscreenDialog: true,
      ),
    );
    if (created == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: widget.store,
          builder: (context, _) {
            final store = widget.store;

            if (_currentTab == 2) {
              return TransactionLogScreen(store: store);
            }

            return Stack(
              children: [
                Column(
                  children: [
                    _header(),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 90),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            BudgetCard(store: store),
                            const SizedBox(height: 18),
                            WeeklyGraph(store: store),
                            const SizedBox(height: 18),
                            _recentEntries(store),
                            const SizedBox(height: 18),
                            BudgetCalendar(store: store),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Error banner (Neo-brutalist)
                if (!store.loading && store.error != null)
                  Positioned(
                    top: 70,
                    left: 18,
                    right: 18,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.alertYellow,
                        border: Border.all(
                            color: AppColors.borderBlack, width: 3),
                        boxShadow: AppShadows.brutalBlackSm,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber,
                              color: AppColors.primaryRed, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              store.error!,
                              style: AppText.body(AppColors.textPrimary,
                                  weight: FontWeight.w700),
                            ),
                          ),
                          TextButton(
                            onPressed: () => store.load(),
                            child: Text('RETRY',
                                style: AppText.labelBold(
                                    12, AppColors.primaryRed)),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Loading indicator overlay
                if (store.loading)
                  Positioned.fill(
                    child: Container(
                      color: AppColors.bgLight.withValues(alpha: 0.75),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceWhite,
                            border: Border.all(
                                color: AppColors.borderBlack, width: 3),
                            boxShadow: AppShadows.brutalBlack,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: AppColors.primaryRed,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'SYNCING LEDGER...',
                                style: AppText.labelBold(
                                    13, AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentTab,
        onTabSelected: (tab) => setState(() => _currentTab = tab),
        onAdd: _openAddExpense,
      ),
    );
  }

  Widget _header() {
    final store = widget.store;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: const BoxDecoration(
        color: AppColors.bgLight,
        border: Border(
          bottom: BorderSide(color: AppColors.borderBlack, width: 4),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  border: Border.all(color: AppColors.borderBlack, width: 2),
                  boxShadow: AppShadows.brutalBlackSm,
                ),
                child: const Icon(Icons.menu,
                    size: 22, color: AppColors.textPrimary),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'EXPENSE_ROOT',
                        style: AppText.headlineSm(color: AppColors.primaryRed),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Good morning,',
                        style: AppText.label(11, AppColors.textSecondary,
                            weight: FontWeight.w600),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        store.userName,
                        style: AppText.labelBold(12, AppColors.textPrimary),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: widget.onSignOut == null ? null : _confirmSignOut,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primaryRed,
                border: Border.all(color: AppColors.borderBlack, width: 2),
                boxShadow: AppShadows.brutalBlackSm,
              ),
              alignment: Alignment.center,
              child: Text(
                store.userInitial,
                style: AppText.labelBold(16, AppColors.onPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Recent Entries section matching Stitch Raw Ledger
  Widget _recentEntries(ExpenseStore store) {
    final recent = store.expenses.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 8),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.borderBlack, width: 3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RECENT ENTRIES',
                style: AppText.labelBold(13, AppColors.textPrimary),
              ),
              GestureDetector(
                onTap: () => setState(() => _currentTab = 2),
                child: Text(
                  'VIEW ALL ›',
                  style: AppText.labelBold(12, AppColors.primaryRed),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        for (final expense in recent)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
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
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    border: Border.all(color: AppColors.borderBlack, width: 2),
                  ),
                  child: Icon(
                    ExpenseCategory.fromValue(expense.categoryKey).icon,
                    size: 20,
                    color: AppColors.borderBlack,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (expense.vendor.isNotEmpty &&
                                expense.vendor.toLowerCase() !=
                                    expense.categoryKey.toLowerCase())
                            ? '${expense.vendor.toUpperCase()} · ${expense.description.toUpperCase()}'
                            : expense.description.toUpperCase(),
                        style: AppText.bodyLg(color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        expense.date,
                        style: AppText.label(11, AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${store.formatInr(expense.amount.round())}',
                  style: AppText.headlineSm(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _confirmSignOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceWhite,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.borderBlack, width: 3),
        ),
        title: Text('SIGN OUT', style: AppText.headlineSm()),
        content: Text(
          'You will need to sign in again to sync your expenses.',
          style: AppText.body(AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCEL',
                style: AppText.labelBold(13, AppColors.textPrimary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: AppColors.onPrimary,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(color: AppColors.borderBlack, width: 2),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('SIGN OUT',
                style: AppText.labelBold(13, AppColors.onPrimary)),
          ),
        ],
      ),
    );
    if (shouldSignOut == true) await widget.onSignOut?.call();
  }
}
