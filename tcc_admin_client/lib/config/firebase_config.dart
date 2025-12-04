import 'package:flutter/foundation.dart';

/// Firebase configuration class
/// This class manages Firebase configuration for different environments
class FirebaseConfig {
  // Firebase Web Configuration
  // TODO: For production, use --dart-define flags or environment-specific configs
  static const String apiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'AIzaSyCXGqJqXrjQJGQMQtDbk2IeIFzQrB7P0Ko',
  );

  static const String authDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
    defaultValue: 'tcc-app-ebb14.firebaseapp.com',
  );

  static const String projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'tcc-app-ebb14',
  );

  static const String storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'tcc-app-ebb14.firebasestorage.app',
  );

  static const String messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '545764390154',
  );

  static const String appId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: '1:545764390154:web:533ebfdec3f5fdb9d4f6f3',
  );

  static const String measurementId = String.fromEnvironment(
    'FIREBASE_MEASUREMENT_ID',
    defaultValue: 'G-YQZQ8NJYPD',
  );

  /// Check if Firebase is properly configured
  static bool get isConfigured {
    return apiKey.isNotEmpty &&
        authDomain.isNotEmpty &&
        projectId.isNotEmpty &&
        storageBucket.isNotEmpty &&
        messagingSenderId.isNotEmpty &&
        appId.isNotEmpty;
  }

  /// Get Firebase options map for web
  static Map<String, String> get webOptions => {
        'apiKey': apiKey,
        'authDomain': authDomain,
        'projectId': projectId,
        'storageBucket': storageBucket,
        'messagingSenderId': messagingSenderId,
        'appId': appId,
        'measurementId': measurementId,
      };

  /// Print configuration status (for debugging)
  static void printConfigStatus() {
    if (kDebugMode) {
      print('Firebase Configuration Status:');
      print('API Key: ${apiKey.isNotEmpty ? "✓" : "✗"}');
      print('Auth Domain: ${authDomain.isNotEmpty ? "✓" : "✗"}');
      print('Project ID: ${projectId.isNotEmpty ? "✓" : "✗"}');
      print('Storage Bucket: ${storageBucket.isNotEmpty ? "✓" : "✗"}');
      print('Messaging Sender ID: ${messagingSenderId.isNotEmpty ? "✓" : "✗"}');
      print('App ID: ${appId.isNotEmpty ? "✓" : "✗"}');
      print('Measurement ID: ${measurementId.isNotEmpty ? "✓" : "✗"}');
      print('Overall Status: ${isConfigured ? "✓ Configured" : "✗ Not Configured"}');
    }
  }
}
