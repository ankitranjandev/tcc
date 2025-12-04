import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryBlue = Color(0xFF5B6EF5);
  static const Color primaryBlueDark = Color(0xFF4A5CD4);
  static const Color primaryBlueLight = Color(0xFF7C8DF7);

  // Secondary Colors
  static const Color secondaryYellow = Color(0xFFF9B234);
  static const Color secondaryYellowDark = Color(0xFFE6A020);
  static const Color secondaryGreen = Color(0xFF00C896);
  static const Color secondaryGreenLight = Color(0xFF4AE4BC);

  // Semantic Colors
  static const Color success = Color(0xFF00C896);
  static const Color warning = Color(0xFFF9B234);
  static const Color error = Color(0xFFFF5757);
  static const Color info = Color(0xFF5B6EF5);

  // Neutral Colors
  static const Color black = Color(0xFF1A1A1A);
  static const Color gray900 = Color(0xFF2D2D2D);
  static const Color gray800 = Color(0xFF4A4A4A);
  static const Color gray700 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFFB5B5B5);
  static const Color gray400 = Color(0xFFD1D5DB);
  static const Color gray300 = Color(0xFFE5E7EB);
  static const Color gray200 = Color(0xFFF3F4F6);
  static const Color gray100 = Color(0xFFF9FAFB);
  static const Color white = Color(0xFFFFFFFF);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryBlueLight],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient yellowCardGradient = LinearGradient(
    colors: [secondaryYellow, Color(0xFFFDD97D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenCardGradient = LinearGradient(
    colors: [secondaryGreen, secondaryGreenLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
