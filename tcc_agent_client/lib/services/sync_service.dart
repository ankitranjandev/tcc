import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'database_service.dart';
import 'dart:convert';

enum SyncStatus {
  idle,
  syncing,
  success,
  failed,
}

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DatabaseService _db = DatabaseService();
  final Connectivity _connectivity = Connectivity();

  StreamController<SyncStatus>? _statusController;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _periodicSyncTimer;

  bool _isInitialized = false;
  bool _isSyncing = false;
  SyncStatus _currentStatus = SyncStatus.idle;

  int _successCount = 0;
  int _failedCount = 0;
  DateTime? _lastSyncTime;

  Stream<SyncStatus> get statusStream =>
      _statusController?.stream ?? const Stream.empty();

  SyncStatus get currentStatus => _currentStatus;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get successCount => _successCount;
  int get failedCount => _failedCount;

  // Configuration
  static const Duration _syncInterval = Duration(minutes: 5);
  static const int _maxRetryAttempts = 3;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _statusController = StreamController<SyncStatus>.broadcast();

      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _handleConnectivityChange,
      );

      // Start periodic sync
      _startPeriodicSync();

      // Initial sync if online
      final connectivityResult = await _connectivity.checkConnectivity();
      if (_isOnline(connectivityResult)) {
        syncAll();
      }

      _isInitialized = true;
      debugPrint('Sync service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing sync service: $e');
    }
  }

  bool _isOnline(List<ConnectivityResult> connectivityResult) {
    return connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.ethernet);
  }

  void _handleConnectivityChange(List<ConnectivityResult> result) {
    debugPrint('Connectivity changed: $result');

    if (_isOnline(result)) {
      debugPrint('Device is online - triggering sync');
      syncAll();
    } else {
      debugPrint('Device is offline');
    }
  }

  void _startPeriodicSync() {
    _periodicSyncTimer?.cancel();

    _periodicSyncTimer = Timer.periodic(_syncInterval, (timer) {
      _checkAndSync();
    });
  }

  Future<void> _checkAndSync() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    if (_isOnline(connectivityResult) && !_isSyncing) {
      await syncAll();
    }
  }

  Future<void> syncAll() async {
    if (_isSyncing) {
      debugPrint('Sync already in progress');
      return;
    }

    _isSyncing = true;
    _updateStatus(SyncStatus.syncing);

    debugPrint('Starting full sync...');

    try {
      // Reset counters
      _successCount = 0;
      _failedCount = 0;

      // Sync pending actions first
      await _syncPendingActions();

      // Sync unsynced data
      await _syncTransactions();
      await _syncOrders();
      await _syncCommissions();
      await _syncVotes();
      await _syncBillPayments();

      _lastSyncTime = DateTime.now();
      _updateStatus(SyncStatus.success);

      debugPrint('Sync completed successfully. Success: $_successCount, Failed: $_failedCount');
    } catch (e) {
      debugPrint('Sync failed: $e');
      _updateStatus(SyncStatus.failed);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncPendingActions() async {
    final pendingActions = await _db.getPendingActions();

    debugPrint('Syncing ${pendingActions.length} pending actions');

    for (final action in pendingActions) {
      try {
        final payload = jsonDecode(action['payload'] as String);
        final success = await _executePendingAction(
          action['action_type'] as String,
          action['entity_type'] as String,
          action['entity_id'] as String,
          payload,
        );

        if (success) {
          await _db.removePendingAction(action['id'] as int);
          _successCount++;
        } else {
          final retryCount = action['retry_count'] as int;
          if (retryCount >= _maxRetryAttempts) {
            debugPrint('Max retries reached for action ${action['id']}, removing');
            await _db.removePendingAction(action['id'] as int);
            _failedCount++;
          } else {
            await _db.incrementRetryCount(action['id'] as int);
          }
        }
      } catch (e) {
        debugPrint('Error syncing pending action ${action['id']}: $e');
        _failedCount++;
      }
    }
  }

  Future<bool> _executePendingAction(
    String actionType,
    String entityType,
    String entityId,
    Map<String, dynamic> payload,
  ) async {
    try {
      debugPrint('Executing pending action: $actionType for $entityType:$entityId');

      // TODO: Replace with actual API calls
      switch (actionType) {
        case 'create':
          // await ApiService().create(entityType, payload);
          break;
        case 'update':
          // await ApiService().update(entityType, entityId, payload);
          break;
        case 'delete':
          // await ApiService().delete(entityType, entityId);
          break;
        default:
          debugPrint('Unknown action type: $actionType');
          return false;
      }

      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      return true;
    } catch (e) {
      debugPrint('Error executing pending action: $e');
      return false;
    }
  }

  Future<void> _syncTransactions() async {
    final unsynced = await _db.getUnsyncedTransactions();

    debugPrint('Syncing ${unsynced.length} transactions');

    for (final transaction in unsynced) {
      try {
        // final data = jsonDecode(transaction['data'] as String);

        // TODO: Replace with actual API call
        // await ApiService().syncTransaction(data);

        // Simulate API call
        await Future.delayed(const Duration(milliseconds: 200));

        await _db.markAsSynced(DatabaseService.transactionsTable, transaction['id'] as String);
        _successCount++;

        debugPrint('Transaction ${transaction['id']} synced successfully');
      } catch (e) {
        debugPrint('Error syncing transaction ${transaction['id']}: $e');
        _failedCount++;
      }
    }
  }

  Future<void> _syncOrders() async {
    final unsynced = await _db.getUnsyncedOrders();

    debugPrint('Syncing ${unsynced.length} orders');

    for (final order in unsynced) {
      try {
        // final data = jsonDecode(order['data'] as String);

        // TODO: Replace with actual API call
        // await ApiService().syncOrder(data);

        // Simulate API call
        await Future.delayed(const Duration(milliseconds: 200));

        await _db.markAsSynced(DatabaseService.ordersTable, order['id'] as String);
        _successCount++;

        debugPrint('Order ${order['id']} synced successfully');
      } catch (e) {
        debugPrint('Error syncing order ${order['id']}: $e');
        _failedCount++;
      }
    }
  }

  Future<void> _syncCommissions() async {
    final unsynced = await _db.query(
      DatabaseService.commissionsTable,
      where: 'synced = ?',
      whereArgs: [0],
    );

    debugPrint('Syncing ${unsynced.length} commissions');

    for (final commission in unsynced) {
      try {
        // final data = jsonDecode(commission['data'] as String);

        // TODO: Replace with actual API call
        // await ApiService().syncCommission(data);

        // Simulate API call
        await Future.delayed(const Duration(milliseconds: 200));

        await _db.markAsSynced(DatabaseService.commissionsTable, commission['id'] as String);
        _successCount++;
      } catch (e) {
        debugPrint('Error syncing commission ${commission['id']}: $e');
        _failedCount++;
      }
    }
  }

  Future<void> _syncVotes() async {
    final unsynced = await _db.query(
      DatabaseService.votesTable,
      where: 'synced = ?',
      whereArgs: [0],
    );

    debugPrint('Syncing ${unsynced.length} votes');

    for (final vote in unsynced) {
      try {
        // TODO: Replace with actual API call
        // await ApiService().syncVote({
        //   'election_id': vote['election_id'],
        //   'option_id': vote['option_id'],
        // });

        // Simulate API call
        await Future.delayed(const Duration(milliseconds: 200));

        await _db.markAsSynced(DatabaseService.votesTable, vote['id'] as String);
        _successCount++;
      } catch (e) {
        debugPrint('Error syncing vote ${vote['id']}: $e');
        _failedCount++;
      }
    }
  }

  Future<void> _syncBillPayments() async {
    final unsynced = await _db.query(
      DatabaseService.billPaymentsTable,
      where: 'synced = ?',
      whereArgs: [0],
    );

    debugPrint('Syncing ${unsynced.length} bill payments');

    for (final payment in unsynced) {
      try {
        // final data = jsonDecode(payment['data'] as String);

        // TODO: Replace with actual API call
        // await ApiService().syncBillPayment(data);

        // Simulate API call
        await Future.delayed(const Duration(milliseconds: 200));

        await _db.markAsSynced(DatabaseService.billPaymentsTable, payment['id'] as String);
        _successCount++;
      } catch (e) {
        debugPrint('Error syncing bill payment ${payment['id']}: $e');
        _failedCount++;
      }
    }
  }

  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    _statusController?.add(status);
  }

  // Public methods

  Future<void> queueAction({
    required String actionType,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
  }) async {
    await _db.addPendingAction(
      actionType: actionType,
      entityType: entityType,
      entityId: entityId,
      payload: payload,
    );

    // Try to sync immediately if online
    final connectivityResult = await _connectivity.checkConnectivity();
    if (_isOnline(connectivityResult)) {
      syncAll();
    }
  }

  Future<Map<String, dynamic>> getSyncStats() async {
    final pendingActions = await _db.getPendingActions();
    final unsyncedTransactions = await _db.getUnsyncedCount(DatabaseService.transactionsTable);
    final unsyncedOrders = await _db.getUnsyncedCount(DatabaseService.ordersTable);
    final unsyncedCommissions = await _db.getUnsyncedCount(DatabaseService.commissionsTable);
    final unsyncedVotes = await _db.getUnsyncedCount(DatabaseService.votesTable);
    final unsyncedBillPayments = await _db.getUnsyncedCount(DatabaseService.billPaymentsTable);

    final totalUnsynced = pendingActions.length +
        unsyncedTransactions +
        unsyncedOrders +
        unsyncedCommissions +
        unsyncedVotes +
        unsyncedBillPayments;

    return {
      'total_unsynced': totalUnsynced,
      'pending_actions': pendingActions.length,
      'unsynced_transactions': unsyncedTransactions,
      'unsynced_orders': unsyncedOrders,
      'unsynced_commissions': unsyncedCommissions,
      'unsynced_votes': unsyncedVotes,
      'unsynced_bill_payments': unsyncedBillPayments,
      'last_sync': _lastSyncTime?.toIso8601String(),
      'is_syncing': _isSyncing,
      'success_count': _successCount,
      'failed_count': _failedCount,
    };
  }

  Future<bool> isOnline() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return _isOnline(connectivityResult);
  }

  Future<void> forceSyncNow() async {
    debugPrint('Force sync requested');
    await syncAll();
  }

  void dispose() {
    _periodicSyncTimer?.cancel();
    _connectivitySubscription?.cancel();
    _statusController?.close();
  }
}
