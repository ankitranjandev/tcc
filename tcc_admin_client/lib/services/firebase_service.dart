import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import '../config/firebase_config.dart';

/// Firebase service to manage Firebase initialization and instances
class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance {
    _instance ??= FirebaseService._();
    return _instance!;
  }

  FirebaseService._();

  // Firebase instances
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  FirebaseStorage? _storage;
  FirebaseAnalytics? _analytics;

  bool _isInitialized = false;

  /// Check if Firebase is initialized
  bool get isInitialized => _isInitialized;

  /// Get Firebase Auth instance
  FirebaseAuth get auth {
    if (!_isInitialized) {
      throw Exception('Firebase not initialized. Call initialize() first.');
    }
    return _auth!;
  }

  /// Get Firestore instance
  FirebaseFirestore get firestore {
    if (!_isInitialized) {
      throw Exception('Firebase not initialized. Call initialize() first.');
    }
    return _firestore!;
  }

  /// Get Firebase Storage instance
  FirebaseStorage get storage {
    if (!_isInitialized) {
      throw Exception('Firebase not initialized. Call initialize() first.');
    }
    return _storage!;
  }

  /// Get Firebase Analytics instance
  FirebaseAnalytics get analytics {
    if (!_isInitialized) {
      throw Exception('Firebase not initialized. Call initialize() first.');
    }
    return _analytics!;
  }

  /// Initialize Firebase
  Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) {
        print('Firebase already initialized');
      }
      return;
    }

    try {
      if (kDebugMode) {
        print('Initializing Firebase...');
        FirebaseConfig.printConfigStatus();
      }

      // Check if configuration is valid
      if (!FirebaseConfig.isConfigured) {
        throw Exception(
          'Firebase configuration is incomplete. Please set all required environment variables.',
        );
      }

      // Initialize Firebase for web
      if (kIsWeb) {
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: FirebaseConfig.apiKey,
            authDomain: FirebaseConfig.authDomain,
            projectId: FirebaseConfig.projectId,
            storageBucket: FirebaseConfig.storageBucket,
            messagingSenderId: FirebaseConfig.messagingSenderId,
            appId: FirebaseConfig.appId,
            measurementId: FirebaseConfig.measurementId,
          ),
        );
      } else {
        // For other platforms, use the default initialization
        await Firebase.initializeApp();
      }

      // Initialize service instances
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _storage = FirebaseStorage.instance;
      _analytics = FirebaseAnalytics.instance;

      // Configure Firestore settings
      if (kDebugMode) {
        // Enable Firestore logging in debug mode
        _firestore!.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      }

      _isInitialized = true;

      if (kDebugMode) {
        print('Firebase initialized successfully');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error initializing Firebase: $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  /// Sign out from Firebase Auth
  Future<void> signOut() async {
    if (_isInitialized && _auth != null) {
      await _auth!.signOut();
    }
  }

  /// Dispose Firebase service
  void dispose() {
    _auth = null;
    _firestore = null;
    _storage = null;
    _analytics = null;
    _isInitialized = false;
  }

  /// Get current user
  User? get currentUser => _auth?.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => currentUser != null;

  /// Listen to auth state changes
  Stream<User?> get authStateChanges {
    if (!_isInitialized) {
      throw Exception('Firebase not initialized. Call initialize() first.');
    }
    return _auth!.authStateChanges();
  }

  /// Log analytics event
  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    if (_isInitialized && _analytics != null) {
      await _analytics!.logEvent(
        name: name,
        parameters: parameters?.cast<String, Object>(),
      );
    }
  }

  /// Set current screen for analytics
  Future<void> setCurrentScreen({
    required String screenName,
    String? screenClassOverride,
  }) async {
    if (_isInitialized && _analytics != null) {
      await _analytics!.logScreenView(
        screenName: screenName,
        screenClass: screenClassOverride,
      );
    }
  }
}
