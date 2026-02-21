import 'package:sqflite/sqflite.dart';
import '../../../../shared/domain/entities/farmer_entity.dart';
import '../../../../core/data/database/app_database_impl.dart';

/// Local data source for farmers (SQLite)
class FarmerLocalDataSource {
  FarmerLocalDataSource(this._database);

  final AppDatabaseImpl _database;

  static const String _tableName = 'farmers';

  /// Convert map to FarmerEntity
  FarmerEntity _mapToEntity(Map<String, dynamic> map) {
    return FarmerEntity(
      id: map['id'] as String,
      fullName: map['full_name'] as String,
      contactNumber: map['contact_number'] as String,
      village: map['village'] as String,
      plotCount: map['plot_count'] as int,
      areaPerPlot: map['area_per_plot'] as double,
      assignedCropTypeId: map['assigned_crop_type_id'] as String,
      classification: FarmerClassification.values.firstWhere(
        (c) => c.name == map['classification'] as String,
      ),
      lastContactAt: map['last_contact_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_contact_at'] as int)
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int)
          : null,
    );
  }

  /// Convert FarmerEntity to map
  Map<String, dynamic> _entityToMap(FarmerEntity farmer) {
    return {
      'id': farmer.id,
      'full_name': farmer.fullName,
      'contact_number': farmer.contactNumber,
      'village': farmer.village,
      'plot_count': farmer.plotCount,
      'area_per_plot': farmer.areaPerPlot,
      'assigned_crop_type_id': farmer.assignedCropTypeId,
      'classification': farmer.classification.name,
      'last_contact_at': farmer.lastContactAt?.millisecondsSinceEpoch,
      'created_at': farmer.createdAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
      'updated_at': farmer.updatedAt?.millisecondsSinceEpoch,
    };
  }

  /// Get all farmers
  Future<List<FarmerEntity>> getAllFarmers() async {
    final db = _database.database;
    final maps = await db.query(_tableName, orderBy: 'full_name ASC');
    return maps.map((map) => _mapToEntity(map)).toList();
  }

  /// Get farmer by ID
  Future<FarmerEntity?> getFarmerById(String id) async {
    final db = _database.database;
    final maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return _mapToEntity(maps.first);
  }

  /// Search farmers
  Future<List<FarmerEntity>> searchFarmers(String query) async {
    final db = _database.database;
    final searchTerm = '%$query%';
    final maps = await db.query(
      _tableName,
      where: 'full_name LIKE ? OR contact_number LIKE ? OR village LIKE ? OR id LIKE ?',
      whereArgs: [searchTerm, searchTerm, searchTerm, searchTerm],
      orderBy: 'full_name ASC',
    );
    return maps.map((map) => _mapToEntity(map)).toList();
  }

  /// Insert farmer
  Future<void> insertFarmer(FarmerEntity farmer) async {
    final db = _database.database;
    final map = _entityToMap(farmer);
    map['created_at'] = DateTime.now().millisecondsSinceEpoch;
    await db.insert(_tableName, map, conflictAlgorithm: ConflictAlgorithm.fail);
  }

  /// Update farmer
  Future<void> updateFarmer(FarmerEntity farmer) async {
    final db = _database.database;
    final map = _entityToMap(farmer);
    map['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      _tableName,
      map,
      where: 'id = ?',
      whereArgs: [farmer.id],
    );
  }

  /// Delete farmer
  Future<void> deleteFarmer(String id) async {
    final db = _database.database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Normalize contact to digits for comparison
  static String _normalizeContact(String contact) {
    return contact.replaceAll(RegExp(r'\D'), '');
  }

  /// Check if farmer exists (by name and contact; contact compared after normalizing to digits)
  Future<bool> farmerExists(String fullName, String contactNumber) async {
    final normalized = _normalizeContact(contactNumber);
    if (normalized.isEmpty) return false;
    final db = _database.database;
    final maps = await db.query(_tableName);
    for (final map in maps) {
      final existingContact = _normalizeContact(map['contact_number'] as String);
      if ((map['full_name'] as String).trim().toLowerCase() == fullName.trim().toLowerCase() &&
          existingContact == normalized) {
        return true;
      }
    }
    return false;
  }

  /// Check if another farmer (excluding [excludeId]) exists with same name and contact
  Future<bool> farmerExistsExcludingId(String fullName, String contactNumber, String excludeId) async {
    final normalized = _normalizeContact(contactNumber);
    if (normalized.isEmpty) return false;
    final db = _database.database;
    final maps = await db.query(_tableName, where: 'id != ?', whereArgs: [excludeId]);
    for (final map in maps) {
      final existingContact = _normalizeContact(map['contact_number'] as String);
      if ((map['full_name'] as String).trim().toLowerCase() == fullName.trim().toLowerCase() &&
          existingContact == normalized) {
        return true;
      }
    }
    return false;
  }

  /// Get farmers by classification
  Future<List<FarmerEntity>> getFarmersByClassification(FarmerClassification classification) async {
    final db = _database.database;
    final maps = await db.query(
      _tableName,
      where: 'classification = ?',
      whereArgs: [classification.name],
      orderBy: 'full_name ASC',
    );
    return maps.map((map) => _mapToEntity(map)).toList();
  }

  /// Get farmers by village
  Future<List<FarmerEntity>> getFarmersByVillage(String village) async {
    final db = _database.database;
    final maps = await db.query(
      _tableName,
      where: 'village = ?',
      whereArgs: [village],
      orderBy: 'full_name ASC',
    );
    return maps.map((map) => _mapToEntity(map)).toList();
  }
}
