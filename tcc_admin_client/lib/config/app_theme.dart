import 'package:flutter/material.dart';
import 'app_colors.dart';

/// TCC Admin Application Theme Configuration
class AppTheme {
  // Private constructor
  AppTheme._();

  // ==================== Spacing ====================
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space64 = 64.0;

  // ==================== Border Radius ====================
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  static const double radiusFull = 999.0;

  // ==================== Font Sizes ====================
  static const double fontSizeH1 = 32.0;
  static const double fontSizeH2 = 28.0;
  static const double fontSizeH3 = 24.0;
  static const double fontSizeH4 = 20.0;
  static const double fontSizeH5 = 18.0;
  static const double fontSizeBody1 = 16.0;
  static const double fontSizeBody2 = 14.0;
  static const double fontSizeCaption = 12.0;
  static const double fontSizeSmall = 10.0;

  // ==================== Layout Dimensions ====================
  static const double sidebarWidth = 280.0;
  static const double sidebarCollapsedWidth = 64.0;
  static const double topbarHeight = 64.0;

  // ==================== Light Theme ====================
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Inter',

      // Color Scheme
      colorScheme: ColorScheme.light(
        primary: AppColors.accentBlue,
        secondary: AppColors.success,
        error: AppColors.error,
        surface: AppColors.white,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onError: AppColors.white,
        onSurface: AppColors.textPrimary,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.bgSecondary,

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: fontSizeH4,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        shadowColor: Colors.black.withValues(alpha: 0.05),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgTertiary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: AppColors.accentBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: space20,
          vertical: space16,
        ),
        hintStyle: const TextStyle(
          color: AppColors.gray600,
          fontSize: fontSizeBody1,
        ),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentBlue,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: space24,
            vertical: space16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeBody1,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accentBlue,
          padding: const EdgeInsets.symmetric(
            horizontal: space16,
            vertical: space12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeBody1,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accentBlue,
          side: const BorderSide(color: AppColors.accentBlue, width: 2),
          padding: const EdgeInsets.symmetric(
            horizontal: space24,
            vertical: space16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeBody1,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Icon Button
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.gray700,
        ),
      ),

      // Data Table
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(AppColors.bgSecondary),
        headingTextStyle: const TextStyle(
          color: AppColors.gray700,
          fontSize: fontSizeCaption,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        dataTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: fontSizeBody2,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.gray200),
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.gray200,
        thickness: 1,
        space: 1,
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accentBlue,
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: fontSizeH1,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          fontSize: fontSizeH2,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.3,
        ),
        displaySmall: TextStyle(
          fontSize: fontSizeH3,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.3,
        ),
        headlineMedium: TextStyle(
          fontSize: fontSizeH4,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
        headlineSmall: TextStyle(
          fontSize: fontSizeH5,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
        bodyLarge: TextStyle(
          fontSize: fontSizeBody1,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: fontSizeBody2,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: fontSizeCaption,
          fontWeight: FontWeight.w400,
          color: AppColors.textTertiary,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: fontSizeBody1,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
          height: 1.2,
        ),
      ),
    );
  }
}
