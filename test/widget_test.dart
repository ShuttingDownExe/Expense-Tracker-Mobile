import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/state/expense_store.dart';

void main() {
  test('spentToday sums only today\'s expenses from sample data', () async {
    final store = ExpenseStore(); // preview mode → sample data
    await store.load();
    // Sample data puts ₹2,840 worth of expenses on today.
    expect(store.spentToday, 2840);
    expect(store.budget, 5000);
    expect(store.remaining, 2160);
    expect(store.isOver, isFalse);
  });
}
