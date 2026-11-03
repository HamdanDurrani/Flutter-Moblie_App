import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/session_user.dart';
import '../state/auth_state.dart';
import '../theme/app_colors.dart';
import '../widgets/pc_button.dart';

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({
    super.key,
    required this.colors,
    required this.challenge,
  });

  final ThemeColors colors;
  final OtpChallenge challenge;

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _code = TextEditingController();
  late String _challengeToken;
  late String _emailHint;
  String? _error;
  bool _verifying = false;
  bool _resending = false;
  int _cooldown = 60;
  Timer? _timer;

  ThemeColors get c => widget.colors;

  @override
  void initState() {
    super.initState();
    _challengeToken = widget.challenge.challengeToken;
    _emailHint = widget.challenge.emailHint;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _cooldown <= 0) return;
      setState(() => _cooldown -= 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final digits = _code.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 6) {
      setState(() => _error = 'Enter the 6-digit code from your email.');
      return;
    }
    if (_verifying) return;

    setState(() {
      _error = null;
      _verifying = true;
    });

    final auth = context.read<AuthState>();
    final result = await auth.verifyOtp(_challengeToken, digits);
    if (!mounted) return;

    switch (result) {
      case AuthLoginFailed(:final error):
        setState(() {
          _error = error;
          _verifying = false;
        });
      case AuthLoginNeedsOtp():
        setState(() {
          _error = 'Unexpected response.';
          _verifying = false;
        });
      case AuthLoginOk(:final user):
        await auth.activateSession(user);
        if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _resend() async {
    if (_cooldown > 0 || _resending) return;
    setState(() {
      _resending = true;
      _error = null;
    });
    final auth = context.read<AuthState>();
    final next = await auth.resendOtp(_challengeToken);
    if (!mounted) return;
    setState(() {
      _resending = false;
      if (next != null) {
        if (next.emailHint.isNotEmpty) _emailHint = next.emailHint;
        _cooldown = 60;
      } else {
        _error = 'Could not resend code.';
      }
    });
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.arrow_back, color: c.text),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Check your email',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: c.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.challenge.message,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  height: 1.45,
                  color: c.textSecondary,
                ),
              ),
              if (_emailHint.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _emailHint,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: c.champagne,
                  ),
                ),
              ],
              const SizedBox(height: 28),
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
                      'VERIFICATION CODE',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w500,
                        color: c.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _code,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: GoogleFonts.outfit(
                        color: c.text,
                        fontSize: 22,
                        letterSpacing: 8,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '••••••',
                        hintStyle: GoogleFonts.outfit(color: c.textMuted),
                        filled: true,
                        fillColor: c.backgroundElevated,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
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
                      ),
                      onSubmitted: (_) => _verify(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: GoogleFonts.outfit(fontSize: 13, color: c.danger),
                      ),
                    ],
                    const SizedBox(height: 24),
                    PcButton(
                      label: 'Verify & continue',
                      loading: _verifying,
                      colors: c,
                      onPressed: _verifying ? null : _verify,
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: (_cooldown > 0 || _resending) ? null : _resend,
                        child: Text(
                          _resending
                              ? 'Sending…'
                              : _cooldown > 0
                                  ? 'Resend in ${_cooldown}s'
                                  : 'Resend code',
                          style: GoogleFonts.outfit(
                            color: c.champagne,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
