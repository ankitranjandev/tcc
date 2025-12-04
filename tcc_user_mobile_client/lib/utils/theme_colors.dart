import 'package:flutter/material.dart';

/// Utility class to get theme-aware colors for dark mode support
class ThemeColors {
  /// Get text color based on text style and theme
  static Color? getTextColor(BuildContext context, TextStyleType type) {
    final theme = Theme.of(context);

    switch (type) {
      case TextStyleType.headline:
        return theme.textTheme.headlineMedium?.color;
      case TextStyleType.title:
        return theme.textTheme.titleLarge?.color;
      case TextStyleType.subtitle:
        return theme.textTheme.titleMedium?.color;
      case TextStyleType.body:
        return theme.textTheme.bodyLarge?.color;
      case TextStyleType.bodySmall:
        return theme.textTheme.bodySmall?.color;
      case TextStyleType.caption:
        return theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7);
      case TextStyleType.label:
        return theme.textTheme.labelLarge?.color;
    }
  }

  /// Get surface color (for cards, containers)
  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).cardColor;
  }

  /// Get background color
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  /// Get divider/border color
  static Color getDividerColor(BuildContext context) {
    return Theme.of(context).dividerColor;
  }

  /// Get icon color
  static Color? getIconColor(BuildContext context, {double opacity = 1.0}) {
    return Theme.of(context).iconTheme.color?.withValues(alpha: opacity);
  }

  /// Get disabled color
  static Color getDisabledColor(BuildContext context) {
    return Theme.of(context).disabledColor;
  }

  /// Get hint color
  static Color? getHintColor(BuildContext context) {
    return Theme.of(context).hintColor;
  }

  /// Check if dark mode
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}

enum TextStyleType {
  headline,
  title,
  subtitle,
  body,
  bodySmall,
  caption,
  label,
}