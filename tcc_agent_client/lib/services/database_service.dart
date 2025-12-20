import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;
  bool _isInitialized = false;

  static const String _databaseName = 'tcc_agent.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String transactionsTable = 'transactions';
  static const String ordersTable = 'orders';
  static const String commissionsTable = 'commissions';
  static const String electionsTable = 'elections';
  static const String votesTable = 'votes';
  static const String billPaymentsTable = 'bill_payments';
  static const String pendingActionsTable = 'pending_actions';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);

    debugPrint('Initializing database at: $path');

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('Creating database tables...');

    // Transactions table
    await db.execute('''
      CREATE TABLE $transactionsTable (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL,
        status TEXT NOT NULL,
        customer_name TEXT,
        customer_phone TEXT,
        description TEXT,
        commission REAL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        data TEXT
      )
    ''');

    // Orders table
    await db.execute('''
      CREATE TABLE $ordersTable (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        status TEXT NOT NULL,
        customer_id TEXT,
        customer_name TEXT,
        customer_phone TEXT,
        verification_code TEXT,
        payment_mode TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        expires_at TEXT,
        synced INTEGER DEFAULT 0,
        data TEXT
      )
    ''');

    // Commissions table
    await db.execute('''
      CREATE TABLE $commissionsTable (
        id TEXT PRIMARY KEY,
        transaction_id TEXT NOT NULL,
        amount REAL NOT NULL,
        percentage REAL NOT NULL,
        type TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        data TEXT
      )
    ''');

    // Elections table
    await db.execute('''
      CREATE TABLE $electionsTable (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        question TEXT NOT NULL,
        voting_charge REAL NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        status TEXT NOT NULL,
        total_votes INTEGER DEFAULT 0,
        total_revenue REAL DEFAULT 0,
        has_voted INTEGER DEFAULT 0,
        user_vote TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        data TEXT
      )
    ''');

    // Votes table
    await db.execute('''
      CREATE TABLE $votesTable (
        id TEXT PRIMARY KEY,
        election_id TEXT NOT NULL,
        option_id TEXT NOT NULL,
        option_label TEXT NOT NULL,
        created_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (election_id) REFERENCES $electionsTable (id)
      )
    ''');

    // Bill payments table
    await db.execute('''
      CREATE TABLE $billPaymentsTable (
        id TEXT PRIMARY KEY,
        bill_type TEXT NOT NULL,
        bill_id TEXT NOT NULL,
        bill_name TEXT NOT NULL,
        amount REAL NOT NULL,
        payment_method TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        data TEXT
      )
    ''');

    // Pending actions table (for offline operations)
    await db.execute('''
      CREATE TABLE $pendingActionsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action_type TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        payload TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        last_retry_at TEXT
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_transactions_created_at ON $transactionsTable(created_at)');
    await db.execute('CREATE INDEX idx_transactions_synced ON $transactionsTable(synced)');
    await db.execute('CREATE INDEX idx_orders_status ON $ordersTable(status)');
    await db.execute('CREATE INDEX idx_orders_synced ON $ordersTable(synced)');
    await db.execute('CREATE INDEX idx_commissions_synced ON $commissionsTable(synced)');
    await db.execute('CREATE INDEX idx_elections_status ON $electionsTable(status)');
    await db.execute('CREATE INDEX idx_pending_actions_created_at ON $pendingActionsTable(created_at)');

    debugPrint('Database tables created successfully');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('Upgrading database from version $oldVersion to $newVersion');

    // Add migration logic here when database schema changes
    if (oldVersion < 2) {
      // Example migration for future versions
      // await db.execute('ALTER TABLE transactions ADD COLUMN new_column TEXT');
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await database;
      _isInitialized = true;
      debugPrint('Database service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing database service: $e');
    }
  }

  // Generic CRUD operations

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(
      table,
      data,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  // Transaction-specific operations

  Future<void> saveTransaction(Map<String, dynamic> transaction) async {
    await insert(transactionsTable, {
      'id': transaction['id'],
      'type': transaction['type'],
      'amount': transaction['amount'],
      'currency': transaction['currency'] ?? 'TCC',
      'status': transaction['status'],
      'customer_name': transaction['customer_name'],
      'customer_phone': transaction['customer_phone'],
      'description': transaction['description'],
      'commission': transaction['commission'],
      'created_at': transaction['created_at'] ?? DateTime.now().toIso8601String(),
      'updated_at': transaction['updated_at'] ?? DateTime.now().toIso8601String(),
      'synced': transaction['synced'] ?? 0,
      'data': jsonEncode(transaction),
    });
  }

  Future<List<Map<String, dynamic>>> getTransactions({
    int? limit,
    int? offset,
    bool? synced,
  }) async {
    return await query(
      transactionsTable,
      where: synced != null ? 'synced = ?' : null,
      whereArgs: synced != null ? [synced ? 1 : 0] : null,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedTransactions() async {
    return await getTransactions(synced: false);
  }

  // Order-specific operations

  Future<void> saveOrder(Map<String, dynamic> order) async {
    await insert(ordersTable, {
      'id': order['id'],
      'type': order['type'],
      'amount': order['amount'],
      'status': order['status'],
      'customer_id': order['customer_id'],
      'customer_name': order['customer_name'],
      'customer_phone': order['customer_phone'],
      'verification_code': order['verification_code'],
      'payment_mode': order['payment_mode'],
      'created_at': order['created_at'] ?? DateTime.now().toIso8601String(),
      'updated_at': order['updated_at'] ?? DateTime.now().toIso8601String(),
      'expires_at': order['expires_at'],
      'synced': order['synced'] ?? 0,
      'data': jsonEncode(order),
    });
  }

  Future<List<Map<String, dynamic>>> getOrders({
    String? status,
    int? limit,
    int? offset,
  }) async {
    return await query(
      ordersTable,
      where: status != null ? 'status = ?' : null,
      whereArgs: status != null ? [status] : null,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedOrders() async {
    return await query(
      ordersTable,
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'created_at DESC',
    );
  }

  // Pending actions for offline queue

  Future<void> addPendingAction({
    required String actionType,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
  }) async {
    await insert(pendingActionsTable, {
      'action_type': actionType,
      'entity_type': entityType,
      'entity_id': entityId,
      'payload': jsonEncode(payload),
      'retry_count': 0,
      'created_at': DateTime.now().toIso8601String(),
    });

    debugPrint('Added pending action: $actionType for $entityType:$entityId');
  }

  Future<List<Map<String, dynamic>>> getPendingActions() async {
    return await query(
      pendingActionsTable,
      orderBy: 'created_at ASC',
    );
  }

  Future<void> removePendingAction(int id) async {
    await delete(
      pendingActionsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> incrementRetryCount(int id) async {
    final actions = await query(
      pendingActionsTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (actions.isNotEmpty) {
      final action = actions.first;
      await update(
        pendingActionsTable,
        {
          'retry_count': (action['retry_count'] as int) + 1,
          'last_retry_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  // Utility methods

  Future<void> markAsSynced(String table, String id) async {
    await update(
      table,
      {'synced': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getUnsyncedCount(String table) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $table WHERE synced = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> clearTable(String table) async {
    final db = await database;
    await db.delete(table);
    debugPrint('Cleared table: $table');
  }

  Future<void> clearAllData() async {
    final db = await database;
    final tables = [
      transactionsTable,
      ordersTable,
      commissionsTable,
      electionsTable,
      votesTable,
      billPaymentsTable,
      pendingActionsTable,
    ];

    for (final table in tables) {
      await db.delete(table);
    }

    debugPrint('Cleared all data from database');
  }

  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;
    final stats = <String, int>{};

    final tables = [
      transactionsTable,
      ordersTable,
      commissionsTable,
      electionsTable,
      votesTable,
      billPaymentsTable,
      pendingActionsTable,
    ];

    for (final table in tables) {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
      stats[table] = Sqflite.firstIntValue(result) ?? 0;
    }

    return stats;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    _isInitialized = false;
    debugPrint('Database closed');
  }
}
