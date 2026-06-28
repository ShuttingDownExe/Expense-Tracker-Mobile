import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../services/api_config.dart';
import '../services/api_service.dart';

/// Holds the user's expenses and derives every figure the dashboard needs
/// (spent today, weekly trend, over-budget calendar days).
///
/// When the API client has no auth (no Firebase sign-in), the store seeds
/// itself with sample data so the UI matches the design reference out of the
/// box. When authenticated it reads expenses plus the /analytics endpoints.
class ExpenseStore extends ChangeNotifier {
  ExpenseStore({ApiService? api, String? userName})
      : _api = api ?? ApiService(),
        _userName = userName ?? 'Arjun';

  final ApiService _api;

  List<Expense> _expenses = [];
  bool _loading = false;
  String? _error;
  final String _userName;

  // Server-computed analytics (authenticated mode only). Null until fetched,
  // in which case the store falls back to deriving figures from [_expenses].
  double? _todayTotalRemote;
  Map<int, double>? _weeklyRemote;
  Map<int, double>? _monthlyRemote; // day-of-month (1-based) → total
  String? _timezone; // resolved device IANA timezone, e.g. 'Asia/Kolkata'

  List<Expense> get expenses => List.unmodifiable(_expenses);
  bool get loading => _loading;
  String? get error => _error;
  String get userName => _userName;
  String get userInitial =>
      _userName.isEmpty ? '?' : _userName[0].toUpperCase();
  double get budget => ApiConfig.dailyBudget;

  /// True when there is no authenticated API client — the store falls back to
  /// sample data so the design renders without a backend.
  bool get isPreview => !_api.hasAuth;

  static final _dateFmt = DateFormat('yyyy-MM-dd');
  static final _inr = NumberFormat.decimalPattern('en_IN');

  String get todayKey => _dateFmt.format(DateTime.now());

  /// Sum of today's expenses. Prefers the server's /analytics/today figure
  /// when authenticated; otherwise derives it locally from [_expenses].
  double get spentToday =>
      _todayTotalRemote ??
      _expenses
          .where((e) => e.date == todayKey)
          .fold(0.0, (sum, e) => sum + e.amount);

  double get remaining => budget - spentToday;
  bool get isOver => spentToday > budget;
  int get pctUsed =>
      budget <= 0 ? 0 : (spentToday / budget * 100).round().clamp(0, 100);

  String formatInr(num value) => _inr.format(value);

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      if (!_api.hasAuth) {
        _expenses = _sampleExpenses();
      } else {
        final tz = await _resolveTimezone();
        // Expenses drive the calendar/list; analytics endpoints drive the
        // headline total and the weekly graph. Fetch in parallel.
        final results = await Future.wait([
          _api.fetchExpenses(),
          _api.fetchTodayTotal(tz: tz),
          _api.fetchWeeklyTotals(tz: tz),
          _api.fetchMonthlyTotals(tz: tz),
        ]);
        _expenses = results[0] as List<Expense>;
        _todayTotalRemote = results[1] as double;
        _weeklyRemote = results[2] as Map<int, double>;
        _monthlyRemote = results[3] as Map<int, double>;
      }
    } on ApiException catch (e) {
      // Surface the failure (the dashboard shows a glass error banner) instead
      // of masking a network problem behind misleading sample/₹0 figures.
      _error = e.message;
      if (!_api.hasAuth) _expenses = _sampleExpenses();
    } catch (e, st) {
      // Log the real cause — a parse/cast error here would otherwise hide
      // behind a generic "couldn't reach the server" message.
      debugPrint('ExpenseStore.load failed: $e\n$st');
      _error = 'Something went wrong loading your data.';
      if (!_api.hasAuth) _expenses = _sampleExpenses();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Resolves (and caches) the device's IANA timezone for analytics queries.
  Future<String?> _resolveTimezone() async {
    if (_timezone != null) return _timezone;
    try {
      _timezone = (await FlutterTimezone.getLocalTimezone()).identifier;
    } catch (_) {
      _timezone = null; // API falls back to Etc/UTC
    }
    return _timezone;
  }

  /// Re-fetches the server analytics after a mutation so the headline total
  /// and weekly graph reflect the change.
  Future<void> _refreshAnalytics() async {
    if (!_api.hasAuth) return;
    try {
      final tz = await _resolveTimezone();
      final results = await Future.wait([
        _api.fetchTodayTotal(tz: tz),
        _api.fetchWeeklyTotals(tz: tz),
        _api.fetchMonthlyTotals(tz: tz),
      ]);
      _todayTotalRemote = results[0] as double;
      _weeklyRemote = results[1] as Map<int, double>;
      _monthlyRemote = results[2] as Map<int, double>;
      notifyListeners();
    } catch (_) {
      // Keep the optimistic local values if the refresh fails.
    }
  }

  /// Optimistically add a created expense and refresh derived figures.
  void addLocal(Expense expense) {
    _expenses = [..._expenses, expense];
    notifyListeners();
  }

  /// Persist a new expense. In preview mode (no auth) it is only added
  /// locally; otherwise it is posted to the API and the server copy
  /// (with its generated id) is stored.
  Future<void> createExpense(Expense expense) async {
    if (!_api.hasAuth) {
      addLocal(expense);
      return;
    }
    final created = await _api.createExpense(expense);
    addLocal(created);
    // Optimistically reflect the new expense in the server-backed headline,
    // then reconcile both today + weekly figures from the server.
    if (created.date == todayKey && _todayTotalRemote != null) {
      _todayTotalRemote = _todayTotalRemote! + created.amount;
      notifyListeners();
    }
    await _refreshAnalytics();
  }

  /// Daily totals for the current Sun–Sat week, oldest first.
  /// Returns 7 values aligned with day labels S M T W T F S — matching the
  /// API's Sunday-first /analytics/weekly convention. Prefers the server's
  /// /analytics/weekly figures when authenticated.
  List<double> get weeklyTotals {
    final remote = _weeklyRemote;
    if (remote != null) {
      // The endpoint returns day-index → total up to today; absent days are 0.
      return List.generate(7, (i) => remote[i] ?? 0);
    }
    final now = DateTime.now();
    final sunday = now.subtract(Duration(days: now.weekday % 7));
    return List.generate(7, (i) {
      final day = _dateFmt.format(sunday.add(Duration(days: i)));
      return _expenses
          .where((e) => e.date == day)
          .fold(0.0, (sum, e) => sum + e.amount);
    });
  }

  /// Index (0=Sun … 6=Sat) of today within the current week.
  /// DateTime.weekday is Mon=1…Sun=7, so `% 7` maps Sunday to 0.
  int get todayWeekdayIndex => DateTime.now().weekday % 7;

  /// Per-day spend for the current month, keyed by day-of-month (1-based).
  /// Prefers the server's /analytics/monthly figures when authenticated;
  /// otherwise derives them locally from [_expenses].
  Map<int, double> get monthlyTotals {
    final remote = _monthlyRemote;
    if (remote != null) return Map.unmodifiable(remote);

    final now = DateTime.now();
    final totals = <int, double>{};
    for (final e in _expenses) {
      final d = e.dateTime;
      if (d.year == now.year && d.month == now.month) {
        totals[d.day] = (totals[d.day] ?? 0) + e.amount;
      }
    }
    return totals;
  }

  /// Day-of-month numbers (1-based) in the current month whose total spend
  /// exceeded the daily budget.
  Set<int> get overBudgetDays => monthlyTotals.entries
      .where((entry) => entry.value > budget)
      .map((entry) => entry.key)
      .toSet();

  // ── Sample data so the dashboard renders meaningfully before sign-in ──
  // Dated relative to today by whole-day offsets so "today" always totals
  // ₹2,840 (the design headline) regardless of the current weekday/date, and
  // no non-today entry can ever collide with today.
  List<Expense> _sampleExpenses() {
    final now = DateTime.now();
    String key(int daysAgo) => _dateFmt.format(now.subtract(Duration(days: daysAgo)));

    return [
      // Today → ₹2,840 spent (matches the design's headline figure).
      Expense(
          id: 's1',
          date: key(0),
          description: 'Lunch',
          amount: 480,
          vendor: 'food'),
      Expense(
          id: 's2',
          date: key(0),
          description: 'Cab',
          amount: 360,
          vendor: 'transport'),
      Expense(
          id: 's3',
          date: key(0),
          description: 'Groceries',
          amount: 2000,
          vendor: 'groceries'),
      // Earlier days, to shape the weekly graph.
      Expense(
          id: 's4',
          date: key(1),
          description: 'Bills',
          amount: 1200,
          vendor: 'utility'),
      Expense(
          id: 's5',
          date: key(2),
          description: 'Dinner',
          amount: 3600,
          vendor: 'dining'),
      Expense(
          id: 's6',
          date: key(3),
          description: 'Pharmacy',
          amount: 900,
          vendor: 'medical'),
      // A couple of over-budget days earlier in the month for the calendar.
      Expense(
          id: 's7',
          date: key(7),
          description: 'Shopping spree',
          amount: 6200,
          vendor: 'fashion'),
      Expense(
          id: 's8',
          date: key(12),
          description: 'Electronics',
          amount: 7400,
          vendor: 'entertainment'),
    ];
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }
}
