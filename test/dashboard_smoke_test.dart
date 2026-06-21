import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:expense_tracker/screens/dashboard_screen.dart';
import 'package:expense_tracker/state/expense_store.dart';

void main() {
  setUpAll(() {
    // Avoid network font fetches during the test.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Dashboard builds and shows the greeting + budget figures',
      (tester) async {
    final store = ExpenseStore();
    await tester.pumpWidget(MaterialApp(home: DashboardScreen(store: store)));

    // Let load() + the staggered animations advance (without settling, since
    // the pulse/cursor animations repeat forever).
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 1700));

    expect(find.text('Good morning,'), findsOneWidget);
    expect(find.text('SPENT TODAY'), findsOneWidget);
    expect(find.text('THIS WEEK'), findsOneWidget);
    // FAB to open the add-expense flow.
    expect(find.byIcon(Icons.add), findsOneWidget);

    store.dispose();
  });
}
