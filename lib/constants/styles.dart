import 'package:flutter/material.dart';
import 'colors.dart';

class AppStyles {
  // Headings
  static const TextStyle headingLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Body Text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: AppColors.textLight,
  );

  // Buttons
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // Cards
  static const TextStyle cardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  // Status Text
  static const TextStyle successText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.success,
  );

  static const TextStyle warningText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.warning,
  );

  static const TextStyle dangerText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.danger,
  );

  static const TextStyle splashTitle = TextStyle(
  fontSize: 32,
  fontWeight: FontWeight.bold,
  color: Colors.white,
  letterSpacing: 1,
);

static const TextStyle splashSubtitle = TextStyle(
  fontSize: 16,
  color: Colors.white70,
);

static const TextStyle appBarTitle = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.bold,
  color: AppColors.textPrimary,
);
}
