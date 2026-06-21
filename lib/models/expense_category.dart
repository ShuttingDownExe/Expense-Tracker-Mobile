import 'package:flutter/material.dart';

/// Expense categories. [value] is the canonical, stable token sent to the API
/// and used downstream as a model feature (keep these strings constant);
/// [label] is the human-readable display name; [color] is the accent shown in
/// the category grid.
class ExpenseCategory {
  final String value; // canonical feature token, e.g. 'transport'
  final String label; // display name, e.g. 'Transport'
  final Color color;

  const ExpenseCategory(this.value, this.label, this.color);

  Color get tintBg => color.withValues(alpha: 0.12);
  Color get tintBorder => color.withValues(alpha: 0.25);

  static const all = <ExpenseCategory>[
    ExpenseCategory('food', 'Food', Color(0xFFE8855A)),
    ExpenseCategory('transport', 'Transport', Color(0xFF5A9BE8)),
    ExpenseCategory('entertainment', 'Entertainment', Color(0xFF9B5AE8)),
    ExpenseCategory('education', 'Education', Color(0xFF5AC8E8)),
    ExpenseCategory('dining', 'Dining', Color(0xFFE85A8A)),
    ExpenseCategory('groceries', 'Groceries', Color(0xFF7AE85A)),
    ExpenseCategory('medical', 'Medical', Color(0xFF5AE89B)),
    ExpenseCategory('utility', 'Utility', Color(0xFFE8C45A)),
    ExpenseCategory('fashion', 'Fashion', Color(0xFFE85AD0)),
    ExpenseCategory('misc', 'Misc', Color(0xFFC9A84C)),
  ];
}
