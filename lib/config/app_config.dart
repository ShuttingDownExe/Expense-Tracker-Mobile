import 'package:flutter/foundation.dart';

/// Build-time feature configuration.
class AppConfig {
  AppConfig._();

  /// Whether email/password sign-in is offered on the login screen.
  ///
  /// Resolution order:
  ///  - If `ENABLE_EMAIL_AUTH` is passed via --dart-define, that wins.
  ///  - Otherwise it defaults to ON in debug/profile builds and OFF in
  ///    release builds.
  ///
  /// So:
  ///  - local dev (`flutter run`)                         → email shown
  ///  - tester build (`--release --dart-define=ENABLE_EMAIL_AUTH=true`) → email shown
  ///  - production build (`flutter build ... --release`)  → email hidden (Google only)
  static const bool emailAuthEnabled = bool.fromEnvironment(
    'ENABLE_EMAIL_AUTH',
    defaultValue: !kReleaseMode,
  );
}
