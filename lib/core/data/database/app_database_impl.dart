import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'app_database.dart';
import 'database_factory.dart'
    if (dart.library.html) 'database_factory_web.dart';

/// SQLite database implementation
class AppDatabaseImpl implements AppDatabase {
  static const String _databaseName = 'ornate_agro.db';
  static const int _databaseVersion = 4;

  Database? _database;

  @override
  Future<void> init() async {
    databaseFactory = getFactory();

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Farmers table
    await db.execute('''
      CREATE TABLE farmers (
        id TEXT PRIMARY KEY,
        full_name TEXT NOT NULL,
        contact_number TEXT NOT NULL,
        village TEXT NOT NULL,
        plot_count INTEGER NOT NULL,
        area_per_plot REAL NOT NULL,
        assigned_crop_type_id TEXT NOT NULL,
        classification TEXT NOT NULL DEFAULT 'regular',
        last_contact_at INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER,
        UNIQUE(full_name, contact_number)
      )
    ''');

    // Farmer indexes
    await db.execute('CREATE INDEX idx_farmers_village ON farmers(village)');
    await db.execute(
        'CREATE INDEX idx_farmers_classification ON farmers(classification)');
    await db.execute(
        'CREATE INDEX idx_farmers_contact_number ON farmers(contact_number)');

    // Distributions table (Req 3)
    await _createDistributionsTable(db);

    // Crop types table (Req 8)
    await _createCropTypesTable(db);

    // Contact logs table (Req 6)
    await _createContactLogsTable(db);
  }

  /// Create the distributions table (shared between onCreate and onUpgrade).
  Future<void> _createDistributionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS distributions (
        id TEXT PRIMARY KEY,
        farmer_id TEXT NOT NULL,
        seed_type TEXT NOT NULL,
        quantity_distributed REAL NOT NULL,
        distribution_date INTEGER NOT NULL,
        expected_yield_due_date INTEGER NOT NULL,
        recorded_by_staff_id TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        quantity_returned REAL NOT NULL DEFAULT 0,
        actual_return_date INTEGER,
        amendment_reason TEXT,
        amended_by_authority_id TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER,
        FOREIGN KEY (farmer_id) REFERENCES farmers(id)
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_distributions_farmer ON distributions(farmer_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_distributions_status ON distributions(status)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_distributions_date ON distributions(distribution_date)');
  }

  /// Create the crop_types table (shared between onCreate and onUpgrade).
  Future<void> _createCropTypesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS crop_types (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        growing_period_days INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  /// Create the contact_logs table (shared between onCreate and onUpgrade).
  Future<void> _createContactLogsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS contact_logs (
        id TEXT PRIMARY KEY,
        farmer_id TEXT NOT NULL,
        contact_date INTEGER NOT NULL,
        contact_method TEXT NOT NULL,
        notes TEXT NOT NULL,
        recorded_by_staff_id TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (farmer_id) REFERENCES farmers(id)
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_contact_logs_farmer ON contact_logs(farmer_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createDistributionsTable(db);
    }
    if (oldVersion < 3) {
      await _createCropTypesTable(db);
    }
    if (oldVersion < 4) {
      await _createContactLogsTable(db);
    }
  }

  Database get database {
    if (_database == null) {
      throw StateError('Database not initialized. Call init() first.');
    }
    return _database!;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
