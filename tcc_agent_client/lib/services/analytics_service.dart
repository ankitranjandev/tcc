import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'dart:async';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  FirebaseAnalytics? _analytics;
  FirebaseCrashlytics? _crashlytics;
  bool _isInitialized = false;

  FirebaseAnalyticsObserver get analyticsObserver =>
      FirebaseAnalyticsObserver(analytics: _analytics!);

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _analytics = FirebaseAnalytics.instance;
      _crashlytics = FirebaseCrashlytics.instance;

      // Configure Crashlytics
      await _configureCrashlytics();

      // Set up analytics
      await _configureAnalytics();

      _isInitialized = true;
      debugPrint('Analytics service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing analytics service: $e');
    }
  }

  Future<void> _configureCrashlytics() async {
    if (_crashlytics == null) return;

    // Enable crashlytics collection
    await _crashlytics!.setCrashlyticsCollectionEnabled(true);

    // Pass all uncaught errors from the framework to Crashlytics
    FlutterError.onError = (errorDetails) {
      _crashlytics!.recordFlutterFatalError(errorDetails);
    };

    // Pass all uncaught asynchronous errors to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics!.recordError(error, stack, fatal: true);
      return true;
    };

    debugPrint('Crashlytics configured successfully');
  }

  Future<void> _configureAnalytics() async {
    if (_analytics == null) return;

    // Set analytics collection
    await _analytics!.setAnalyticsCollectionEnabled(true);

    debugPrint('Analytics configured successfully');
  }

  // User tracking

  Future<void> setUserId(String userId) async {
    if (_analytics == null) return;

    try {
      await _analytics!.setUserId(id: userId);
      await _crashlytics?.setUserIdentifier(userId);

      debugPrint('User ID set: $userId');
    } catch (e) {
      debugPrint('Error setting user ID: $e');
    }
  }

  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    if (_analytics == null) return;

    try {
      await _analytics!.setUserProperty(name: name, value: value);
      debugPrint('User property set: $name = $value');
    } catch (e) {
      debugPrint('Error setting user property: $e');
    }
  }

  Future<void> setUserRole(String role) async {
    await setUserProperty(name: 'user_role', value: role);
  }

  Future<void> setAgentLocation(String location) async {
    await setUserProperty(name: 'agent_location', value: location);
  }

  // Event tracking

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (_analytics == null) return;

    try {
      await _analytics!.logEvent(
        name: name,
        parameters: parameters,
      );

      debugPrint('Event logged: $name ${parameters != null ? "with parameters: $parameters" : ""}');
    } catch (e) {
      debugPrint('Error logging event: $e');
    }
  }

  // Screen tracking

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (_analytics == null) return;

    try {
      await _analytics!.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );

      debugPrint('Screen view logged: $screenName');
    } catch (e) {
      debugPrint('Error logging screen view: $e');
    }
  }

  // Authentication events

  Future<void> logLogin({String? method}) async {
    await logEvent(
      name: 'login',
      parameters: {
        'method': method ?? 'phone',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> logSignUp({String? method}) async {
    await logEvent(
      name: 'sign_up',
      parameters: {
        'method': method ?? 'phone',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> logLogout() async {
    await logEvent(name: 'logout');
  }

  // Transaction events

  Future<void> logTransaction({
    required String transactionId,
    required String type,
    required double amount,
    String? currency,
  }) async {
    await logEvent(
      name: 'transaction_${type.toLowerCase()}',
      parameters: {
        'transaction_id': transactionId,
        'type': type,
        'value': amount,
        'currency': currency ?? 'TCC' as Object,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> logDeposit({
    required String transactionId,
    required double amount,
    String? paymentMethod,
  }) async {
    await logEvent(
      name: 'deposit',
      parameters: {
        'transaction_id': transactionId,
        'value': amount,
        'currency': 'TCC',
        if (paymentMethod != null) 'payment_method': paymentMethod,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> logWithdrawal({
    required String transactionId,
    required double amount,
    String? paymentMethod,
  }) async {
    await logEvent(
      name: 'withdrawal',
      parameters: {
        'transaction_id': transactionId,
        'value': amount,
        'currency': 'TCC',
        if (paymentMethod != null) 'payment_method': paymentMethod,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Order events

  Future<void> logOrderCreated({
    required String orderId,
    required String orderType,
    required double amount,
  }) async {
    await logEvent(
      name: 'order_created',
      parameters: {
        'order_id': orderId,
        'order_type': orderType,
        'value': amount,
        'currency': 'TCC',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> logOrderCompleted({
    required String orderId,
    required String orderType,
    required double amount,
    required double commission,
  }) async {
    await logEvent(
      name: 'order_completed',
      parameters: {
        'order_id': orderId,
        'order_type': orderType,
        'value': amount,
        'commission': commission,
        'currency': 'TCC',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Voting events

  Future<void> logVoteCast({
    required String electionId,
    required String electionTitle,
    required double votingCharge,
  }) async {
    await logEvent(
      name: 'vote_cast',
      parameters: {
        'election_id': electionId,
        'election_title': electionTitle,
        'voting_charge': votingCharge,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Bill payment events

  Future<void> logBillPayment({
    required String billType,
    required double amount,
    String? paymentMethod,
  }) async {
    await logEvent(
      name: 'bill_payment',
      parameters: {
        'bill_type': billType,
        'value': amount,
        'currency': 'TCC',
        if (paymentMethod != null) 'payment_method': paymentMethod,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Commission events

  Future<void> logCommissionEarned({
    required String transactionId,
    required double commission,
    required String commissionType,
  }) async {
    await logEvent(
      name: 'commission_earned',
      parameters: {
        'transaction_id': transactionId,
        'value': commission,
        'currency': 'TCC',
        'commission_type': commissionType,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Error tracking

  Future<void> recordError({
    required dynamic exception,
    StackTrace? stackTrace,
    String? reason,
    bool fatal = false,
  }) async {
    if (_crashlytics == null) return;

    try {
      await _crashlytics!.recordError(
        exception,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );

      debugPrint('Error recorded: $exception');
    } catch (e) {
      debugPrint('Error recording error: $e');
    }
  }

  Future<void> log(String message) async {
    if (_crashlytics == null) return;

    try {
      await _crashlytics!.log(message);
    } catch (e) {
      debugPrint('Error logging message: $e');
    }
  }

  // Custom keys for crash reports

  Future<void> setCustomKey(String key, dynamic value) async {
    if (_crashlytics == null) return;

    try {
      await _crashlytics!.setCustomKey(key, value);
    } catch (e) {
      debugPrint('Error setting custom key: $e');
    }
  }

  // Performance tracking

  Future<void> logPerformance({
    required String metricName,
    required int durationMs,
    Map<String, String>? attributes,
  }) async {
    await logEvent(
      name: 'performance_$metricName',
      parameters: {
        'duration_ms': durationMs,
        ...?attributes,
      },
    );
  }

  Future<void> logApiCall({
    required String endpoint,
    required int durationMs,
    required int statusCode,
  }) async {
    await logEvent(
      name: 'api_call',
      parameters: {
        'endpoint': endpoint,
        'duration_ms': durationMs,
        'status_code': statusCode,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Session tracking

  Future<void> logSessionStart() async {
    await logEvent(
      name: 'session_start',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> logSessionEnd({int? duration}) async {
    await logEvent(
      name: 'session_end',
      parameters: {
        if (duration != null) 'duration_seconds': duration,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Feature usage tracking

  Future<void> logFeatureUsed(String featureName) async {
    await logEvent(
      name: 'feature_used',
      parameters: {
        'feature': featureName,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> logSearchPerformed({
    required String searchTerm,
    String? category,
  }) async {
    await logEvent(
      name: 'search',
      parameters: {
        'search_term': searchTerm,
        if (category != null) 'category': category,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Testing crash reporting (use carefully!)

  Future<void> testCrash() async {
    if (_crashlytics == null) return;

    debugPrint('Testing crash reporting...');
    _crashlytics!.crash();
  }

  Future<void> testException() async {
    try {
      throw Exception('This is a test exception for Crashlytics');
    } catch (e, stackTrace) {
      await recordError(
        exception: e,
        stackTrace: stackTrace,
        reason: 'Test exception',
        fatal: false,
      );
    }
  }

  // Consent management

  Future<void> setAnalyticsConsent(bool enabled) async {
    if (_analytics == null) return;

    try {
      _analytics!.setAnalyticsCollectionEnabled(enabled);
      debugPrint('Analytics collection ${enabled ? "enabled" : "disabled"}');
    } catch (e) {
      debugPrint('Error setting analytics consent: $e');
    }
  }

  Future<void> setCrashlyticsConsent(bool enabled) async {
    if (_crashlytics == null) return;

    try {
      _crashlytics!.setCrashlyticsCollectionEnabled(enabled);
      debugPrint('Crashlytics collection ${enabled ? "enabled" : "disabled"}');
    } catch (e) {
      debugPrint('Error setting crashlytics consent: $e');
    }
  }
}
