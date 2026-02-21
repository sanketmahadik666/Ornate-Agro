import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'app_database.dart';
import 'database_factory.dart'
    if (dart.library.html) 'database_factory_web.dart';

/// SQLite database implementation
class AppDatabaseImpl implements AppDatabase {
  static const String _databaseName = 'ornate_agro.db';
  static const int _databaseVersion = 1;

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

    // Create indexes
    await db.execute('CREATE INDEX idx_farmers_village ON farmers(village)');
    await db.execute(
        'CREATE INDEX idx_farmers_classification ON farmers(classification)');
    await db.execute(
        'CREATE INDEX idx_farmers_contact_number ON farmers(contact_number)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    if (oldVersion < 2) {
      // Example: Add new column
      // await db.execute('ALTER TABLE farmers ADD COLUMN new_field TEXT');
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
