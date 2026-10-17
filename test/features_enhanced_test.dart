import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/services/api_service.dart';
import 'package:expense_tracker/state/expense_store.dart';
import 'package:expense_tracker/widgets/budget_calendar.dart';
import 'package:expense_tracker/widgets/budget_card.dart';

void main() {
  group('Enhanced Features Unit Tests', () {
    test('Expense model category vs vendor backward compatibility', () {
      // Legacy JSON without category
      final legacy = Expense.fromJson('1', {
        'date': '2026-10-17',
        'description': 'Coffee',
        'amount': 120.0,
        'vendor': 'food',
      });
      expect(legacy.vendor, 'food');
      expect(legacy.categoryKey, 'food');

      // Enhanced JSON with both category and vendor
      final modern = Expense.fromJson('2', {
        'date': '2026-10-17',
        'description': 'Espresso',
        'amount': 250.0,
        'vendor': 'Blue Tokai',
        'category': 'food',
      });
      expect(modern.vendor, 'Blue Tokai');
      expect(modern.categoryKey, 'food');

      // toCreateJson preserves category, vendor, and custom date
      final json = modern.toCreateJson();
      expect(json['vendor'], 'Blue Tokai');
      expect(json['category'], 'food');
      expect(json['date'], '2026-10-17');
    });

    test('ApiService budget endpoints fetch and update', () async {
      double currentBudget = 500;
      final client = MockClient((req) async {
        if (req.url.path.endsWith('/user/budget')) {
          if (req.method == 'GET') {
            return http.Response(jsonEncode({'dailyBudget': currentBudget}), 200);
          } else if (req.method == 'PUT') {
            final body = jsonDecode(req.body) as Map;
            currentBudget = (body['dailyBudget'] as num).toDouble();
            return http.Response(jsonEncode({'dailyBudget': currentBudget}), 200);
          }
        }
        return http.Response('Not Found', 404);
      });

      final api = ApiService(client: client, tokenProvider: () async => 'mock-token');

      final initial = await api.fetchDailyBudget();
      expect(initial, 500);

      final updated = await api.updateDailyBudget(1200);
      expect(updated, 1200);

      final fetchedAgain = await api.fetchDailyBudget();
      expect(fetchedAgain, 1200);
    });

    test('ApiService fetchExpensesPaged parses pagination metadata', () async {
      final client = MockClient((req) async {
        expect(req.url.queryParameters['limit'], '10');
        return http.Response(
          jsonEncode({
            'data': [
              {'id': 'e1', 'date': '2026-10-17', 'description': 'Item 1', 'amount': 100, 'vendor': 'Shop', 'createdAt': 1000},
            ],
            'metaData': {
              'nextCursor': 999,
              'hasMore': true,
              'count': 1,
            }
          }),
          200,
        );
      });

      final api = ApiService(client: client, tokenProvider: () async => 'token');
      final paged = await api.fetchExpensesPaged(limit: 10);
      expect(paged.expenses.length, 1);
      expect(paged.nextCursor, 999);
      expect(paged.hasMore, true);
    });

    test('ExpenseStore getMonthlyTotalsFor and getOverBudgetDaysFor', () {
      final store = ExpenseStore(api: ApiService());
      final totals = store.getMonthlyTotalsFor(2026, 10);
      expect(totals, isA<Map<int, double>>());

      final overDays = store.getOverBudgetDaysFor(2026, 10);
      expect(overDays, isA<Set<int>>());
    });
  });

  group('Enhanced UI Widget Tests', () {
    testWidgets('BudgetCalendar month navigation buttons exist and step months', (tester) async {
      final store = ExpenseStore(api: ApiService());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BudgetCalendar(store: store),
          ),
        ),
      );

      // Verify chevron buttons exist
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);

      // Tap next month
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      // "TODAY" button in header + legend text = 2 widgets
      expect(find.text('TODAY'), findsNWidgets(2));

      // Tap TODAY button in header to snap back
      await tester.tap(find.widgetWithText(GestureDetector, 'TODAY'));
      await tester.pumpAndSettle();

      // Only the legend has 'TODAY' now
      expect(find.text('TODAY'), findsOneWidget);
    });

    testWidgets('BudgetCard limit edit dialog opens on tap', (tester) async {
      final store = ExpenseStore(api: ApiService());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BudgetCard(store: store),
          ),
        ),
      );

      // Find the limit edit button with the pencil icon
      final editButton = find.byIcon(Icons.edit);
      expect(editButton, findsOneWidget);

      await tester.tap(editButton);
      await tester.pumpAndSettle();

      // Verify the dialog opened
      expect(find.text('SET DAILY BUDGET'), findsOneWidget);
      expect(find.text('SAVE'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);

      // Tap CANCEL to close
      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();

      expect(find.text('SET DAILY BUDGET'), findsNothing);
    });
  });
}
