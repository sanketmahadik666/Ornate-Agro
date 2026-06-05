import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/domain/entities/contact_log_entity.dart';

/// Firestore data source for contact logs.
class ContactLogLocalDataSource {
  ContactLogLocalDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  static const String _collectionName = 'contact_logs';

  ContactLogEntity _mapToEntity(Map<String, dynamic> map) {
    return ContactLogEntity(
      id: map['id'] as String,
      farmerId: map['farmer_id'] as String,
      contactDate:
          DateTime.fromMillisecondsSinceEpoch(map['contact_date'] as int),
      contactMethod: map['contact_method'] as String,
      notes: map['notes'] as String,
      recordedByStaffId: map['recorded_by_staff_id'] as String,
      createdAt: map['created_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : DateTime.now(),
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
    final snapshot = await _firestore
        .collection(_collectionName)
        .where('farmer_id', isEqualTo: farmerId)
        .get();
    final list = snapshot.docs.map((doc) => _mapToEntity(doc.data())).toList();
    list.sort((a, b) => b.contactDate.compareTo(a.contactDate));
    return list;
  }

  /// Insert a new contact log.
  Future<void> insertContactLog(ContactLogEntity entity) async {
    final map = _entityToMap(entity);
    map['created_at'] = DateTime.now().millisecondsSinceEpoch;
    await _firestore.collection(_collectionName).doc(entity.id).set(map);
  }
}
