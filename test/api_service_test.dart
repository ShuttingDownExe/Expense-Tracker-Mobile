import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/services/api_service.dart';

void main() {
  group('ApiService (mock transport)', () {
    test('attaches the bearer token from the provider on each request',
        () async {
      String? sentAuth;
      final client = MockClient((req) async {
        sentAuth = req.headers['Authorization'];
        return http.Response('{}', 200);
      });
      final api = ApiService(
          client: client, tokenProvider: () async => 'token-abc');

      await api.fetchExpenses();
      expect(sentAuth, 'Bearer token-abc');
    });

    test('fetchExpenses parses the {data:[…]} array shape into a list',
        () async {
      final client = MockClient((req) async {
        expect(req.url.path, endsWith('/expenses'));
        // The API wraps the list in `data` (newest first) with per-item ids.
        return http.Response(
          jsonEncode({
            'data': [
              {'id': 'id1', 'date': '2026-06-21', 'description': 'A', 'amount': 10, 'vendor': 'Food'},
              {'id': 'id2', 'date': '2026-06-21', 'description': 'B', 'amount': 5, 'vendor': 'Bills'},
            ],
            'metaData': {'nextCursor': null, 'hasMore': false, 'count': 2},
          }),
          200,
        );
      });
      final api = ApiService(client: client, tokenProvider: () async => 't');

      final expenses = await api.fetchExpenses();
      expect(expenses, hasLength(2));
      expect(expenses.firstWhere((e) => e.id == 'id1').amount, 10);
    });

    test('createExpense posts the strict payload and parses the response',
        () async {
      Map<String, dynamic>? sentBody;
      final client = MockClient((req) async {
        sentBody = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({'id': 'new-1', ...sentBody!}),
          201,
        );
      });
      final api = ApiService(client: client, tokenProvider: () async => 't');

      final created = await api.createExpense(const Expense(
        id: '',
        date: '2026-06-21',
        description: 'Lunch',
        amount: 150,
        vendor: 'Food',
      ));

      // Only the three schema fields are sent — the server sets the date.
      expect(sentBody!.keys.toSet(), {'description', 'amount', 'vendor'});
      expect(created.id, 'new-1');
      expect(created.amount, 150);
    });

    test('fetchTodayTotal reads the total field', () async {
      final client = MockClient((req) async {
        expect(req.url.path, endsWith('/analytics/today'));
        return http.Response(
            jsonEncode({'date': '2026-06-21', 'timeZone': 'Etc/UTC', 'total': 2840}), 200);
      });
      final api = ApiService(client: client, tokenProvider: () async => 't');

      expect(await api.fetchTodayTotal(), 2840);
    });

    test('fetchWeeklyTotals parses the day-index map (string keys → int)',
        () async {
      final client = MockClient((req) async {
        return http.Response(jsonEncode({'0': 100, '1': 0, '2': 250.5}), 200);
      });
      final api = ApiService(client: client, tokenProvider: () async => 't');

      final weekly = await api.fetchWeeklyTotals();
      expect(weekly[0], 100);
      expect(weekly[2], 250.5);
    });

    test('throws ApiException on a non-2xx response', () async {
      final client = MockClient((req) async => http.Response('nope', 401));
      final api = ApiService(client: client, tokenProvider: () async => 't');

      expect(api.fetchExpenses(), throwsA(isA<ApiException>()));
    });
  });
}
