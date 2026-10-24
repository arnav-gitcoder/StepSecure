/// Reusable input validators. Each returns an error message, or null when the
/// value is valid (the shape `TextFormField.validator` expects).
class Validators {
  Validators._();

  // Same rule register_screen.dart uses, so login and register agree.
  static final RegExp _emailRule = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  static bool isValidEmail(String? value) =>
      _emailRule.hasMatch((value ?? '').trim());

  static String? email(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return 'Email is required';
    if (!_emailRule.hasMatch(trimmed)) return 'Enter a valid email address';
    return null;
  }
}