import 'dart:async';
import 'package:flutter/material.dart';
import 'package:stepsecure_app/constants/colors.dart';
import 'package:stepsecure_app/constants/styles.dart';
import 'package:stepsecure_app/services/auth_service.dart';
import 'package:stepsecure_app/widgets/custom_button.dart';
import 'login_screen.dart';
import '../main.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  static const int _resendCooldownSeconds = 30;

  /// Spinner on the button: only for checks the user asked for.
  bool _checking = false;

  /// Guard so a slow check can't overlap the next poll.
  bool _inFlight = false;

  bool _resending = false;
  int _cooldown = 0;

  Timer? _pollTimer;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    // Auto-poll so someone who verifies from another device/tab lands
    // in the app without needing to tap the button themselves.
    _pollTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _checkVerified(silent: true),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _goToLogin() {
    _pollTimer?.cancel();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _checkVerified({bool silent = false}) async {
    if (_inFlight) return;
    _inFlight = true;
    if (!silent && mounted) setState(() => _checking = true);

    try {
      // null = couldn't reach Firebase. That is not "unverified", and it
      // must not throw out of a timer callback.
      final fresh = await AuthService.instance.refreshEmailVerified();
      if (!mounted) return;

      // The account may have been deleted/disabled while we waited.
      if (AuthService.instance.currentUser == null) {
        _goToLogin();
        return;
      }

      if (fresh == true) {
        _pollTimer?.cancel();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigation()),
          (route) => false,
        );
        return;
      }

      if (!silent) {
        _showSnack(
          fresh == null
              ? "Couldn't reach the server. Check your connection and try again."
              : "Not verified yet — check your inbox and spam folder.",
        );
      }
    } finally {
      _inFlight = false;
      if (!silent && mounted) setState(() => _checking = false);
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldown = _resendCooldownSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _cooldown -= 1);
      if (_cooldown <= 0) timer.cancel();
    });
  }

  Future<void> _resend() async {
    if (_resending || _cooldown > 0) return;

    setState(() => _resending = true);
    try {
      await AuthService.instance.sendEmailVerification();
      if (!mounted) return;
      _showSnack("Verification email sent.");
      // Firebase rate-limits these; a short cooldown avoids
      // "too many attempts" errors from repeated taps.
      _startCooldown();
    } catch (e) {
      if (!mounted) return;
      _showSnack(AuthService.instance.friendlyError(e));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _useDifferentAccount() async {
    await AuthService.instance.signOut();
    if (!mounted) return;
    _goToLogin();
  }

  String get _resendLabel {
    if (_resending) return "Sending...";
    if (_cooldown > 0) return "Resend in ${_cooldown}s";
    return "Resend email";
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                "Verify your email",
                style: AppStyles.headingMedium.copyWith(color: cs.onSurface),
              ),
              const SizedBox(height: 12),
              Text(
                "We sent a verification link to ${widget.email}. "
                "Open it, then come back here. If you can't find it, "
                "check your spam folder.",
                textAlign: TextAlign.center,
                style: AppStyles.bodyMedium.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: _checking ? "Checking..." : "I've verified",
                icon: Icons.check_circle_outline,
                isLoading: _checking,
                onPressed: () => _checkVerified(),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: (_resending || _cooldown > 0) ? null : _resend,
                child: Text(_resendLabel),
              ),
              TextButton(
                onPressed: _useDifferentAccount,
                child: const Text("Use a different account"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}