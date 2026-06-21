import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:expense_tracker/screens/add_expense_screen.dart';
import 'package:expense_tracker/state/expense_store.dart';
import 'package:expense_tracker/widgets/numpad.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('Numpad builds the amount and Save adds an expense',
      (tester) async {
    // Target device size from the design (375×812pt).
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final store = ExpenseStore();
    await store.load();
    final before = store.expenses.length;

    await tester.pumpWidget(MaterialApp(home: AddExpenseScreen(store: store)));
    await tester.pump(const Duration(milliseconds: 200));

    // Tap 1, 5, 0 on the numpad → ₹150.
    Finder key(String k) =>
        find.descendant(of: find.byType(Numpad), matching: find.text(k));
    await tester.tap(key('1'));
    await tester.tap(key('5'));
    await tester.tap(key('0'));
    await tester.pump();
    expect(find.text('150'), findsOneWidget);

    // Pick a category, then save via the pinned header check button.
    await tester.tap(find.text('Food'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.check));
    await tester.pump(const Duration(milliseconds: 200));

    expect(store.expenses.length, before + 1);
    expect(store.expenses.last.amount, 150);
    // Vendor carries the canonical category token (the model feature).
    expect(store.expenses.last.vendor, 'food');

    store.dispose();
  });
}
