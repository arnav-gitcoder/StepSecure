import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:stepsecure_app/constants/colors.dart';
import 'package:stepsecure_app/services/auth_service.dart';
import 'package:stepsecure_app/widgets/custom_button.dart';
import 'email_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // Set by IntlPhoneField's onChanged — includes the country dial code,
  // e.g. "+91XXXXXXXXXX".
  String? _fullPhoneNumber;
  bool _phoneValid = false;

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool _loading = false;

  // At least one digit, at least one special character, no whitespace
  // anywhere, minimum 8 characters total.
  static final RegExp _passwordRule = RegExp(
    r'^(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>_\-+=~`\[\];/\\]).{8,}$',
  );
  static final RegExp _emailRule = RegExp(
    r'^[\w.+-]+@[\w-]+\.[\w.-]+$',
  );

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String? _validateFullName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return "Full name is required";
    if (trimmed.length < 2) return "Name is too short";
    return null;
  }

  String? _validateEmail(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return "Email is required";
    if (!_emailRule.hasMatch(trimmed)) return "Enter a valid email address";
    return null;
  }

  String? _validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return "Password is required";
    if (v.contains(' ')) return "Password cannot contain spaces";
    if (!_passwordRule.hasMatch(v)) {
      return "Min 8 characters, at least 1 number and 1 special character";
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if ((value ?? '').isEmpty) return "Please confirm your password";
    if (value != passwordController.text) return "Passwords do not match";
    return null;
  }

  Future<void> _handleRegister() async {
    final formValid = _formKey.currentState?.validate() ?? false;

    if (!formValid) {
      _showSnack("Please fix the highlighted fields");
      return;
    }

    if (_fullPhoneNumber == null || !_phoneValid) {
      _showSnack("Enter a valid phone number");
      return;
    }

    setState(() => _loading = true);
    try {
      final user = await AuthService.instance.signUpWithEmail(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      // TODO: once a Firestore/user-profile layer exists, save
      // fullNameController.text and _fullPhoneNumber there — Firebase
      // Auth itself only stores email/password/uid.

      if (!mounted || user == null) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(email: user.email!),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack(AuthService.instance.friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Account"),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              children: [
                Container(
                  height: 90,
                  width: 90,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1,
                    color: AppColors.icon,
                    size: 50,
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  "Join StepSecure",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Create an account to start monitoring and receiving alerts.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.6),
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 30),

                TextFormField(
                  controller: fullNameController,
                  enabled: !_loading,
                  textCapitalization: TextCapitalization.words,
                  validator: _validateFullName,
                  decoration: inputDecoration(
                    label: "Full Name",
                    icon: Icons.person_outline,
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_loading,
                  validator: _validateEmail,
                  decoration: inputDecoration(
                    label: "Email",
                    icon: Icons.email_outlined,
                  ),
                ),

                const SizedBox(height: 16),

                // Country-code phone field — flag + dial code dropdown,
                // per-country number-length validation built in.
                IntlPhoneField(
                  enabled: !_loading,
                  initialCountryCode: 'IN',
                  decoration: inputDecoration(
                    label: "Phone Number",
                    icon: Icons.phone_outlined,
                  ).copyWith(counterText: ''),
                  onChanged: (phone) {
                    _fullPhoneNumber = phone.completeNumber;
                    _phoneValid = phone.isValidNumber();
                  },
                  validator: (phone) {
                    if (phone == null || phone.number.isEmpty) {
                      return "Phone number is required";
                    }
                    if (!phone.isValidNumber()) {
                      return "Enter a valid phone number";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  enabled: !_loading,
                  validator: _validatePassword,
                  decoration:
                      inputDecoration(
                        label: "Password",
                        icon: Icons.lock_outline,
                      ).copyWith(
                        helperText:
                            "8+ chars, 1 number, 1 special character, no spaces",
                        helperMaxLines: 2,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                      ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  enabled: !_loading,
                  validator: _validateConfirmPassword,
                  onFieldSubmitted: (_) => _handleRegister(),
                  decoration:
                      inputDecoration(
                        label: "Confirm Password",
                        icon: Icons.lock_reset_outlined,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              obscureConfirmPassword =
                                  !obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: "Create Account",
                    icon: Icons.person_add_alt_1,
                    backgroundColor: AppColors.primary,
                    isLoading: _loading,
                    onPressed: _handleRegister,
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account?"),
                    TextButton(
                      onPressed:
                          _loading ? null : () => Navigator.pop(context),
                      child: const Text("Login"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}