import 'package:flutter/material.dart';

/// Responsive helper class for handling different screen sizes
class ResponsiveHelper {
  // Device breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Get device type
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < mobileBreakpoint) {
      return DeviceType.mobile;
    } else if (width < tabletBreakpoint) {
      return DeviceType.tablet;
    } else if (width < desktopBreakpoint) {
      return DeviceType.smallDesktop;
    } else {
      return DeviceType.largeDesktop;
    }
  }

  // Check device types
  static bool isMobile(BuildContext context) {
    return getDeviceType(context) == DeviceType.mobile;
  }

  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet;
  }

  static bool isDesktop(BuildContext context) {
    final type = getDeviceType(context);
    return type == DeviceType.smallDesktop || type == DeviceType.largeDesktop;
  }

  // Get responsive values based on screen size
  static T getResponsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.smallDesktop:
      case DeviceType.largeDesktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  // Get screen dimensions
  static Size getScreenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }

  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  // Get responsive font sizes
  static double getFontSize(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return getResponsiveValue<double>(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  // Get responsive padding/spacing
  static EdgeInsets getResponsivePadding(BuildContext context) {
    return EdgeInsets.all(
      getResponsiveValue<double>(
        context,
        mobile: 16.0,
        tablet: 24.0,
        desktop: 32.0,
      ),
    );
  }

  static double getResponsiveSpacing(BuildContext context, {
    double mobileFactor = 1.0,
  }) {
    return getResponsiveValue<double>(
      context,
      mobile: 8.0 * mobileFactor,
      tablet: 12.0 * mobileFactor,
      desktop: 16.0 * mobileFactor,
    );
  }

  // Get responsive grid columns
  static int getGridColumns(BuildContext context, {
    int mobileColumns = 2,
    int? tabletColumns,
    int? desktopColumns,
  }) {
    return getResponsiveValue<int>(
      context,
      mobile: mobileColumns,
      tablet: tabletColumns ?? mobileColumns + 1,
      desktop: desktopColumns ?? (tabletColumns ?? mobileColumns) + 2,
    );
  }

  // Check orientation
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  // Get safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  // Calculate responsive dimensions
  static double getResponsiveWidth(BuildContext context, double percentage) {
    return getScreenWidth(context) * (percentage / 100);
  }

  static double getResponsiveHeight(BuildContext context, double percentage) {
    return getScreenHeight(context) * (percentage / 100);
  }
}

// Device type enum
enum DeviceType {
  mobile,
  tablet,
  smallDesktop,
  largeDesktop,
}