import 'package:flutter/material.dart';

/// Responsive utility class for handling different screen sizes
class Responsive {
  // Breakpoints
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double largeDesktop = 1536;

  /// Check if current screen is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobile;
  }

  /// Check if current screen is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < desktop;
  }

  /// Check if current screen is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktop;
  }

  /// Check if current screen is large desktop
  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= largeDesktop;
  }

  /// Get value based on screen size
  static T value<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }

  /// Get responsive padding
  static EdgeInsets padding(BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    final padding = value(
      context: context,
      mobile: mobile ?? 16.0,
      tablet: tablet ?? 24.0,
      desktop: desktop ?? 32.0,
    );
    return EdgeInsets.all(padding);
  }

  /// Get responsive horizontal padding
  static EdgeInsets horizontalPadding(BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    final padding = value(
      context: context,
      mobile: mobile ?? 16.0,
      tablet: tablet ?? 24.0,
      desktop: desktop ?? 32.0,
    );
    return EdgeInsets.symmetric(horizontal: padding);
  }

  /// Get responsive vertical padding
  static EdgeInsets verticalPadding(BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    final padding = value(
      context: context,
      mobile: mobile ?? 16.0,
      tablet: tablet ?? 24.0,
      desktop: desktop ?? 32.0,
    );
    return EdgeInsets.symmetric(vertical: padding);
  }

  /// Get responsive grid column count
  static int gridColumns(BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 4,
  }) {
    return value(
      context: context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  /// Get responsive font size
  static double fontSize(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return value(
      context: context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.1,
      desktop: desktop ?? mobile * 1.2,
    );
  }

  /// Get responsive spacing
  static double spacing(BuildContext context, {
    double mobile = 16.0,
    double? tablet,
    double? desktop,
  }) {
    return value(
      context: context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.5,
      desktop: desktop ?? mobile * 2,
    );
  }

  /// Build responsive widget based on screen size
  static Widget builder({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }

  /// Get screen width
  static double width(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double height(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Get safe area padding
  static EdgeInsets safeArea(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Check if device is in landscape mode
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Check if device is in portrait mode
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }
}

/// Extension on BuildContext for easier responsive access
extension ResponsiveContext on BuildContext {
  bool get isMobile => Responsive.isMobile(this);
  bool get isTablet => Responsive.isTablet(this);
  bool get isDesktop => Responsive.isDesktop(this);
  bool get isLargeDesktop => Responsive.isLargeDesktop(this);

  double get screenWidth => Responsive.width(this);
  double get screenHeight => Responsive.height(this);

  bool get isLandscape => Responsive.isLandscape(this);
  bool get isPortrait => Responsive.isPortrait(this);
}
