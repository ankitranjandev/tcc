import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _messageController;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;

  bool _isConnected = false;
  bool _shouldReconnect = true;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  String? _url;
  String? _authToken;

  // Event listeners
  final Map<String, List<Function(Map<String, dynamic>)>> _eventListeners = {};

  Stream<Map<String, dynamic>> get messageStream =>
      _messageController?.stream ?? const Stream.empty();

  bool get isConnected => _isConnected;

  Future<void> connect({
    required String url,
    String? authToken,
  }) async {
    _url = url;
    _authToken = authToken;

    if (_isConnected) {
      debugPrint('WebSocket already connected');
      return;
    }

    try {
      debugPrint('Connecting to WebSocket: $url');

      _messageController = StreamController<Map<String, dynamic>>.broadcast();

      final uri = Uri.parse(url);
      _channel = WebSocketChannel.connect(uri);

      // Listen to messages
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      _isConnected = true;
      _reconnectAttempts = 0;

      // Send authentication if token provided
      if (_authToken != null) {
        _sendMessage({
          'type': 'auth',
          'token': _authToken,
        });
      }

      // Start heartbeat
      _startHeartbeat();

      debugPrint('WebSocket connected successfully');
    } catch (e) {
      debugPrint('WebSocket connection error: $e');
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message.toString());

      debugPrint('WebSocket message received: $data');

      // Add to message stream
      _messageController?.add(data);

      // Handle specific event types
      final eventType = data['type'] as String?;
      if (eventType != null && _eventListeners.containsKey(eventType)) {
        for (final listener in _eventListeners[eventType]!) {
          listener(data);
        }
      }

      // Handle heartbeat response
      if (eventType == 'pong') {
        debugPrint('Heartbeat acknowledged');
      }
    } catch (e) {
      debugPrint('Error processing WebSocket message: $e');
    }
  }

  void _onError(error) {
    debugPrint('WebSocket error: $error');
    _isConnected = false;
    _scheduleReconnect();
  }

  void _onDone() {
    debugPrint('WebSocket connection closed');
    _isConnected = false;
    _heartbeatTimer?.cancel();

    if (_shouldReconnect) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('Max reconnect attempts reached');
      return;
    }

    _reconnectAttempts++;
    debugPrint('Scheduling reconnect attempt $_reconnectAttempts in ${_reconnectDelay.inSeconds}s');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      if (_url != null) {
        connect(url: _url!, authToken: _authToken);
      }
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (_isConnected) {
        _sendMessage({'type': 'ping'});
      }
    });
  }

  void _sendMessage(Map<String, dynamic> message) {
    if (!_isConnected || _channel == null) {
      debugPrint('Cannot send message: not connected');
      return;
    }

    try {
      final jsonMessage = jsonEncode(message);
      _channel!.sink.add(jsonMessage);
      debugPrint('Message sent: $message');
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  // Public methods

  void send(String type, Map<String, dynamic> data) {
    _sendMessage({
      'type': type,
      ...data,
    });
  }

  void subscribe(String eventType, Function(Map<String, dynamic>) callback) {
    if (!_eventListeners.containsKey(eventType)) {
      _eventListeners[eventType] = [];
    }
    _eventListeners[eventType]!.add(callback);
    debugPrint('Subscribed to event: $eventType');
  }

  void unsubscribe(String eventType, [Function(Map<String, dynamic>)? callback]) {
    if (callback != null) {
      _eventListeners[eventType]?.remove(callback);
    } else {
      _eventListeners.remove(eventType);
    }
    debugPrint('Unsubscribed from event: $eventType');
  }

  void updateAuthToken(String token) {
    _authToken = token;
    if (_isConnected) {
      _sendMessage({
        'type': 'auth',
        'token': token,
      });
    }
  }

  Future<void> disconnect() async {
    debugPrint('Disconnecting WebSocket');
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();

    if (_channel != null) {
      await _channel!.sink.close(status.goingAway);
      _channel = null;
    }

    _isConnected = false;
    await _messageController?.close();
    _messageController = null;
  }

  void dispose() {
    disconnect();
    _eventListeners.clear();
  }

  // Convenience methods for common events

  void subscribeToWalletUpdates(Function(Map<String, dynamic>) callback) {
    subscribe('wallet_update', callback);
  }

  void subscribeToOrderUpdates(Function(Map<String, dynamic>) callback) {
    subscribe('order_update', callback);
  }

  void subscribeToTransactionUpdates(Function(Map<String, dynamic>) callback) {
    subscribe('transaction_update', callback);
  }

  void subscribeToCommissionUpdates(Function(Map<String, dynamic>) callback) {
    subscribe('commission_update', callback);
  }

  void subscribeToNotifications(Function(Map<String, dynamic>) callback) {
    subscribe('notification', callback);
  }

  void requestWalletBalance() {
    send('request', {'resource': 'wallet_balance'});
  }

  void requestOrderStatus(String orderId) {
    send('request', {'resource': 'order_status', 'order_id': orderId});
  }
}

// Example usage:
/*
void initWebSocket() {
  final ws = WebSocketService();

  // Connect
  await ws.connect(
    url: 'wss://api.example.com/ws',
    authToken: 'your-auth-token',
  );

  // Subscribe to events
  ws.subscribeToWalletUpdates((data) {
    debugPrint('Wallet updated: ${data['balance']}');
    // Update UI
  });

  ws.subscribeToOrderUpdates((data) {
    debugPrint('Order update: ${data['status']}');
    // Show notification or update UI
  });

  // Send custom message
  ws.send('custom_event', {
    'key': 'value',
  });

  // Disconnect when done
  await ws.disconnect();
}
*/
