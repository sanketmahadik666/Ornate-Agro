import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/domain/entities/farmer_entity.dart';

/// Firestore data source for farmers
class FarmerLocalDataSource {
  FarmerLocalDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  static const String _collectionName = 'farmers';

  /// Convert map to FarmerEntity
  FarmerEntity _mapToEntity(Map<String, dynamic> map) {
    return FarmerEntity(
      id: map['id'] as String,
      fullName: map['full_name'] as String,
      contactNumber: map['contact_number'] as String,
      village: map['village'] as String,
      plotCount: map['plot_count'] as int,
      areaPerPlot: (map['area_per_plot'] as num).toDouble(),
      assignedCropTypeId: map['assigned_crop_type_id'] as String,
      classification: FarmerClassification.values.firstWhere(
        (c) => c.name == map['classification'] as String,
        orElse: () => FarmerClassification.regular,
      ),
      lastContactAt: map['last_contact_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_contact_at'] as int)
          : null,
      createdAt: map['created_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : DateTime.now(),
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
    final snapshot = await _firestore.collection(_collectionName).get();
    final list = snapshot.docs.map((doc) => _mapToEntity(doc.data())).toList();
    list.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
    return list;
  }

  /// Get farmer by ID
  Future<FarmerEntity?> getFarmerById(String id) async {
    final doc = await _firestore.collection(_collectionName).doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return _mapToEntity(doc.data()!);
  }

  /// Search farmers
  Future<List<FarmerEntity>> searchFarmers(String query) async {
    final all = await getAllFarmers();
    final searchTerm = query.trim().toLowerCase();
    if (searchTerm.isEmpty) return all;

    return all.where((f) {
      return f.fullName.toLowerCase().contains(searchTerm) ||
          f.contactNumber.toLowerCase().contains(searchTerm) ||
          f.village.toLowerCase().contains(searchTerm) ||
          f.id.toLowerCase().contains(searchTerm);
    }).toList();
  }

  /// Insert farmer
  Future<void> insertFarmer(FarmerEntity farmer) async {
    final map = _entityToMap(farmer);
    map['created_at'] = DateTime.now().millisecondsSinceEpoch;
    await _firestore.collection(_collectionName).doc(farmer.id).set(map);
  }

  /// Update farmer
  Future<void> updateFarmer(FarmerEntity farmer) async {
    final map = _entityToMap(farmer);
    map['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    await _firestore.collection(_collectionName).doc(farmer.id).update(map);
  }

  /// Delete farmer
  Future<void> deleteFarmer(String id) async {
    await _firestore.collection(_collectionName).doc(id).delete();
  }

  /// Normalize contact to digits for comparison
  static String _normalizeContact(String contact) {
    return contact.replaceAll(RegExp(r'\D'), '');
  }

  /// Check if farmer exists (by name and contact; contact compared after normalizing to digits)
  Future<bool> farmerExists(String fullName, String contactNumber) async {
    final normalized = _normalizeContact(contactNumber);
    if (normalized.isEmpty) return false;
    final all = await getAllFarmers();
    for (final f in all) {
      final existingContact = _normalizeContact(f.contactNumber);
      if (f.fullName.trim().toLowerCase() == fullName.trim().toLowerCase() &&
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
    final all = await getAllFarmers();
    for (final f in all) {
      if (f.id == excludeId) continue;
      final existingContact = _normalizeContact(f.contactNumber);
      if (f.fullName.trim().toLowerCase() == fullName.trim().toLowerCase() &&
          existingContact == normalized) {
        return true;
      }
    }
    return false;
  }

  /// Get farmers by classification
  Future<List<FarmerEntity>> getFarmersByClassification(FarmerClassification classification) async {
    final snapshot = await _firestore
        .collection(_collectionName)
        .where('classification', isEqualTo: classification.name)
        .get();
    final list = snapshot.docs.map((doc) => _mapToEntity(doc.data())).toList();
    list.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
    return list;
  }

  /// Get farmers by village
  Future<List<FarmerEntity>> getFarmersByVillage(String village) async {
    final snapshot = await _firestore
        .collection(_collectionName)
        .where('village', isEqualTo: village)
        .get();
    final list = snapshot.docs.map((doc) => _mapToEntity(doc.data())).toList();
    list.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
    return list;
  }

  /// Generate next auto-incrementing ID like FMR-001
  Future<String> generateNextFarmerId() async {
    final snapshot = await _firestore.collection(_collectionName).get();
    final ids = snapshot.docs
        .map((doc) => doc.id)
        .where((id) => id.startsWith('FMR-'))
        .toList();
    
    if (ids.isEmpty) {
      return 'FMR-001';
    }

    int maxNumber = 0;
    for (final id in ids) {
      final lastNumberStr = id.substring(4);
      final lastNumber = int.tryParse(lastNumberStr) ?? 0;
      if (lastNumber > maxNumber) {
        maxNumber = lastNumber;
      }
    }
    
    final nextNumber = maxNumber + 1;
    return 'FMR-${nextNumber.toString().padLeft(3, '0')}';
  }
}
