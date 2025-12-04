// TEMPORARILY DISABLED - Enable when background_location package is compatible
// import 'dart:async';
// import 'dart:math' as math;
// import 'package:flutter/foundation.dart';
// import 'package:background_location/background_location.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';

// Placeholder - Location service disabled for APK build
import 'package:flutter/foundation.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Future<void> initialize() async {
    debugPrint('Location service temporarily disabled');
  }
}

/*
// ORIGINAL CODE - Commented out temporarily for APK build

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:background_location/background_location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  bool _isTracking = false;
  bool _isInitialized = false;

  Location? _currentLocation;
  final List<Location> _locationHistory = [];

  StreamController<Location>? _locationStreamController;
  Timer? _periodicUpdateTimer;

  // Configuration
  static const int _updateIntervalMinutes = 5;
  static const int _maxHistorySize = 100;
  static const String _locationHistoryKey = 'location_history';

  Stream<Location> get locationStream =>
      _locationStreamController?.stream ?? const Stream.empty();

  Location? get currentLocation => _currentLocation;
  bool get isTracking => _isTracking;
  List<Location> get locationHistory => List.unmodifiable(_locationHistory);

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _locationStreamController = StreamController<Location>.broadcast();

      // Load location history from local storage
      await _loadLocationHistory();

      _isInitialized = true;
      debugPrint('Location service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing location service: $e');
    }
  }

  Future<bool> requestPermission() async {
    try {
      // background_location handles permissions internally
      debugPrint('Requesting location permission');
      return true;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return false;
    }
  }

  Future<void> startTracking() async {
    if (_isTracking) {
      debugPrint('Location tracking already active');
      return;
    }

    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Check and request permissions
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        debugPrint('Location permission denied');
        return;
      }

      // Configure background location
      await BackgroundLocation.setAndroidNotification(
        title: 'TCC Agent',
        message: 'Tracking location for order management',
        icon: '@mipmap/ic_launcher',
      );

      // Set update interval
      await BackgroundLocation.setAndroidConfiguration(1000 * 60); // 1 minute

      // Start listening to location updates
      BackgroundLocation.startLocationService();

      BackgroundLocation.getLocationUpdates((location) {
        _handleLocationUpdate(location);
      });

      _isTracking = true;

      // Start periodic backend updates
      _startPeriodicUpdates();

      debugPrint('Location tracking started');
    } catch (e) {
      debugPrint('Error starting location tracking: $e');
      _isTracking = false;
    }
  }

  Future<void> stopTracking() async {
    if (!_isTracking) return;

    try {
      await BackgroundLocation.stopLocationService();
      _periodicUpdateTimer?.cancel();
      _isTracking = false;

      debugPrint('Location tracking stopped');
    } catch (e) {
      debugPrint('Error stopping location tracking: $e');
    }
  }

  void _handleLocationUpdate(Location location) {
    _currentLocation = location;

    // Add to history
    _locationHistory.add(location);
    if (_locationHistory.length > _maxHistorySize) {
      _locationHistory.removeAt(0);
    }

    // Save to local storage
    _saveLocationHistory();

    // Broadcast to listeners
    _locationStreamController?.add(location);

    debugPrint('Location updated: ${location.latitude}, ${location.longitude}');
  }

  void _startPeriodicUpdates() {
    _periodicUpdateTimer?.cancel();

    _periodicUpdateTimer = Timer.periodic(
      Duration(minutes: _updateIntervalMinutes),
      (timer) {
        if (_currentLocation != null) {
          _sendLocationToBackend(_currentLocation!);
        }
      },
    );
  }

  Future<void> _sendLocationToBackend(Location location) async {
    try {
      debugPrint('Sending location to backend: ${location.latitude}, ${location.longitude}');

      // TODO: Replace with actual API call
      // await ApiService().updateAgentLocation(
      //   latitude: location.latitude,
      //   longitude: location.longitude,
      //   accuracy: location.accuracy,
      //   timestamp: DateTime.now(),
      // );

      debugPrint('Location sent to backend successfully');
    } catch (e) {
      debugPrint('Error sending location to backend: $e');
    }
  }

  Future<void> _loadLocationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_locationHistoryKey);

      if (historyJson != null) {
        final List<dynamic> decoded = jsonDecode(historyJson);
        _locationHistory.clear();

        for (final item in decoded) {
          _locationHistory.add(LocationJson.locationFromJson(item as Map<String, dynamic>));
        }

        debugPrint('Loaded ${_locationHistory.length} location history items');
      }
    } catch (e) {
      debugPrint('Error loading location history: $e');
    }
  }

  Future<void> _saveLocationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Only save recent locations (last 50)
      final recentLocations = _locationHistory.length > 50
          ? _locationHistory.sublist(_locationHistory.length - 50)
          : _locationHistory;

      final encoded = jsonEncode(
        recentLocations.map((loc) => loc.toJson()).toList(),
      );

      await prefs.setString(_locationHistoryKey, encoded);
    } catch (e) {
      debugPrint('Error saving location history: $e');
    }
  }

  // Get current location once (without starting background tracking)
  Future<Location?> getCurrentLocation() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) return null;

      // Return current cached location
      return _currentLocation;
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  // Calculate distance between two locations in kilometers
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371.0; // km

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  // Find nearby agents (mock implementation - replace with actual API)
  Future<List<NearbyAgent>> findNearbyAgents({double radiusKm = 5.0}) async {
    if (_currentLocation == null) {
      await getCurrentLocation();
    }

    if (_currentLocation == null) {
      return [];
    }

    try {
      debugPrint('Finding nearby agents within ${radiusKm}km');

      // TODO: Replace with actual API call
      // final response = await ApiService().getNearbyAgents(
      //   latitude: _currentLocation!.latitude,
      //   longitude: _currentLocation!.longitude,
      //   radius: radiusKm,
      // );

      // Mock data for testing
      return [
        NearbyAgent(
          id: '1',
          name: 'John Doe',
          latitude: _currentLocation!.latitude! + 0.01,
          longitude: _currentLocation!.longitude! + 0.01,
          distance: 1.2,
          isAvailable: true,
        ),
        NearbyAgent(
          id: '2',
          name: 'Jane Smith',
          latitude: _currentLocation!.latitude! + 0.02,
          longitude: _currentLocation!.longitude! - 0.01,
          distance: 2.5,
          isAvailable: true,
        ),
      ];
    } catch (e) {
      debugPrint('Error finding nearby agents: $e');
      return [];
    }
  }

  // Update agent availability status
  Future<void> updateAvailability(bool isAvailable) async {
    try {
      debugPrint('Updating agent availability: $isAvailable');

      // TODO: Replace with actual API call
      // await ApiService().updateAgentAvailability(isAvailable);

      debugPrint('Agent availability updated successfully');
    } catch (e) {
      debugPrint('Error updating agent availability: $e');
    }
  }

  void dispose() {
    stopTracking();
    _locationStreamController?.close();
    _periodicUpdateTimer?.cancel();
  }
}

// Helper class for nearby agents
class NearbyAgent {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double distance; // in kilometers
  final bool isAvailable;

  NearbyAgent({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.isAvailable,
  });

  factory NearbyAgent.fromJson(Map<String, dynamic> json) {
    return NearbyAgent(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distance: (json['distance'] as num).toDouble(),
      isAvailable: json['is_available'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
      'is_available': isAvailable,
    };
  }
}

// Extension for Location serialization
extension LocationJson on Location {
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude ?? 0.0,
      'longitude': longitude ?? 0.0,
      'accuracy': accuracy ?? 0.0,
      'altitude': altitude ?? 0.0,
      'bearing': bearing ?? 0.0,
      'speed': speed ?? 0.0,
      'time': time ?? 0.0,
      'is_mock': isMock ?? false,
    };
  }

  static Location locationFromJson(Map<String, dynamic> json) {
    return Location(
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      accuracy: json['accuracy'] as double?,
      altitude: json['altitude'] as double?,
      bearing: json['bearing'] as double?,
      speed: json['speed'] as double?,
      time: json['time'] as double?,
      isMock: json['is_mock'] as bool?,
    );
  }
}

*/ // End of commented original code
