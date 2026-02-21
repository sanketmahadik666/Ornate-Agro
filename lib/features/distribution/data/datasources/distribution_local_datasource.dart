import 'package:sqflite/sqflite.dart';
import '../../../../shared/domain/entities/distribution_entity.dart';
import '../../../../core/data/database/app_database_impl.dart';

/// Local data source for distributions (SQLite).
class DistributionLocalDataSource {
  DistributionLocalDataSource(this._database);

  final AppDatabaseImpl _database;

  static const String _tableName = 'distributions';

  /// Convert a DB map row to [DistributionEntity].
  DistributionEntity _mapToEntity(Map<String, dynamic> map) {
    return DistributionEntity(
      id: map['id'] as String,
      farmerId: map['farmer_id'] as String,
      seedType: map['seed_type'] as String,
      quantityDistributed: (map['quantity_distributed'] as num).toDouble(),
      distributionDate:
          DateTime.fromMillisecondsSinceEpoch(map['distribution_date'] as int),
      expectedYieldDueDate: DateTime.fromMillisecondsSinceEpoch(
          map['expected_yield_due_date'] as int),
      recordedByStaffId: map['recorded_by_staff_id'] as String,
      status: DistributionStatus.values.firstWhere(
        (s) => s.name == map['status'] as String,
        orElse: () => DistributionStatus.pending,
      ),
      quantityReturned: (map['quantity_returned'] as num?)?.toDouble() ?? 0,
      actualReturnDate: map['actual_return_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map['actual_return_date'] as int)
          : null,
      amendmentReason: map['amendment_reason'] as String?,
      amendedByAuthorityId: map['amended_by_authority_id'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int)
          : null,
    );
  }

  /// Convert a [DistributionEntity] to a DB map.
  Map<String, dynamic> _entityToMap(DistributionEntity entity) {
    return {
      'id': entity.id,
      'farmer_id': entity.farmerId,
      'seed_type': entity.seedType,
      'quantity_distributed': entity.quantityDistributed,
      'distribution_date': entity.distributionDate.millisecondsSinceEpoch,
      'expected_yield_due_date':
          entity.expectedYieldDueDate.millisecondsSinceEpoch,
      'recorded_by_staff_id': entity.recordedByStaffId,
      'status': entity.status.name,
      'quantity_returned': entity.quantityReturned,
      'actual_return_date': entity.actualReturnDate?.millisecondsSinceEpoch,
      'amendment_reason': entity.amendmentReason,
      'amended_by_authority_id': entity.amendedByAuthorityId,
      'created_at': entity.createdAt?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch,
      'updated_at': entity.updatedAt?.millisecondsSinceEpoch,
    };
  }

  /// Get all distributions ordered by date descending.
  Future<List<DistributionEntity>> getAllDistributions() async {
    final db = _database.database;
    final maps = await db.query(_tableName, orderBy: 'distribution_date DESC');
    return maps.map(_mapToEntity).toList();
  }

  /// Get a distribution by ID.
  Future<DistributionEntity?> getDistributionById(String id) async {
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

  /// Get all distributions for a specific farmer.
  Future<List<DistributionEntity>> getDistributionsByFarmer(
      String farmerId) async {
    final db = _database.database;
    final maps = await db.query(
      _tableName,
      where: 'farmer_id = ?',
      whereArgs: [farmerId],
      orderBy: 'distribution_date DESC',
    );
    return maps.map(_mapToEntity).toList();
  }

  /// Insert a new distribution record.
  Future<void> insertDistribution(DistributionEntity entity) async {
    final db = _database.database;
    final map = _entityToMap(entity);
    map['created_at'] = DateTime.now().millisecondsSinceEpoch;
    await db.insert(_tableName, map, conflictAlgorithm: ConflictAlgorithm.fail);
  }

  /// Update an existing distribution (amendment only, no delete).
  Future<void> updateDistribution(DistributionEntity entity) async {
    final db = _database.database;
    final map = _entityToMap(entity);
    map['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      _tableName,
      map,
      where: 'id = ?',
      whereArgs: [entity.id],
    );
  }

  /// Get distributions matching filters.
  Future<List<DistributionEntity>> getFilteredDistributions({
    DateTime? startDate,
    DateTime? endDate,
    String? seedType,
    String? farmerId,
    DistributionStatus? status,
  }) async {
    final db = _database.database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (startDate != null) {
      whereClauses.add('distribution_date >= ?');
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }
    if (endDate != null) {
      whereClauses.add('distribution_date <= ?');
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }
    if (seedType != null && seedType.isNotEmpty) {
      whereClauses.add('seed_type = ?');
      whereArgs.add(seedType);
    }
    if (farmerId != null && farmerId.isNotEmpty) {
      whereClauses.add('farmer_id = ?');
      whereArgs.add(farmerId);
    }
    if (status != null) {
      whereClauses.add('status = ?');
      whereArgs.add(status.name);
    }

    final maps = await db.query(
      _tableName,
      where: whereClauses.isEmpty ? null : whereClauses.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'distribution_date DESC',
    );
    return maps.map(_mapToEntity).toList();
  }
}
