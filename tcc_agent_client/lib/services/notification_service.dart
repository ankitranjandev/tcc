import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  bool _isInitialized = false;

  // Notification channels
  static const String _defaultChannelId = 'tcc_default_channel';
  static const String _transactionChannelId = 'tcc_transactions';
  static const String _orderChannelId = 'tcc_orders';
  static const String _systemChannelId = 'tcc_system';

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permissions
      await _requestPermission();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Configure Firebase Messaging
      await _configureFCM();

      // Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $_fcmToken');

      // Save token to preferences
      if (_fcmToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _fcmToken!);
        // TODO: Send token to backend
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _saveAndSendToken(newToken);
      });

      _isInitialized = true;
      debugPrint('Notification service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
    }
  }

  Future<void> _requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('Notification permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    const defaultChannel = AndroidNotificationChannel(
      _defaultChannelId,
      'Default Notifications',
      description: 'General notifications',
      importance: Importance.high,
      playSound: true,
    );

    const transactionChannel = AndroidNotificationChannel(
      _transactionChannelId,
      'Transactions',
      description: 'Transaction updates and confirmations',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    const orderChannel = AndroidNotificationChannel(
      _orderChannelId,
      'Payment Orders',
      description: 'Payment order notifications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const systemChannel = AndroidNotificationChannel(
      _systemChannelId,
      'System Notifications',
      description: 'System updates and announcements',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(defaultChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(transactionChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(orderChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(systemChannel);
  }

  Future<void> _configureFCM() async {
    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);

    // Check if app was opened from notification
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationOpen(initialMessage);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.messageId}');

    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      _showLocalNotification(
        title: notification.title ?? 'TCC Agent',
        body: notification.body ?? '',
        payload: jsonEncode(data),
        channelId: _getChannelId(data['type']),
      );
    }
  }

  void _handleNotificationOpen(RemoteMessage message) {
    debugPrint('Notification opened: ${message.messageId}');
    final data = message.data;

    // TODO: Navigate to appropriate screen based on notification type
    _handleNotificationNavigation(data);
  }

  void _handleNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');

    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        _handleNotificationNavigation(data);
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'];
    final id = data['id'];

    debugPrint('Navigate to: $type with id: $id');

    // TODO: Implement navigation based on notification type
    // Example:
    // - transaction -> Transaction details screen
    // - order -> Order details screen
    // - commission -> Commission dashboard
    // - announcement -> Announcements screen
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = _defaultChannelId,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      channelDescription: _getChannelDescription(channelId),
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      styleInformation: BigTextStyleInformation(body),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  String _getChannelId(String? type) {
    switch (type) {
      case 'transaction':
        return _transactionChannelId;
      case 'order':
        return _orderChannelId;
      case 'system':
      case 'announcement':
        return _systemChannelId;
      default:
        return _defaultChannelId;
    }
  }

  String _getChannelName(String channelId) {
    switch (channelId) {
      case _transactionChannelId:
        return 'Transactions';
      case _orderChannelId:
        return 'Payment Orders';
      case _systemChannelId:
        return 'System Notifications';
      default:
        return 'Default Notifications';
    }
  }

  String _getChannelDescription(String channelId) {
    switch (channelId) {
      case _transactionChannelId:
        return 'Transaction updates and confirmations';
      case _orderChannelId:
        return 'Payment order notifications';
      case _systemChannelId:
        return 'System updates and announcements';
      default:
        return 'General notifications';
    }
  }

  Future<void> _saveAndSendToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);

      // TODO: Send token to backend
      debugPrint('New FCM token: $token');
      // await ApiService().updateFCMToken(token);
    } catch (e) {
      debugPrint('Error saving/sending FCM token: $e');
    }
  }

  // Public methods

  Future<String?> getToken() async {
    if (_fcmToken != null) return _fcmToken;

    _fcmToken = await _firebaseMessaging.getToken();
    return _fcmToken;
  }

  Future<void> deleteToken() async {
    await _firebaseMessaging.deleteToken();
    _fcmToken = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fcm_token');
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }

  // Show local notification manually (for testing or custom use)
  Future<void> showNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? channelId,
  }) async {
    await _showLocalNotification(
      title: title,
      body: body,
      payload: data != null ? jsonEncode(data) : null,
      channelId: channelId ?? _defaultChannelId,
    );
  }

  // Get notification settings
  Future<NotificationSettings> getSettings() async {
    return await _firebaseMessaging.getNotificationSettings();
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final settings = await getSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }
}
