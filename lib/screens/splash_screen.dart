import 'dart:async';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'email_verification_screen.dart';
import 'package:stepsecure_app/constants/colors.dart';
import 'package:stepsecure_app/constants/styles.dart';
import 'package:stepsecure_app/services/auth_service.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    // Keep the brand moment on screen briefly even on a fast/no-op
    // auth check, so it doesn't flash by instantly.
    final minDelay = Future.delayed(const Duration(seconds: 2));

    final user = AuthService.instance.currentUser;
    Widget destination;

    if (user == null) {
      destination = const LoginScreen();
    } else {
      // Local emailVerified can be stale, so reload before deciding.
      final verified = await AuthService.instance.reloadAndCheckVerified();
      destination = verified
          ? const MainNavigation()
          : EmailVerificationScreen(email: user.email!);
    }

    await minDelay;
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // The main brand logo block
              Container(
                height: 110,
                width: 110,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.health_and_safety_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                "StepSecure",
                style: AppStyles.splashTitle,
              ),

              const SizedBox(height: 8),

              const Text(
                "AI-Powered Fall Detection System",
                textAlign: TextAlign.center,
                style: AppStyles.splashSubtitle,
              ),

              const SizedBox(height: 60),

              const SizedBox(
                width: 35,
                height: 35,
                child: CircularProgressIndicator(
                  color: AppColors.primaryLight,
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}