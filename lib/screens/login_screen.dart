import 'package:flutter/material.dart';
import '../main.dart';
import 'register_screen.dart';
import 'email_verification_screen.dart';
import 'package:stepsecure_app/constants/colors.dart';
import 'package:stepsecure_app/services/auth_service.dart';
import 'package:stepsecure_app/utils/validators.dart';
import 'package:stepsecure_app/widgets/custom_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool obscurePassword = true;
  bool _loading = false;
  bool _googleLoading = false;
  bool _resetting = false;

  /// True while any request is running. Blocks double submissions.
  bool get _busy => _loading || _googleLoading || _resetting;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleEmailLogin() async {
    if (_busy) return;

    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnack("Please enter email and password");
      return;
    }

    final emailError = Validators.email(email);
    if (emailError != null) {
      _showSnack(emailError);
      return;
    }

    setState(() => _loading = true);
    try {
      final user = await AuthService.instance.signInWithEmail(
        email: email,
        password: password,
      );

      if (!mounted || user == null) return;

      if (!user.emailVerified) {
        // Not verified yet — send them to the gate screen instead of
        // straight into the app. That screen has a Resend button (with a
        // cooldown), so we don't fire another email on every login; doing
        // so can hit Firebase's rate limit and block this very redirect.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(email: user.email ?? email),
          ),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack(AuthService.instance.friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    if (_busy) return;

    setState(() => _googleLoading = true);
    try {
      final user = await AuthService.instance.signInWithGoogle();
      if (!mounted || user == null) return; // user cancelled the picker

      // Google-verified accounts come back already emailVerified.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack(AuthService.instance.friendlyError(e));
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_busy) return;

    final email = emailController.text.trim();
    if (email.isEmpty) {
      _showSnack("Enter your email above first, then tap Forgot Password.");
      return;
    }

    final emailError = Validators.email(email);
    if (emailError != null) {
      _showSnack(emailError);
      return;
    }

    setState(() => _resetting = true);
    try {
      await AuthService.instance.sendPasswordReset(email);
      if (!mounted) return;
      // Same wording whether or not an account exists, so this screen can't
      // be used to find out who is registered.
      _showSnack(
        "If an account exists for $email, a password reset link is on its "
        "way. Check your spam folder too.",
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack(AuthService.instance.friendlyError(e));
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              Container(
                height: 90,
                width: 90,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.health_and_safety_rounded,
                  color: AppColors.icon,
                  size: 50,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                "Welcome Back",
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Sign in to continue using StepSecure",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.6),
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 40),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                enabled: !_busy,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                enabled: !_busy,
                onSubmitted: (_) => _handleEmailLogin(),
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: obscurePassword ? "Show password" : "Hide password",
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _busy ? null : _handleForgotPassword,
                  child: Text(
                    _resetting ? "Sending..." : "Forgot Password?",
                  ),
                ),
              ),

              const SizedBox(height: 12),

              CustomButton(
                text: "Login",
                icon: Icons.login,
                backgroundColor: AppColors.primary,
                isLoading: _loading,
                onPressed: _handleEmailLogin,
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Divider(color: cs.onSurface.withValues(alpha: 0.2)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "OR",
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: cs.onSurface.withValues(alpha: 0.2)),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _handleGoogleLogin,
                  icon: _googleLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.g_mobiledata, size: 28),
                  label: Text(
                    _googleLoading ? "Signing in..." : "Continue with Google",
                    style: TextStyle(color: cs.onSurface),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: cs.onSurface.withValues(alpha: 0.2),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                    child: const Text("Register"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}