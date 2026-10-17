import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../models/expense_category.dart';
import '../state/expense_store.dart';
import '../theme/app_theme.dart';

/// Transaction Log screen matching the Stitch "Daily Log" design (`a07768fab5d14bb6a099eef84602eb54`):
/// prominent "DAILY LOG" header with total amount, infinite scroll pagination,
/// square brutal category icons, red category tags, merchant name display, Anton amounts, and deletion support.
class TransactionLogScreen extends StatefulWidget {
  const TransactionLogScreen({super.key, required this.store});

  final ExpenseStore store;

  @override
  State<TransactionLogScreen> createState() => _TransactionLogScreenState();
}

class _TransactionLogScreenState extends State<TransactionLogScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (widget.store.hasMore && !widget.store.loadingMore) {
        widget.store.loadMore();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expenses = widget.store.expenses;
    final totalSpend = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final hasLoader = widget.store.loadingMore;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Container(
                padding: const EdgeInsets.only(bottom: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.borderBlack, width: 4),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'DAILY LOG',
                      style: AppText.headlineLg(color: AppColors.textPrimary),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'TOTAL',
                          style: AppText.labelBold(11, AppColors.textSecondary),
                        ),
                        Text(
                          '₹${widget.store.formatInr(totalSpend.round())}',
                          style: AppText.headlineSm(color: AppColors.primaryRed),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Transaction list with infinite scroll
            Expanded(
              child: expenses.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                      itemCount: expenses.length + (hasLoader ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == expenses.length) {
                          return _buildLoadingMoreTile();
                        }
                        final expense = expenses[index];
                        final category = ExpenseCategory.fromValue(expense.categoryKey);
                        return _buildTransactionItem(context, expense, category);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingMoreTile() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border.all(color: AppColors.borderBlack, width: 2),
        boxShadow: AppShadows.brutalBlackSm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primaryRed,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'LOADING OLDER ENTRIES...',
            style: AppText.labelBold(11, AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              border: Border.all(color: AppColors.borderBlack, width: 3),
              boxShadow: AppShadows.brutalBlackSm,
            ),
            child: const Icon(Icons.receipt_long, size: 36, color: AppColors.borderBlack),
          ),
          const SizedBox(height: 16),
          Text(
            'NO TRANSACTIONS YET',
            style: AppText.headlineSm(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Log an expense using the + button below',
            style: AppText.body(AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
      BuildContext context, Expense expense, ExpenseCategory category) {
    final hasCustomVendor = expense.vendor.isNotEmpty &&
        expense.vendor.toLowerCase() != expense.categoryKey.toLowerCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
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
          onLongPress: () => _confirmDelete(context, expense),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Square Icon Box
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.zero,
                    border: Border.all(color: AppColors.borderBlack, width: 2),
                  ),
                  child: Icon(
                    category.icon,
                    size: 24,
                    color: AppColors.borderBlack,
                  ),
                ),
                const SizedBox(width: 14),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Red category badge + Vendor tag
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryRed,
                              border: Border.all(
                                  color: AppColors.borderBlack, width: 1),
                            ),
                            child: Text(
                              category.label.toUpperCase(),
                              style: AppText.labelBold(10, AppColors.onPrimary),
                            ),
                          ),
                          if (hasCustomVendor) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainer,
                                  border: Border.all(
                                      color: AppColors.borderBlack, width: 1),
                                ),
                                child: Text(
                                  expense.vendor.toUpperCase(),
                                  style: AppText.labelBold(10, AppColors.textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        expense.description.isNotEmpty
                            ? expense.description.toUpperCase()
                            : (hasCustomVendor ? expense.vendor.toUpperCase() : category.label.toUpperCase()),
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

                // Amount
                Text(
                  '₹${widget.store.formatInr(expense.amount.round())}',
                  style: AppText.headlineSm(color: AppColors.textPrimary),
                ),

                // Delete Icon button
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: AppColors.textSecondary),
                  onPressed: () => _confirmDelete(context, expense),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceWhite,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.borderBlack, width: 3),
        ),
        title: Text('DELETE ENTRY',
            style: AppText.headlineSm(color: AppColors.textPrimary)),
        content: Text(
          'Delete "${expense.description}" (₹${widget.store.formatInr(expense.amount.round())})?',
          style: AppText.body(AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('CANCEL', style: AppText.labelBold(13, AppColors.textPrimary)),
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
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('DELETE', style: AppText.labelBold(13, AppColors.onPrimary)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.store.deleteExpense(expense.id);
    }
  }
}
