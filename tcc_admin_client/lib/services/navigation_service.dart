import 'package:flutter/material.dart';

/// Navigation Service
/// Provides global navigation capabilities for the app
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;

  NavigationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Get the current build context
  BuildContext? get context => navigatorKey.currentContext;

  /// Navigate to a named route
  Future<dynamic>? navigateTo(String routeName, {Object? arguments}) {
    return navigatorKey.currentState?.pushNamed(routeName, arguments: arguments);
  }

  /// Replace current route with a named route
  Future<dynamic>? navigateReplacementTo(String routeName, {Object? arguments}) {
    return navigatorKey.currentState?.pushReplacementNamed(routeName, arguments: arguments);
  }

  /// Navigate back
  void goBack([dynamic result]) {
    return navigatorKey.currentState?.pop(result);
  }

  /// Navigate to login and clear stack
  void navigateToLogin() {
    // This will be handled by go_router, but we can trigger a rebuild
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  /// Show a dialog
  Future<T?> showDialogWidget<T>(Widget dialog) {
    return showDialog<T>(
      context: context!,
      builder: (context) => dialog,
    );
  }

  /// Show a bottom sheet
  Future<T?> showBottomSheetWidget<T>(Widget bottomSheet) {
    return showModalBottomSheet<T>(
      context: context!,
      builder: (context) => bottomSheet,
    );
  }

  /// Show a snackbar
  void showSnackBar(String message, {Color? backgroundColor}) {
    final scaffold = ScaffoldMessenger.of(context!);
    scaffold.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
