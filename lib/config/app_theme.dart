import 'package:flutter/material.dart';

import '../constants/colors.dart';

/// Light-mode neutrals. Dark mode uses the neutrals in constants/colors.dart
/// (AppColors); the brand and status colors are shared by both modes.
class _LightColors {
  _LightColors._();

  static const Color background = Color(0xFFF3F4F6); // Slate 100
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF111827); // Slate 900
  static const Color textSecondary = Color(0xFF374151); // Slate 700
  static const Color border = Color(0xFFD1D5DB); // Slate 300
  static const Color divider = Color(0xFFE5E7EB); // Slate 200
}

/// App-wide theme definitions. Import this, never build ThemeData inline.
///
/// The palette lives in one place, constants/colors.dart. This file only maps
/// it onto Material's ColorScheme, so screens that read
/// `Theme.of(context).colorScheme` (onSurface, surface, outlineVariant...)
/// get readable colors in both light and dark mode.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    // Teal 800 on white is ~7.5:1; plain primary (teal 600) is too pale for
    // white button text in light mode.
    const brand = AppColors.primaryDark;

    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: brand,
      onPrimary: Colors.white,
      secondary: AppColors.primary,
      onSecondary: Colors.white,
      error: Color(0xFFB91C1C),
      onError: Colors.white,
      surface: _LightColors.surface,
      onSurface: _LightColors.textPrimary,
      outline: _LightColors.border,
      outlineVariant: _LightColors.divider,
    );

    return _build(
      colorScheme: colorScheme,
      scaffold: _LightColors.background,
      appBarBackground: _LightColors.surface,
      appBarForeground: _LightColors.textPrimary,
      inputFill: _LightColors.surface,
      inputBorder: _LightColors.border,
      focus: brand,
      buttonBackground: brand,
      buttonForeground: Colors.white,
      indicatorAlpha: 0.15,
    );
  }

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryLight,
      onPrimary: Color(0xFF042F2E), // dark teal text on the light teal
      secondary: AppColors.primary,
      onSecondary: Colors.white,
      error: AppColors.danger,
      onError: Color(0xFF450A0A),
      surface: AppColors.cardBackground,
      onSurface: AppColors.textPrimary,
      outline: AppColors.divider,
      outlineVariant: AppColors.border,
    );

    return _build(
      colorScheme: colorScheme,
      scaffold: AppColors.background,
      appBarBackground: AppColors.cardBackground,
      appBarForeground: AppColors.textPrimary,
      inputFill: AppColors.cardBackground,
      inputBorder: AppColors.border,
      focus: AppColors.primaryLight,
      buttonBackground: AppColors.primaryLight,
      buttonForeground: const Color(0xFF042F2E),
      indicatorAlpha: 0.25,
    );
  }

  static ThemeData _build({
    required ColorScheme colorScheme,
    required Color scaffold,
    required Color appBarBackground,
    required Color appBarForeground,
    required Color inputFill,
    required Color inputBorder,
    required Color focus,
    required Color buttonBackground,
    required Color buttonForeground,
    required double indicatorAlpha,
  }) {
    OutlineInputBorder outline(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffold,
      dividerColor: colorScheme.outlineVariant,
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBackground,
        foregroundColor: appBarForeground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonBackground,
          foregroundColor: buttonForeground,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: outline(inputBorder),
        enabledBorder: outline(inputBorder),
        focusedBorder: outline(focus, width: 2),
        errorBorder: outline(colorScheme.error),
        focusedErrorBorder: outline(colorScheme.error, width: 2),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.bold),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colorScheme.primary.withValues(alpha: indicatorAlpha),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}