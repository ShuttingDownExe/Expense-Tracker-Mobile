/// Build-time environment configuration.
///
/// The target environment is selected at build time with
/// `--dart-define=APP_ENV=dev|test|prod` (defaults to `dev`). Everything else
/// — API URL, whether email sign-in is offered — derives from it.
///
///   dev   → local API, email auth on,  cleartext HTTP (debug build only)
///   test  → hosted test API, email auth on,  HTTPS
///   prod  → hosted prod API, email auth OFF (Google only), HTTPS
class AppConfig {
  AppConfig._();

  static const String environment =
      String.fromEnvironment('APP_ENV', defaultValue: 'dev');

  static bool get isDev => environment == 'dev';
  static bool get isTest => environment == 'test';
  static bool get isProd => environment == 'prod';

  /// Email/password sign-in is available everywhere except production.
  /// Const (derives from the const [environment]) so it can be used in the
  /// sign-in screen's const constructor.
  static const bool emailAuthEnabled = environment != 'prod';
}
