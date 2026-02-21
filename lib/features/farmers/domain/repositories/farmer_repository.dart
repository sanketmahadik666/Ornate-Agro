import '../../../../shared/domain/entities/farmer_entity.dart';

/// Repository interface for farmer operations
abstract class FarmerRepository {
  /// Get all farmers
  Future<List<FarmerEntity>> getAllFarmers();

  /// Get farmer by ID
  Future<FarmerEntity?> getFarmerById(String id);

  /// Search farmers by query (name, contact, village, ID)
  Future<List<FarmerEntity>> searchFarmers(String query);

  /// Create new farmer
  Future<FarmerEntity> createFarmer(FarmerEntity farmer);

  /// Update existing farmer
  Future<FarmerEntity> updateFarmer(FarmerEntity farmer);

  /// Delete farmer
  Future<void> deleteFarmer(String id);

  /// Check if farmer exists (by name and contact)
  Future<bool> farmerExists(String fullName, String contactNumber);

  /// Get farmers by classification
  Future<List<FarmerEntity>> getFarmersByClassification(FarmerClassification classification);

  /// Get farmers by village
  Future<List<FarmerEntity>> getFarmersByVillage(String village);
}

/// Farmer repository exceptions
class FarmerException implements Exception {
  FarmerException(this.message);
  final String message;
  @override
  String toString() => 'FarmerException: $message';
}

class FarmerNotFoundException extends FarmerException {
  FarmerNotFoundException(String id) : super('Farmer with ID $id not found');
}

class DuplicateFarmerException extends FarmerException {
  DuplicateFarmerException() : super('Farmer with same name and contact already exists');
}
