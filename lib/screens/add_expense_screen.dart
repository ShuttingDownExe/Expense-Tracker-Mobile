import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../models/expense_category.dart';
import '../services/api_service.dart';
import '../state/expense_store.dart';
import '../theme/app_theme.dart';
import '../widgets/numpad.dart';

/// Screen 2 — log a new expense. Amount is entered via the custom numpad,
/// a category is picked from the grid, and Save posts to the API.
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
  bool _saving = false;

  // The server stamps the date automatically (today, Asia/Kolkata), so the
  // date shown here is informational only — there is no date picker.
  final DateTime _date = DateTime.now();

  static final _dateLabelFmt = DateFormat('MMM d yyyy');
  static final _apiDateFmt = DateFormat('yyyy-MM-dd');

  @override
  void dispose() {
    _descController.dispose();
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
        // Cap to two decimal places.
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
    final expense = Expense(
      id: '',
      // Local-only (preview display). The server stamps the real date.
      date: _apiDateFmt.format(_date),
      // The API requires a non-empty description; fall back to the category.
      description: desc.isEmpty ? _category!.label : desc,
      amount: _amountValue,
      // The API has no category field yet — the canonical category token is
      // sent as the vendor (and is the model feature). Switch to a dedicated
      // category field once the API supports one.
      vendor: _category!.value,
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

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final dateLabel = _isToday(_date)
        ? 'Today, ${_dateLabelFmt.format(_date)}'
        : _dateLabelFmt.format(_date);

    return Scaffold(
      backgroundColor: AppColors.bgBlack,
      body: SafeArea(
        child: Column(
          children: [
            // Header + amount stay pinned so the running total is always
            // visible while typing.
            _header(),
            _amountDisplay(store),
            // Category grid (10 items) + fields scroll if the device is short.
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                      child: _categoryGrid(),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                      child: Column(
                        children: [
                          _descriptionField(),
                          const SizedBox(height: 10),
                          _dateField(dateLabel),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Numpad then Save pinned to the bottom.
            SizedBox(
              height: 244,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 8),
                child: Numpad(onKey: _onKey, onBackspace: _onBackspace),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
              child: _saveButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _iconButton(
            icon: Icons.arrow_back,
            iconColor: const Color(0xFF888888),
            bg: AppColors.bgSurface,
            border: AppColors.borderFaint,
            onTap: () => Navigator.of(context).pop(),
          ),
          Text('New Expense',
              style: AppText.label(17, AppColors.textPrimary,
                  weight: FontWeight.w600)),
          _iconButton(
            icon: Icons.check,
            iconColor: AppColors.gold,
            bg: AppColors.goldTint10,
            border: const Color(0xFFC9A84C).withValues(alpha: 0.25),
            onTap: _canSave ? _save : null,
          ),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required Color iconColor,
    required Color bg,
    required Color border,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Icon(icon, size: 22, color: iconColor),
      ),
    );
  }

  Widget _amountDisplay(ExpenseStore store) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
      child: Column(
        children: [
          Text('ENTER AMOUNT',
              style: AppText.label(10, AppColors.textGhost)
                  .copyWith(letterSpacing: 2.5)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('₹',
                  style: AppText.display(28)
                      .copyWith(color: AppColors.goldDim, letterSpacing: 0)),
              const SizedBox(width: 6),
              Text(_displayAmount(), style: AppText.display(64)),
              const SizedBox(width: 4),
              const _BlinkingCursor(),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 14),
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent,
                AppColors.goldDim,
                Colors.transparent,
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Today's budget: ₹${store.formatInr(store.budget)} · "
            'Used: ₹${store.formatInr(store.spentToday.round())}',
            style: AppText.label(11, AppColors.textDark),
          ),
        ],
      ),
    );
  }

  String _displayAmount() {
    // Group the integer part with Indian commas, keep any decimal suffix.
    final parts = _amount.split('.');
    final intPart = int.tryParse(parts[0]) ?? 0;
    final grouped = NumberFormat.decimalPattern('en_IN').format(intPart);
    return parts.length > 1 ? '$grouped.${parts[1]}' : grouped;
  }

  Widget _categoryGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CATEGORY',
            style: AppText.label(10, AppColors.textGhost)
                .copyWith(letterSpacing: 2.5)),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, constraints) {
          const gap = 10.0;
          final w = (constraints.maxWidth - gap * 2) / 3;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final cat in ExpenseCategory.all)
                _categoryButton(cat, w),
            ],
          );
        }),
      ],
    );
  }

  Widget _categoryButton(ExpenseCategory cat, double width) {
    final selected = _category?.label == cat.label;
    return GestureDetector(
      onTap: () => setState(() => _category = cat),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? cat.color : AppColors.borderSubtle,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cat.tintBg,
                shape: BoxShape.circle,
                border: Border.all(color: cat.tintBorder),
              ),
              child: Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: cat.color, shape: BoxShape.circle),
              ),
            ),
            const SizedBox(height: 8),
            // Shrink-to-fit so long labels (e.g. "Entertainment") never
            // overflow the button at larger type scales.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(cat.label,
                  maxLines: 1,
                  style: AppText.label(12,
                      selected ? AppColors.textPrimary : const Color(0xFF666666))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _descriptionField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_outlined, size: 19, color: AppColors.textGhost),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _descController,
              style: AppText.body(AppColors.textPrimary),
              cursorColor: AppColors.gold,
              maxLength: 100, // API caps description at 100 chars
              decoration: InputDecoration(
                isCollapsed: true,
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: InputBorder.none,
                hintText: 'Description (optional)',
                hintStyle: AppText.body(AppColors.textDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Date is server-assigned (today), so this row is informational only.
  Widget _dateField(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 19, color: AppColors.textGhost),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(AppColors.textPrimary)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('Auto',
              style: AppText.label(12, AppColors.textGhost)),
        ],
      ),
    );
  }

  Widget _saveButton() {
    return GestureDetector(
      onTap: _canSave ? _save : null,
      child: Opacity(
        opacity: _canSave ? 1 : 0.5,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFFC9A84C).withValues(alpha: 0.25),
                  blurRadius: 28,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: _saving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.black))
              : Text('Save Expense',
                  style: AppText.label(16, Colors.black,
                          weight: FontWeight.w600)
                      .copyWith(letterSpacing: 0.5)),
        ),
      ),
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}

/// The 3×52pt blinking gold cursor next to the amount.
class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 3,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
