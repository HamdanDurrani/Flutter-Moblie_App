import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../state/auth_state.dart';
import '../theme/app_colors.dart';
import '../widgets/pc_button.dart';
import 'verify_otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.colors});

  final ThemeColors colors;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(text: 'ceo@paramount.club');
  final _password = TextEditingController(text: 'ceo123');
  String? _error;
  bool _loading = false;

  ThemeColors get c => widget.colors;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    final auth = context.read<AuthState>();
    final result = await auth.login(_email.text, _password.text);
    if (!mounted) return;
    setState(() => _loading = false);

    switch (result) {
      case AuthLoginFailed(:final error):
        setState(() => _error = error);
      case AuthLoginNeedsOtp(:final challenge):
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VerifyOtpScreen(
              colors: c,
              challenge: challenge,
            ),
          ),
        );
      case AuthLoginOk(:final user):
        await auth.activateSession(user);
    }
  }

  void _fillDemo(String email, String password) {
    setState(() {
      _email.text = email;
      _password.text = password;
      _error = null;
    });
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.outfit(color: c.textMuted),
      filled: true,
      fillColor: c.backgroundElevated,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(color: c.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(color: c.champagne, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [c.gradientTop, c.gradientBottom],
          ),
        ),
        child: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
              children: [
                Column(
                  children: [
                    Image.asset(
                      'assets/images/logo-full.png',
                      width: 260,
                      height: 110,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Manage enquiries, availability, and events — built for the floor team.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        height: 1.45,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(AppRadii.xl),
                    border: Border.all(color: c.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EMAIL',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w500,
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        style: GoogleFonts.outfit(color: c.text, fontSize: 16),
                        decoration: _decoration('you@paramount.club'),
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'PASSWORD',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w500,
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _password,
                        obscureText: true,
                        style: GoogleFonts.outfit(color: c.text, fontSize: 16),
                        decoration: _decoration('••••••••'),
                        onSubmitted: (_) => _submit(),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: c.danger,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      PcButton(
                        label: 'Sign in',
                        loading: _loading,
                        colors: c,
                        onPressed: _loading ? null : _submit,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'SIGN-IN ACCOUNT',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w500,
                    color: c.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _fillDemo('ceo@paramount.club', 'ceo123'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CEO · Paramount',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: c.text,
                                ),
                              ),
                              Text(
                                'ceo@paramount.club',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: c.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'CEO',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w500,
                            color: c.champagne,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(height: 1, color: c.border),
                const SizedBox(height: 16),
                Text(
                  'Website queries are live. Bookings still use the demo hall diary.',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    height: 1.45,
                    color: c.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
