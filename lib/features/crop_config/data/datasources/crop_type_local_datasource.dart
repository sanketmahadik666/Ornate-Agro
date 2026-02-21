import 'package:sqflite/sqflite.dart';
import '../../../../shared/domain/entities/crop_type_entity.dart';
import '../../../../core/data/database/app_database_impl.dart';

/// Local data source for crop types (SQLite).
class CropTypeLocalDataSource {
  CropTypeLocalDataSource(this._database);

  final AppDatabaseImpl _database;

  static const String _tableName = 'crop_types';

  CropTypeEntity _mapToEntity(Map<String, dynamic> map) {
    return CropTypeEntity(
      id: map['id'] as String,
      name: map['name'] as String,
      growingPeriodDays: map['growing_period_days'] as int,
    );
  }

  Map<String, dynamic> _entityToMap(CropTypeEntity entity) {
    return {
      'id': entity.id,
      'name': entity.name,
      'growing_period_days': entity.growingPeriodDays,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };
  }

  Future<List<CropTypeEntity>> getAllCropTypes() async {
    final db = _database.database;
    final maps = await db.query(_tableName, orderBy: 'name ASC');
    return maps.map(_mapToEntity).toList();
  }

  Future<CropTypeEntity?> getCropTypeById(String id) async {
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

  Future<CropTypeEntity?> getCropTypeByName(String name) async {
    final db = _database.database;
    final maps = await db.query(
      _tableName,
      where: 'LOWER(name) = ?',
      whereArgs: [name.toLowerCase().trim()],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return _mapToEntity(maps.first);
  }

  Future<void> insertCropType(CropTypeEntity entity) async {
    final db = _database.database;
    await db.insert(_tableName, _entityToMap(entity),
        conflictAlgorithm: ConflictAlgorithm.fail);
  }

  Future<void> updateCropType(CropTypeEntity entity) async {
    final db = _database.database;
    await db.update(
      _tableName,
      {'name': entity.name, 'growing_period_days': entity.growingPeriodDays},
      where: 'id = ?',
      whereArgs: [entity.id],
    );
  }

  Future<void> deleteCropType(String id) async {
    final db = _database.database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  /// Check if any distribution references this crop type by seed_type matching name.
  Future<bool> isCropTypeInUse(String cropTypeName) async {
    final db = _database.database;
    final result = await db.query(
      'distributions',
      where: 'LOWER(seed_type) = ?',
      whereArgs: [cropTypeName.toLowerCase()],
      limit: 1,
    );
    return result.isNotEmpty;
  }
}
