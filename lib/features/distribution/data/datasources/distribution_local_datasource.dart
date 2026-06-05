import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/domain/entities/distribution_entity.dart';

/// Firestore data source for distributions.
class DistributionLocalDataSource {
  DistributionLocalDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  static const String _collectionName = 'distributions';

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
      createdAt: map['created_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : DateTime.now(),
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
    final snapshot = await _firestore.collection(_collectionName).get();
    final list = snapshot.docs.map((doc) => _mapToEntity(doc.data())).toList();
    list.sort((a, b) => b.distributionDate.compareTo(a.distributionDate));
    return list;
  }

  /// Get a distribution by ID.
  Future<DistributionEntity?> getDistributionById(String id) async {
    final doc = await _firestore.collection(_collectionName).doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return _mapToEntity(doc.data()!);
  }

  /// Get all distributions for a specific farmer.
  Future<List<DistributionEntity>> getDistributionsByFarmer(
      String farmerId) async {
    final snapshot = await _firestore
        .collection(_collectionName)
        .where('farmer_id', isEqualTo: farmerId)
        .get();
    final list = snapshot.docs.map((doc) => _mapToEntity(doc.data())).toList();
    list.sort((a, b) => b.distributionDate.compareTo(a.distributionDate));
    return list;
  }

  /// Insert a new distribution record.
  Future<void> insertDistribution(DistributionEntity entity) async {
    final map = _entityToMap(entity);
    map['created_at'] = DateTime.now().millisecondsSinceEpoch;
    await _firestore.collection(_collectionName).doc(entity.id).set(map);
  }

  /// Update an existing distribution (amendment only, no delete).
  Future<void> updateDistribution(DistributionEntity entity) async {
    final map = _entityToMap(entity);
    map['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    await _firestore.collection(_collectionName).doc(entity.id).update(map);
  }

  /// Get distributions matching filters.
  Future<List<DistributionEntity>> getFilteredDistributions({
    DateTime? startDate,
    DateTime? endDate,
    String? seedType,
    String? farmerId,
    DistributionStatus? status,
  }) async {
    final all = await getAllDistributions();

    return all.where((d) {
      if (startDate != null && d.distributionDate.isBefore(startDate)) {
        return false;
      }
      if (endDate != null && d.distributionDate.isAfter(endDate)) {
        return false;
      }
      if (seedType != null && seedType.isNotEmpty && d.seedType != seedType) {
        return false;
      }
      if (farmerId != null && farmerId.isNotEmpty && d.farmerId != farmerId) {
        return false;
      }
      if (status != null && d.status != status) {
        return false;
      }
      return true;
    }).toList();
  }
}
