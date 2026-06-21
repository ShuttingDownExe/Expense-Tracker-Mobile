import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';
import 'screens/dashboard_screen.dart';
import 'screens/sign_in_screen.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'state/expense_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.bgBlack,
  ));

  // Try to initialise Firebase. If it isn't configured yet (placeholder
  // firebase_options.dart), fall back to preview mode so the UI still runs.
  bool firebaseReady = false;
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    firebaseReady = true;
  } catch (e) {
    debugPrint('Firebase not initialised — running in preview mode: $e');
  }

  runApp(ExpenseTrackerApp(firebaseReady: firebaseReady));
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bgBlack,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.gold,
          surface: AppColors.bgSurface,
        ),
      ),
      home: firebaseReady
          ? AuthGate(auth: AuthService())
          // No Firebase yet → dashboard in preview mode (sample data).
          : DashboardScreen(store: ExpenseStore()),
    );
  }
}

/// Shows the sign-in screen or the dashboard depending on Firebase auth state.
/// A fresh [ExpenseStore] (wired to the authenticated API client) is built for
/// each signed-in user.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.auth});

  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: auth.authState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.bgBlack,
            body: Center(
                child: CircularProgressIndicator(color: AppColors.gold)),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return SignInScreen(auth: auth);
        }

        final store = ExpenseStore(
          api: ApiService(tokenProvider: auth.idToken),
          userName: (user.displayName?.isNotEmpty ?? false)
              ? user.displayName!
              : (user.email?.split('@').first ?? 'there'),
        );
        return DashboardScreen(store: store, onSignOut: auth.signOut);
      },
    );
  }
}
