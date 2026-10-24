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

  Future<Widget> _resolveDestination() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return const LoginScreen();

    // Ask the server for the real verified state, but never wait forever:
    // null means "couldn't reach Firebase" (offline / timeout), in which
    // case we trust the cached value so an offline launch still works.
    final fresh = await AuthService.instance.refreshEmailVerified();

    // refreshEmailVerified signs the user out if the account was deleted or
    // disabled, so look again.
    final current = AuthService.instance.currentUser;
    if (current == null) return const LoginScreen();

    final verified = fresh ?? current.emailVerified;
    return verified
        ? const MainNavigation()
        : EmailVerificationScreen(email: current.email ?? '');
  }

  Future<void> _route() async {
    // Keep the brand moment on screen briefly even on a fast/no-op
    // auth check, so it doesn't flash by instantly.
    final minDelay = Future<void>.delayed(const Duration(seconds: 2));

    Widget destination;
    try {
      destination = await _resolveDestination();
    } catch (_) {
      // Never leave the user on an endless splash screen.
      destination = const LoginScreen();
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
    final cs = Theme.of(context).colorScheme;

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

              // Colors come from the theme: the shared splash styles are
              // hardcoded white, which disappears in light mode.
              Text(
                "StepSecure",
                style: AppStyles.splashTitle.copyWith(color: cs.onSurface),
              ),

              const SizedBox(height: 8),

              Text(
                "AI-Powered Fall Detection System",
                textAlign: TextAlign.center,
                style: AppStyles.splashSubtitle.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
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