import 'package:flutter/material.dart';

import '../state/expense_store.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/budget_calendar.dart';
import '../widgets/budget_card.dart';
import '../widgets/glass_loading.dart';
import '../widgets/weekly_graph.dart';
import 'add_expense_screen.dart';

/// Screen 1 — the dashboard. Header greeting, budget card, weekly graph and
/// monthly calendar stacked in a single column, with the bottom tab bar.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.store, this.onSignOut});

  final ExpenseStore store;

  /// Present when signed in via Firebase; null in preview mode.
  final Future<void> Function()? onSignOut;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
      setState(() {}); // refresh derived figures after a new expense
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBlack,
      // Let the body scroll behind the floating glass pill so its blur has
      // content to frost.
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: widget.store,
          builder: (context, _) {
            final store = widget.store;
            return Stack(
              children: [
                Column(
                  children: [
                    _header(),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        // Extra bottom padding so the last card clears the
                        // floating glass pill.
                        padding: const EdgeInsets.fromLTRB(22, 14, 22, 130),
                        child: Column(
                          children: [
                            BudgetCard(store: store),
                            const SizedBox(height: 14),
                            WeeklyGraph(store: store),
                            const SizedBox(height: 14),
                            BudgetCalendar(store: store),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Error banner (when a fetch failed) pinned below the header.
                if (!store.loading && store.error != null)
                  Positioned(
                    top: 8,
                    left: 16,
                    right: 16,
                    child: GlassErrorBanner(
                      message: store.error!,
                      onRetry: () => store.load(),
                    ),
                  ),
                // Frosted loading overlay, fading out once data arrives.
                Positioned.fill(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: store.loading
                        ? const GlassLoadingOverlay()
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNav(onAdd: _openAddExpense),
    );
  }

  Widget _header() {
    final store = widget.store;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good morning,',
                  style: AppText.label(13, AppColors.textMuted)),
              const SizedBox(height: 1),
              Text(store.userName, style: AppText.screenTitle),
            ],
          ),
          Row(
            children: [
              // Notification bell button.
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderFaint),
                ),
                child: const Icon(Icons.notifications_none,
                    size: 22, color: AppColors.textMuted),
              ),
              const SizedBox(width: 12),
              // Avatar with gold ring + initial.
              GestureDetector(
                onTap: widget.onSignOut == null ? null : _confirmSignOut,
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.goldTint12,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.goldBorder, width: 1.5),
                  ),
                  child: Text(store.userInitial,
                      style: AppText.label(16, AppColors.gold,
                          weight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        title: Text('Sign out?', style: AppText.sectionTitle),
        content: Text('You will need to sign in again.',
            style: AppText.body(AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: AppText.label(14, AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sign out', style: AppText.label(14, AppColors.gold)),
          ),
        ],
      ),
    );
    if (shouldSignOut == true) await widget.onSignOut?.call();
  }
}
