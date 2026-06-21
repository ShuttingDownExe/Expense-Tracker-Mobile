import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// Sign-in screen. Google sign-in is always offered; email/password is shown
/// only when [emailAuthEnabled] (on in dev/tester builds, off in production —
/// see [AppConfig.emailAuthEnabled]).
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, required this.auth, bool? emailAuthEnabled})
      : emailAuthEnabled = emailAuthEnabled ?? AppConfig.emailAuthEnabled;

  final AuthService auth;
  final bool emailAuthEnabled;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegister = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter your email and password.');
      return;
    }
    await _run(() => _isRegister
        ? widget.auth.register(email, password)
        : widget.auth.signIn(email, password));
  }

  Future<void> _signInWithGoogle() => _run(widget.auth.signInWithGoogle);

  /// Runs an auth action with shared busy/error handling. On success the
  /// AuthGate reacts to the auth-state change, so there's nothing else to do.
  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = AuthService.describeError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBlack,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Expense Tracker',
                    textAlign: TextAlign.center, style: AppText.screenTitle),
                const SizedBox(height: 6),
                Text(
                  widget.emailAuthEnabled
                      ? (_isRegister ? 'Create your account' : 'Welcome back')
                      : 'Sign in to continue',
                  textAlign: TextAlign.center,
                  style: AppText.label(13, AppColors.textMuted),
                ),
                const SizedBox(height: 36),

                // Email/password block — dev/tester builds only.
                if (widget.emailAuthEnabled) ...[
                  _field(_emailController, 'Email',
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  _field(_passwordController, 'Password', obscure: true),
                ],

                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!,
                      textAlign: TextAlign.center,
                      style: AppText.label(12, AppColors.red)),
                ],

                if (widget.emailAuthEnabled) ...[
                  const SizedBox(height: 24),
                  _submitButton(),
                  const SizedBox(height: 18),
                  _orDivider(),
                  const SizedBox(height: 18),
                ],

                _googleButton(),

                if (widget.emailAuthEnabled) ...[
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                              _isRegister = !_isRegister;
                              _error = null;
                            }),
                    child: Text(
                      _isRegister
                          ? 'Have an account? Sign in'
                          : 'New here? Create an account',
                      style: AppText.label(13, AppColors.gold),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String hint,
      {bool obscure = false, TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        enabled: !_busy,
        style: AppText.body(AppColors.textPrimary),
        cursorColor: AppColors.gold,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          hintText: hint,
          hintStyle: AppText.body(AppColors.textDark),
        ),
      ),
    );
  }

  Widget _orDivider() {
    final line = Expanded(
      child: Container(height: 1, color: AppColors.borderSubtle),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or', style: AppText.label(12, AppColors.textMuted)),
        ),
        line,
      ],
    );
  }

  Widget _googleButton() {
    return GestureDetector(
      onTap: _busy ? null : _signInWithGoogle,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Simple multi-color "G" mark rendered without an asset.
            Text('G',
                style: AppText.label(18, const Color(0xFF4285F4),
                    weight: FontWeight.w700)),
            const SizedBox(width: 10),
            Text('Continue with Google',
                style: AppText.label(15, AppColors.textPrimary,
                    weight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _submitButton() {
    return GestureDetector(
      onTap: _busy ? null : _submit,
      child: Opacity(
        opacity: _busy ? 0.6 : 1,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(16),
          ),
          child: _busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.black))
              : Text(_isRegister ? 'Create account' : 'Sign in',
                  style: AppText.label(16, Colors.black, weight: FontWeight.w600)
                      .copyWith(letterSpacing: 0.5)),
        ),
      ),
    );
  }
}
