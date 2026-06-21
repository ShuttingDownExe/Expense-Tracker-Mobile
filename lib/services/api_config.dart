import 'dart:io' show Platform;

import '../config/app_config.dart';

/// Connection settings for the Expense Tracker API, resolved from the build
/// environment ([AppConfig.environment]).
class ApiConfig {
  ApiConfig._();

  /// Base URL of the backend (including the `/api` prefix).
  ///
  ///   dev  → local server (Android emulator reaches the host via 10.0.2.2)
  ///   test → hosted App Hosting test backend
  ///   prod → hosted App Hosting prod backend
  ///
  /// A `--dart-define=API_BASE_URL=...` override always wins (handy for
  /// pointing a dev build at a physical device's LAN host, etc.).
  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;

    switch (AppConfig.environment) {
      case 'prod':
        return 'https://prod--expense-tracker-a9ebd.asia-east1.hosted.app/api';
      case 'test':
        return 'https://test--expense-tracker-a9ebd.us-east4.hosted.app/api';
      case 'dev':
      default:
        try {
          if (Platform.isAndroid) return 'http://10.0.2.2:3000/api';
        } catch (_) {
          // Platform unavailable (e.g. tests) — fall through to localhost.
        }
        return 'http://localhost:3000/api';
    }
  }

  /// Client-side daily budget. The API has no budget concept, so this lives
  /// in the app (matches the design's ₹5,000 default).
  static const double dailyBudget = 5000;
}
