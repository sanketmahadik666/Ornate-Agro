import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/domain/entities/crop_type_entity.dart';

/// Firestore data source for crop types.
class CropTypeLocalDataSource {
  CropTypeLocalDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  static const String _collectionName = 'crop_types';

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
    final snapshot = await _firestore.collection(_collectionName).get();
    final list = snapshot.docs.map((doc) => _mapToEntity(doc.data())).toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  Future<CropTypeEntity?> getCropTypeById(String id) async {
    final doc = await _firestore.collection(_collectionName).doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return _mapToEntity(doc.data()!);
  }

  Future<CropTypeEntity?> getCropTypeByName(String name) async {
    final all = await getAllCropTypes();
    final target = name.toLowerCase().trim();
    for (final c in all) {
      if (c.name.toLowerCase().trim() == target) {
        return c;
      }
    }
    return null;
  }

  Future<void> insertCropType(CropTypeEntity entity) async {
    await _firestore.collection(_collectionName).doc(entity.id).set(_entityToMap(entity));
  }

  Future<void> updateCropType(CropTypeEntity entity) async {
    await _firestore.collection(_collectionName).doc(entity.id).update({
      'name': entity.name,
      'growing_period_days': entity.growingPeriodDays,
    });
  }

  Future<void> deleteCropType(String id) async {
    await _firestore.collection(_collectionName).doc(id).delete();
  }

  /// Check if any distribution references this crop type by seed_type matching name.
  Future<bool> isCropTypeInUse(String cropTypeName) async {
    final target = cropTypeName.toLowerCase().trim();
    
    // Check using exact check in Firestore
    final snapshot = await _firestore
        .collection('distributions')
        .where('seed_type', isEqualTo: cropTypeName)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) return true;

    // Check with client-side case-insensitive mapping
    final allDistsSnapshot = await _firestore.collection('distributions').get();
    for (final doc in allDistsSnapshot.docs) {
      final seedType = (doc.data()['seed_type'] as String?)?.toLowerCase().trim();
      if (seedType == target) {
        return true;
      }
    }
    return false;
  }
}
