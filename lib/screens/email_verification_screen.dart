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
  bool _checking = false;
  bool _resending = false;
  Timer? _pollTimer;

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
    super.dispose();
  }

  Future<void> _checkVerified({bool silent = false}) async {
    if (_checking) return;
    setState(() => _checking = true);

    final verified = await AuthService.instance.reloadAndCheckVerified();

    if (!mounted) return;
    setState(() => _checking = false);

    if (verified) {
      _pollTimer?.cancel();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
        (route) => false,
      );
    } else if (!silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Not verified yet — check your inbox and spam folder."),
        ),
      );
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await AuthService.instance.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Verification email sent.")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthService.instance.friendlyError(e))),
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _useDifferentAccount() async {
    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
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
                "Open it, then come back here.",
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
                onPressed: _resending ? null : _resend,
                child: Text(_resending ? "Sending..." : "Resend email"),
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