import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// Sign-in screen matching the Stitch Raw Ledger Neo-Brutalist design:
/// sharp 0px inputs, 3px solid black borders, 4px hard black shadows,
/// Anton typography, and bold primary red actions.
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
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                border: Border.all(color: AppColors.borderBlack, width: 4),
                boxShadow: AppShadows.brutalBlack,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'EXPENSE_ROOT',
                    textAlign: TextAlign.center,
                    style: AppText.headlineLg(color: AppColors.primaryRed),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.emailAuthEnabled
                        ? (_isRegister ? 'CREATE ACCOUNT' : 'DAILY BUDGET TRACKER')
                        : 'SIGN IN TO CONTINUE',
                    textAlign: TextAlign.center,
                    style: AppText.labelBold(12, AppColors.textSecondary, spacing: 1.0),
                  ),
                  const SizedBox(height: 28),

                  if (widget.emailAuthEnabled) ...[
                    _field(_emailController, 'EMAIL ADDRESS',
                        keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 14),
                    _field(_passwordController, 'PASSWORD', obscure: true),
                  ],

                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      color: AppColors.alertYellow,
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: AppText.labelBold(11, AppColors.primaryRed),
                      ),
                    ),
                  ],

                  if (widget.emailAuthEnabled) ...[
                    const SizedBox(height: 20),
                    _submitButton(),
                    const SizedBox(height: 16),
                    _orDivider(),
                    const SizedBox(height: 16),
                  ],

                  _googleButton(),

                  if (widget.emailAuthEnabled) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                                _isRegister = !_isRegister;
                                _error = null;
                              }),
                      child: Text(
                        _isRegister
                            ? 'ALREADY REGISTERED? SIGN IN ›'
                            : 'NEW HERE? CREATE ACCOUNT ›',
                        style: AppText.labelBold(12, AppColors.primaryRed),
                      ),
                    ),
                  ],
                ],
              ),
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
        color: AppColors.bgLight,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.borderBlack, width: 2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        enabled: !_busy,
        style: AppText.bodyLg(color: AppColors.textPrimary),
        cursorColor: AppColors.primaryRed,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          hintText: hint,
          hintStyle: AppText.labelBold(11, AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _orDivider() {
    final line = Expanded(
      child: Container(height: 2, color: AppColors.borderBlack),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('OR', style: AppText.labelBold(11, AppColors.textSecondary)),
        ),
        line,
      ],
    );
  }

  Widget _googleButton() {
    return GestureDetector(
      onTap: _busy ? null : _signInWithGoogle,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: AppColors.borderBlack, width: 2),
          boxShadow: AppShadows.brutalBlackSm,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'G',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF4285F4),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'CONTINUE WITH GOOGLE',
              style: AppText.labelBold(12, AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _submitButton() {
    return GestureDetector(
      onTap: _busy ? null : _submit,
      child: Opacity(
        opacity: _busy ? 0.6 : 1.0,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryRed,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: AppColors.borderBlack, width: 2),
            boxShadow: AppShadows.brutalBlackSm,
          ),
          child: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.onPrimary,
                  ),
                )
              : Text(
                  _isRegister ? 'CREATE ACCOUNT' : 'SIGN IN',
                  style: AppText.headlineSm(color: AppColors.onPrimary),
                ),
        ),
      ),
    );
  }
}
