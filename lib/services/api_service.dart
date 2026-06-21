import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/expense.dart';
import 'api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Supplies a fresh Firebase ID token for each request. Returning null means
/// "no auth" (preview mode). Implemented by [AuthService] in the live app and
/// stubbed in tests.
typedef TokenProvider = Future<String?> Function();

/// Thin client over the Expense Tracker API. Every route is protected by
/// Firebase auth, so a bearer ID token is attached to each request. The token
/// is fetched per-request via [tokenProvider] so short-lived tokens are always
/// current.
class ApiService {
  ApiService({http.Client? client, this.tokenProvider})
      : _client = client ?? http.Client();

  final http.Client _client;
  final TokenProvider? tokenProvider;

  bool get hasAuth => tokenProvider != null;

  Future<Map<String, String>> _headers() async {
    final token = await tokenProvider?.call();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  /// GET /api/expenses — returns the user's expenses keyed by id.
  Future<List<Expense>> fetchExpenses() async {
    final res = await _client.get(_uri('/expenses'), headers: await _headers());
    if (res.statusCode != 200) {
      throw ApiException('Failed to fetch expenses',
          statusCode: res.statusCode);
    }
    final body = jsonDecode(res.body);
    if (body is! Map) return const [];
    return body.entries
        .map((e) => Expense.fromJson(
            e.key as String, Map<String, dynamic>.from(e.value as Map)))
        .toList();
  }

  /// POST /api/expenses — creates an expense and returns it with its new id.
  Future<Expense> createExpense(Expense expense) async {
    final res = await _client.post(
      _uri('/expenses'),
      headers: await _headers(),
      body: jsonEncode(expense.toCreateJson()),
    );
    if (res.statusCode != 201) {
      throw ApiException('Failed to create expense',
          statusCode: res.statusCode);
    }
    final json = Map<String, dynamic>.from(jsonDecode(res.body) as Map);
    final id = json.remove('id') as String;
    return Expense.fromJson(id, json);
  }

  /// DELETE /api/expenses/:id
  Future<void> deleteExpense(String id) async {
    final res =
        await _client.delete(_uri('/expenses/$id'), headers: await _headers());
    if (res.statusCode != 204) {
      throw ApiException('Failed to delete expense',
          statusCode: res.statusCode);
    }
  }

  // ── Analytics ──

  /// GET /api/analytics/today?tz=… — returns `{date, timeZone, total}`.
  Future<double> fetchTodayTotal({String? tz}) async {
    final res = await _client.get(
      _uri('/analytics/today${tz != null ? '?tz=$tz' : ''}'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) {
      throw ApiException('Failed to fetch today total',
          statusCode: res.statusCode);
    }
    final json = Map<String, dynamic>.from(jsonDecode(res.body) as Map);
    return (json['total'] as num?)?.toDouble() ?? 0;
  }

  /// GET /api/analytics/weekly?tz=… — returns totals keyed by day index
  /// (0 = first day of the week) up to today.
  Future<Map<int, double>> fetchWeeklyTotals({String? tz}) async {
    final res = await _client.get(
      _uri('/analytics/weekly${tz != null ? '?tz=$tz' : ''}'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) {
      throw ApiException('Failed to fetch weekly totals',
          statusCode: res.statusCode);
    }
    final json = Map<String, dynamic>.from(jsonDecode(res.body) as Map);
    return json.map(
        (k, v) => MapEntry(int.parse(k), (v as num?)?.toDouble() ?? 0));
  }

  void dispose() => _client.close();
}
