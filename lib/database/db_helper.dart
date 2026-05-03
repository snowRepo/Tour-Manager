import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/client_model.dart';
import '../models/trip_model.dart';
import '../models/payment_model.dart';
import '../constants/app_constants.dart';

class DbHelper {
  static final DbHelper _instance = DbHelper._internal();
  factory DbHelper() => _instance;
  DbHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tour_manager.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE clients ADD COLUMN gender TEXT DEFAULT 'Other'");
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        pin_hash TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        other_names TEXT DEFAULT '',
        gender TEXT DEFAULT 'Other',
        phone TEXT DEFAULT '',
        email TEXT DEFAULT '',
        notes TEXT DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE trips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id INTEGER NOT NULL,
        destination TEXT NOT NULL,
        departure_date TEXT NOT NULL,
        return_date TEXT NOT NULL,
        total_cost REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (client_id) REFERENCES clients(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_method TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES trips(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Seed default settings
    final batch = db.batch();
    for (final entry in {
      SettingKeys.businessName: '',
      SettingKeys.businessPhone: '',
      SettingKeys.businessEmail: '',
      SettingKeys.termsAndConditions: AppStrings.defaultTnC,
    }.entries) {
      batch.insert('settings', {'key': entry.key, 'value': entry.value});
    }
    await batch.commit(noResult: true);
  }

  // ── Users ──────────────────────────────────────────────────────────────────

  Future<int> insertUser(UserModel user) async {
    final db = await database;
    return db.insert('users', user.toMap());
  }

  Future<UserModel?> getUser(String username) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first);
  }

  Future<UserModel?> getFirstUser() async {
    final db = await database;
    final rows = await db.query('users', limit: 1);
    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first);
  }

  Future<void> updatePassword(int userId, String newPasswordHash) async {
    final db = await database;
    await db.update(
      'users',
      {'password_hash': newPasswordHash},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> userCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM users');
    return (result.first['cnt'] as int?) ?? 0;
  }

  // ── Clients ────────────────────────────────────────────────────────────────

  Future<int> insertClient(ClientModel client) async {
    final db = await database;
    return db.insert('clients', client.toMap());
  }

  Future<List<ClientModel>> getAllClients() async {
    final db = await database;
    final rows = await db.query('clients', orderBy: 'first_name ASC');
    return rows.map(ClientModel.fromMap).toList();
  }

  Future<ClientModel?> getClientById(int id) async {
    final db = await database;
    final rows = await db.query(
      'clients',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ClientModel.fromMap(rows.first);
  }

  Future<void> updateClient(ClientModel client) async {
    final db = await database;
    await db.update(
      'clients',
      client.toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  Future<void> deleteClient(int id) async {
    final db = await database;
    await db.delete('clients', where: 'id = ?', whereArgs: [id]);
  }

  // ── Trips ──────────────────────────────────────────────────────────────────

  Future<int> insertTrip(TripModel trip) async {
    final db = await database;
    return db.insert('trips', trip.toMap());
  }

  Future<List<TripModel>> getAllTrips() async {
    final db = await database;
    final rows = await db.query('trips', orderBy: 'created_at DESC');
    return rows.map(TripModel.fromMap).toList();
  }

  Future<List<TripModel>> getTripsByClient(int clientId) async {
    final db = await database;
    final rows = await db.query(
      'trips',
      where: 'client_id = ?',
      whereArgs: [clientId],
      orderBy: 'created_at DESC',
    );
    return rows.map(TripModel.fromMap).toList();
  }

  Future<TripModel?> getTripById(int id) async {
    final db = await database;
    final rows = await db.query(
      'trips',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TripModel.fromMap(rows.first);
  }

  Future<void> updateTrip(TripModel trip) async {
    final db = await database;
    await db.update(
      'trips',
      trip.toMap(),
      where: 'id = ?',
      whereArgs: [trip.id],
    );
  }

  Future<void> deleteTrip(int id) async {
    final db = await database;
    await db.delete('trips', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getTripCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM trips');
    return (result.first['cnt'] as int?) ?? 0;
  }

  Future<int> getActiveTripCount() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as cnt FROM trips WHERE status IN ('pending','confirmed')",
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  // ── Payments ───────────────────────────────────────────────────────────────

  Future<int> insertPayment(PaymentModel payment) async {
    final db = await database;
    return db.insert('payments', payment.toMap());
  }

  Future<List<PaymentModel>> getPaymentsByTrip(int tripId) async {
    final db = await database;
    final rows = await db.query(
      'payments',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'created_at ASC',
    );
    return rows.map(PaymentModel.fromMap).toList();
  }

  Future<List<PaymentModel>> getAllPayments() async {
    final db = await database;
    final rows = await db.query('payments', orderBy: 'created_at DESC');
    return rows.map(PaymentModel.fromMap).toList();
  }

  Future<PaymentModel?> getPaymentById(int id) async {
    final db = await database;
    final rows = await db.query(
      'payments',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return PaymentModel.fromMap(rows.first);
  }

  Future<void> deletePayment(int id) async {
    final db = await database;
    await db.delete('payments', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllData() async {
    final db = await database;
    final batch = db.batch();
    batch.delete('payments');
    batch.delete('trips');
    batch.delete('clients');
    batch.delete('settings');
    batch.delete('users');
    await batch.commit(noResult: true);
  }

  Future<double> getTotalRevenue() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM payments WHERE amount > 0',
    );
    return ((result.first['total'] as num?) ?? 0).toDouble();
  }

  // ── Settings ───────────────────────────────────────────────────────────────

  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, String>> getAllSettings() async {
    final db = await database;
    final rows = await db.query('settings');
    return {
      for (final row in rows) row['key'] as String: row['value'] as String,
    };
  }
}
