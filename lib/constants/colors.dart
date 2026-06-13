import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors (Slightly desaturated for dark mode to prevent eye strain)
// Primary Colors (Emerald/Teal Theme)
  static const Color primary = Color(0xFF0D9488);      // Teal 600 - Calming, professional primary
  static const Color primaryLight = Color(0xFF2DD4BF); // Teal 400 - Vibrant accent/active state
  static const Color primaryDark = Color(0xFF115E59);  // Teal 800 - Deep container fill

  // Status Colors (Softened for dark background contrast)
  static const Color success = Color(0xFF34D399);      // Soft dark-mode green
  static const Color warning = Color(0xFFFBBF24);      // Soft dark-mode amber
  static const Color danger = Color(0xFFF87171);       // Soft dark-mode red

  // Background Colors (Your excellent Tailwind-style dark neutrals)
  static const Color background = Color(0xFF111827);   // Slate 900 (Deep background)
  static const Color cardBackground = Color(0xFF1F2937); // Slate 800 (Elevated surfaces)
   static const Color icon = Color(0xFFF9FAFB);

  // Text Colors (FIXED: Lifted to high-contrast whites/light grays)
  static const Color textPrimary = Color(0xFFF9FAFB);    // Slate 50 (Crisp white for titles)
  static const Color textSecondary = Color(0xFFE5E7EB);  // Slate 200 (Highly legible body text)
  static const Color textLight = Color(0xFF9CA3AF);      // Slate 400 (Captions and disabled text)

  // Border & Structural Colors (FIXED: Made subtle and light against the dark background)
  static const Color border = Color(0xFF374151);       // Slate 700 (Clean, subtle borders)
  static const Color divider = Color(0xFF4B5563);      // Slate 600 (Slightly more visible dividers)

  // Sensor Colors (Shifted up to vibrant pastel-ish tones for dark mode pop)
  static const Color accentPurple = Color(0xFFA78BFA);
  static const Color accentTeal = Color(0xFF2DD4BF);
  static const Color accentIndigo = Color(0xFF818CF8);

  // Alert Colors (High visibility but balanced against deep slate)
  static const Color fallDetected = Color(0xFFEF4444);  // Clear, bright red alert
  static const Color preFall = Color(0xFFF59E0B);       // Warning amber
  static const Color normal = Color(0xFF10B981);        // Safe green

  // Connection Status
  static const Color connected = Color(0xFF10B981);
  static const Color disconnected = Color(0xFFEF4444);
}