import 'dart:io' show Platform;

/// Connection settings for the Expense Tracker API.
class ApiConfig {
  ApiConfig._();

  /// Base URL of the backend. The API listens on port 3000 (see the API's
  /// `.env`). When running against a local server:
  ///   - Android emulator reaches the host machine via 10.0.2.2
  ///   - iOS simulator / desktop can use localhost directly
  /// Override this with your deployed Firebase Functions URL in production.
  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;

    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:3000/api';
    } catch (_) {
      // Platform unavailable (e.g. tests) — fall through to localhost.
    }
    return 'http://localhost:3000/api';
  }

  /// Client-side daily budget. The API has no budget concept, so this lives
  /// in the app (matches the design's ₹5,000 default).
  static const double dailyBudget = 5000;
}
