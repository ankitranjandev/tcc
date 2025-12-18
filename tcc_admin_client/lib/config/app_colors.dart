import 'package:flutter/material.dart';

/// TCC Admin Application Color Palette
/// Professional dark theme for admin interface
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // ==================== Primary Colors ====================
  /// Dark sidebar background
  static const Color primaryDark = Color(0xFF1A1A1A);

  /// Sidebar hover state
  static const Color primaryGray = Color(0xFF2D2D2D);

  /// Accent blue (consistent with user app)
  static const Color accentBlue = Color(0xFF5B6EF5);

  /// Accent blue light (hover states)
  static const Color accentBlueLight = Color(0xFF7C8DF7);

  /// Accent purple (for voting/polls)
  static const Color accentPurple = Color(0xFF9333EA);

  // ==================== Background Colors ====================
  /// Card backgrounds
  static const Color bgPrimary = Color(0xFFFFFFFF);

  /// Content area background
  static const Color bgSecondary = Color(0xFFF9FAFB);

  /// Input backgrounds
  static const Color bgTertiary = Color(0xFFF3F4F6);

  // ==================== Semantic Colors ====================
  /// Success, Approved
  static const Color success = Color(0xFF00C896);

  /// Pending, Warning
  static const Color warning = Color(0xFFF9B234);

  /// Rejected, Error
  static const Color error = Color(0xFFFF5757);

  /// Info, Processing
  static const Color info = Color(0xFF5B6EF5);

  // ==================== Status Colors ====================
  // User/Agent Status
  static const Color statusApproved = Color(0xFF00C896);
  static const Color statusPending = Color(0xFFF9B234);
  static const Color statusRejected = Color(0xFFFF5757);
  static const Color statusActive = Color(0xFF4CAF50);
  static const Color statusInactive = Color(0xFF9E9E9E);

  // Transaction Status
  static const Color statusCompleted = Color(0xFF00C896);
  static const Color statusProcessing = Color(0xFF5B6EF5);
  static const Color statusFailed = Color(0xFFFF5757);
  static const Color statusCancelled = Color(0xFF9E9E9E);

  // Investment Status
  static const Color statusPaid = Color(0xFF00C896);
  static const Color statusMatured = Color(0xFFF9B234);
  static const Color statusOngoing = Color(0xFF5B6EF5);

  // ==================== Text Colors ====================
  /// Headings
  static const Color textPrimary = Color(0xFF1A1A1A);

  /// Body text
  static const Color textSecondary = Color(0xFF6B7280);

  /// Captions
  static const Color textTertiary = Color(0xFF9CA3AF);

  /// Sidebar text
  static const Color textWhite = Color(0xFFFFFFFF);

  /// Disabled text
  static const Color textMuted = Color(0xFFB5B5B5);

  // ==================== Neutral Colors ====================
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
  static const Color gray50 = Color(0xFFFCFCFC);
  static const Color white = Color(0xFFFFFFFF);

  // ==================== Additional Colors ====================
  // Aliases for consistency across the codebase
  static const Color primary = accentBlue;
  static const Color secondary = accentPurple;
  static const Color background = bgSecondary;
  static const Color cardBackground = bgPrimary;
  static const Color borderLight = gray300;
  static const Color divider = gray300;
  static const Color successGreen = success;
  static const Color errorRed = error;
  static const Color warningOrange = warning;
  static const Color warningYellow = warning;
  static const Color infoBlue = info;

  // ==================== Gradient Colors ====================
  /// Primary button gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [accentBlue, accentBlueLight],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Success card gradient
  static const LinearGradient successGradient = LinearGradient(
    colors: [success, Color(0xFF4AE4BC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Warning card gradient
  static const LinearGradient warningGradient = LinearGradient(
    colors: [warning, Color(0xFFFDD97D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ==================== Shadow Colors ====================
  /// Small shadow
  static BoxShadow get shadowSmall => BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 4,
        offset: const Offset(0, 2),
      );

  /// Medium shadow
  static BoxShadow get shadowMedium => BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 8,
        offset: const Offset(0, 4),
      );

  /// Large shadow
  static BoxShadow get shadowLarge => BoxShadow(
        color: Colors.black.withValues(alpha: 0.12),
        blurRadius: 16,
        offset: const Offset(0, 8),
      );

  /// XLarge shadow
  static BoxShadow get shadowXLarge => BoxShadow(
        color: Colors.black.withValues(alpha: 0.15),
        blurRadius: 24,
        offset: const Offset(0, 12),
      );

  // ==================== Helper Methods ====================
  /// Get status color based on status string
  static Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
      case 'COMPLETED':
      case 'ACTIVE':
      case 'PAID':
        return statusApproved;
      case 'PENDING':
      case 'MATURED':
        return statusPending;
      case 'REJECTED':
      case 'FAILED':
        return statusRejected;
      case 'INACTIVE':
      case 'CANCELLED':
        return statusInactive;
      case 'PROCESSING':
      case 'ONGOING':
        return statusProcessing;
      default:
        return gray500;
    }
  }

  /// Get background color for status badge
  static Color getStatusBackgroundColor(String status) {
    return getStatusColor(status).withValues(alpha: 0.1);
  }
}
