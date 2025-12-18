import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Orange/Amber Theme for Agent App
  static const Color primaryOrange = Color(0xFFFF8C42);
  static const Color primaryOrangeDark = Color(0xFFF57C20);
  static const Color primaryOrangeLight = Color(0xFFFFB074);

  // Secondary Colors
  static const Color secondaryTeal = Color(0xFF00897B);
  static const Color secondaryTealLight = Color(0xFF4DB6AC);
  static const Color secondaryPurple = Color(0xFF7E57C2);
  static const Color secondaryPurpleLight = Color(0xFF9575CD);

  // Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFFF5757);
  static const Color info = Color(0xFF42A5F5);

  // Semantic Color Aliases (for consistency across codebase)
  static const Color successGreen = success;
  static const Color warningOrange = warning;
  static const Color errorRed = error;
  static const Color infoBlue = info;

  // Agent Status Colors
  static const Color statusActive = Color(0xFF4CAF50);
  static const Color statusInactive = Color(0xFF9E9E9E);
  static const Color statusBusy = Color(0xFFFFA726);

  // Commission & Earnings Colors
  static const Color commissionGreen = Color(0xFF00C896);
  static const Color earningsAmber = Color(0xFFFFB300);

  // Neutral Colors (Same as user app for consistency)
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

  // Text Colors
  static const Color textPrimary = gray900;
  static const Color textSecondary = gray700;
  static const Color textTertiary = gray600;

  // Background & Border Colors
  static const Color background = gray100;
  static const Color backgroundLight = gray100;
  static const Color borderLight = gray300;
  static const Color cardBackground = white;
  static const Color warningYellow = Color(0xFFFFB300);

  // Aliases for consistency
  static const Color primary = primaryOrange;
  static const Color secondary = secondaryTeal;

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryOrange, primaryOrangeLight],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient tealCardGradient = LinearGradient(
    colors: [secondaryTeal, secondaryTealLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleCardGradient = LinearGradient(
    colors: [secondaryPurple, secondaryPurpleLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient commissionGradient = LinearGradient(
    colors: [commissionGreen, Color(0xFF4AE4BC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient earningsGradient = LinearGradient(
    colors: [earningsAmber, Color(0xFFFFCA28)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
