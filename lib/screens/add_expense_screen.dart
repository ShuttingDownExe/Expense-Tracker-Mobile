import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../models/expense_category.dart';
import '../services/api_service.dart';
import '../state/expense_store.dart';
import '../theme/app_theme.dart';
import '../widgets/numpad.dart';
import 'qr_scanner_screen.dart';

/// Screen 2 — Add Expense flow matching the Stitch Raw Ledger design:
/// sharp 0px inputs, 4px/2px black borders, hard offset shadows,
/// giant Anton currency display, brutal category chips, and custom numpad.
class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, required this.store});

  final ExpenseStore store;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  String _amount = '0';
  ExpenseCategory? _category;
  final _descController = TextEditingController();
  final _vendorController = TextEditingController();
  bool _saving = false;

  DateTime _date = DateTime.now();
  static final _dateLabelFmt = DateFormat('MMM d yyyy');
  static final _apiDateFmt = DateFormat('yyyy-MM-dd');

  @override
  void dispose() {
    _descController.dispose();
    _vendorController.dispose();
    super.dispose();
  }

  void _onKey(String k) {
    setState(() {
      if (k == '.') {
        if (_amount.contains('.')) return;
        _amount = '$_amount.';
      } else if (_amount == '0') {
        _amount = k;
      } else {
        final dot = _amount.indexOf('.');
        if (dot != -1 && _amount.length - dot > 2) return;
        _amount = '$_amount$k';
      }
    });
  }

  void _onBackspace() {
    setState(() {
      if (_amount.length <= 1) {
        _amount = '0';
      } else {
        _amount = _amount.substring(0, _amount.length - 1);
        if (_amount.isEmpty) _amount = '0';
      }
    });
  }

  double get _amountValue => double.tryParse(_amount) ?? 0;
  bool get _canSave => _amountValue > 0 && _category != null && !_saving;

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);

    final desc = _descController.text.trim();
    final vendor = _vendorController.text.trim();
    final resolvedVendor = vendor.isNotEmpty ? vendor : _category!.value;
    final expense = Expense(
      id: '',
      date: _apiDateFmt.format(_date),
      description: desc.isEmpty ? _category!.label : desc,
      amount: _amountValue,
      vendor: resolvedVendor,
      category: _category!.value,
    );

    try {
      await widget.store.createExpense(expense);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Could not save expense');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryRed,
              onPrimary: AppColors.onPrimary,
              surface: AppColors.surfaceWhite,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: AppText.bodyLg(color: AppColors.onPrimary)),
        backgroundColor: AppColors.primaryRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final isToday = _apiDateFmt.format(_date) == _apiDateFmt.format(DateTime.now());
    final dateLabel = isToday
        ? 'Today, ${_dateLabelFmt.format(_date)}'
        : _dateLabelFmt.format(_date);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            _amountDisplay(store),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    _categoryGrid(),
                    const SizedBox(height: 16),
                    _vendorField(),
                    const SizedBox(height: 12),
                    _descriptionField(),
                    const SizedBox(height: 12),
                    _dateField(dateLabel),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            // Bottom Numpad + Save Button
            Container(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
              decoration: const BoxDecoration(
                color: AppColors.bgLight,
                border: Border(
                  top: BorderSide(color: AppColors.borderBlack, width: 4),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 220,
                    child: Numpad(onKey: _onKey, onBackspace: _onBackspace),
                  ),
                  const SizedBox(height: 8),
                  _saveButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openQrScanner() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => QrScannerScreen(store: widget.store),
      ),
    );
    if (result == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.bgLight,
        border: Border(
          bottom: BorderSide(color: AppColors.borderBlack, width: 4),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _brutalButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.of(context).pop(),
          ),
          Text(
            'NEW EXPENSE',
            style: AppText.headlineSm(color: AppColors.textPrimary),
          ),
          _brutalButton(
            icon: Icons.qr_code_scanner,
            isPrimary: true,
            onTap: _openQrScanner,
          ),
        ],
      ),
    );
  }

  Widget _brutalButton({
    required IconData icon,
    VoidCallback? onTap,
    bool isPrimary = false,
  }) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isPrimary ? AppColors.primaryRed : AppColors.surfaceWhite,
            border: Border.all(color: AppColors.borderBlack, width: 2),
            boxShadow: AppShadows.brutalBlackSm,
          ),
          child: Icon(
            icon,
            size: 22,
            color: isPrimary ? AppColors.onPrimary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _amountDisplay(ExpenseStore store) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(
          bottom: BorderSide(color: AppColors.borderBlack, width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ENTER AMOUNT',
                style: AppText.labelBold(11, AppColors.textSecondary),
              ),
              Text(
                'BUDGET: ₹${store.formatInr(store.budget.round())}',
                style: AppText.labelBold(11, AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₹',
                style: AppText.displayCurrency(36,
                    color: AppColors.primaryRed),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _amount,
                  style: AppText.displayCurrency(52,
                      color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _categoryGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CATEGORY',
          style: AppText.labelBold(12, AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 8.0;
            final itemWidth = (constraints.maxWidth - (gap * 2)) / 3;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final cat in ExpenseCategory.all)
                  _categoryChip(cat, itemWidth),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _categoryChip(ExpenseCategory cat, double width) {
    final isSelected = _category?.value == cat.value;

    return GestureDetector(
      onTap: () => setState(() => _category = cat),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryRed : AppColors.surfaceWhite,
          border: Border.all(color: AppColors.borderBlack, width: 2),
          boxShadow: isSelected ? AppShadows.brutalBlackSm : const [],
        ),
        child: Column(
          children: [
            Icon(
              cat.icon,
              size: 22,
              color: isSelected ? AppColors.onPrimary : AppColors.textPrimary,
            ),
            const SizedBox(height: 4),
            Text(
              cat.label,
              style: AppText.labelBold(
                11,
                isSelected ? AppColors.onPrimary : AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _vendorField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border.all(color: AppColors.borderBlack, width: 2),
        boxShadow: AppShadows.brutalBlackSm,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: _vendorController,
        style: AppText.bodyLg(color: AppColors.textPrimary),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'MERCHANT / SHOP (OPTIONAL)',
          hintStyle: AppText.labelBold(12, AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _descriptionField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border.all(color: AppColors.borderBlack, width: 2),
        boxShadow: AppShadows.brutalBlackSm,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: _descController,
        style: AppText.bodyLg(color: AppColors.textPrimary),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'NOTES / DETAILS (OPTIONAL)',
          hintStyle: AppText.labelBold(12, AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _dateField(String label) {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          border: Border.all(color: AppColors.borderBlack, width: 2),
          boxShadow: AppShadows.brutalBlackSm,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18, color: AppColors.textPrimary),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      label.toUpperCase(),
                      style: AppText.labelBold(12, AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: AppColors.primaryRed,
              child: Row(
                children: [
                  const Icon(Icons.edit_calendar, size: 14, color: AppColors.onPrimary),
                  const SizedBox(width: 4),
                  Text(
                    'CHANGE',
                    style: AppText.labelBold(10, AppColors.onPrimary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _saveButton() {
    return GestureDetector(
      onTap: _canSave ? _save : null,
      child: Opacity(
        opacity: _canSave ? 1.0 : 0.45,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryRed,
            border: Border.all(color: AppColors.borderBlack, width: 3),
            boxShadow: _canSave ? AppShadows.brutalBlackSm : const [],
          ),
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.onPrimary,
                  ),
                )
              : Text(
                  'SAVE EXPENSE',
                  style: AppText.headlineSm(color: AppColors.onPrimary),
                ),
        ),
      ),
    );
  }
}
