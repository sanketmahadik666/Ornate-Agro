import 'package:sqflite/sqflite.dart';
import '../../../../shared/domain/entities/contact_log_entity.dart';
import '../../../../core/data/database/app_database_impl.dart';

/// Local data source for contact logs.
class ContactLogLocalDataSource {
  ContactLogLocalDataSource(this._database);

  final AppDatabaseImpl _database;

  static const String _tableName = 'contact_logs';

  ContactLogEntity _mapToEntity(Map<String, dynamic> map) {
    return ContactLogEntity(
      id: map['id'] as String,
      farmerId: map['farmer_id'] as String,
      contactDate:
          DateTime.fromMillisecondsSinceEpoch(map['contact_date'] as int),
      contactMethod: map['contact_method'] as String,
      notes: map['notes'] as String,
      recordedByStaffId: map['recorded_by_staff_id'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  Map<String, dynamic> _entityToMap(ContactLogEntity entity) {
    return {
      'id': entity.id,
      'farmer_id': entity.farmerId,
      'contact_date': entity.contactDate.millisecondsSinceEpoch,
      'contact_method': entity.contactMethod,
      'notes': entity.notes,
      'recorded_by_staff_id': entity.recordedByStaffId,
      'created_at': entity.createdAt?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Get all contact logs for a specific farmer.
  Future<List<ContactLogEntity>> getContactLogsByFarmerId(
      String farmerId) async {
    final db = _database.database;
    final maps = await db.query(
      _tableName,
      where: 'farmer_id = ?',
      whereArgs: [farmerId],
      orderBy: 'contact_date DESC',
    );
    return maps.map(_mapToEntity).toList();
  }

  /// Insert a new contact log.
  Future<void> insertContactLog(ContactLogEntity entity) async {
    final db = _database.database;
    final map = _entityToMap(entity);
    map['created_at'] = DateTime.now().millisecondsSinceEpoch;
    await db.insert(_tableName, map, conflictAlgorithm: ConflictAlgorithm.fail);
  }
}
