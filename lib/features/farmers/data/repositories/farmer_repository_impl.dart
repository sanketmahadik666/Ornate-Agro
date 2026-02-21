import '../../../../shared/domain/entities/farmer_entity.dart';
import '../../domain/repositories/farmer_repository.dart';
import '../datasources/farmer_local_datasource.dart';

/// Implementation of FarmerRepository
class FarmerRepositoryImpl implements FarmerRepository {
  FarmerRepositoryImpl(this._localDataSource);

  final FarmerLocalDataSource _localDataSource;

  @override
  Future<List<FarmerEntity>> getAllFarmers() async {
    return _localDataSource.getAllFarmers();
  }

  @override
  Future<FarmerEntity?> getFarmerById(String id) async {
    return _localDataSource.getFarmerById(id);
  }

  @override
  Future<List<FarmerEntity>> searchFarmers(String query) async {
    if (query.trim().isEmpty) {
      return getAllFarmers();
    }
    return _localDataSource.searchFarmers(query.trim());
  }

  @override
  Future<FarmerEntity> createFarmer(FarmerEntity farmer) async {
    // Check for duplicates
    final exists = await _localDataSource.farmerExists(
      farmer.fullName,
      farmer.contactNumber,
    );
    if (exists) {
      throw DuplicateFarmerException();
    }

    // Set timestamps
    final farmerWithTimestamps = FarmerEntity(
      id: farmer.id,
      fullName: farmer.fullName,
      contactNumber: farmer.contactNumber,
      village: farmer.village,
      plotCount: farmer.plotCount,
      areaPerPlot: farmer.areaPerPlot,
      assignedCropTypeId: farmer.assignedCropTypeId,
      classification: farmer.classification,
      lastContactAt: farmer.lastContactAt,
      createdAt: DateTime.now(),
      updatedAt: null,
    );

    await _localDataSource.insertFarmer(farmerWithTimestamps);
    return farmerWithTimestamps;
  }

  @override
  Future<FarmerEntity> updateFarmer(FarmerEntity farmer) async {
    // Check if farmer exists
    final existing = await _localDataSource.getFarmerById(farmer.id);
    if (existing == null) {
      throw FarmerNotFoundException(farmer.id);
    }

    // Check for duplicates (excluding current farmer)
    final exists = await _localDataSource.farmerExists(
      farmer.fullName,
      farmer.contactNumber,
    );
    if (exists && existing.id != farmer.id) {
      throw DuplicateFarmerException();
    }

    // Update with timestamp
    final updatedFarmer = FarmerEntity(
      id: farmer.id,
      fullName: farmer.fullName,
      contactNumber: farmer.contactNumber,
      village: farmer.village,
      plotCount: farmer.plotCount,
      areaPerPlot: farmer.areaPerPlot,
      assignedCropTypeId: farmer.assignedCropTypeId,
      classification: farmer.classification,
      lastContactAt: farmer.lastContactAt,
      createdAt: existing.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _localDataSource.updateFarmer(updatedFarmer);
    return updatedFarmer;
  }

  @override
  Future<void> deleteFarmer(String id) async {
    final exists = await _localDataSource.getFarmerById(id);
    if (exists == null) {
      throw FarmerNotFoundException(id);
    }
    await _localDataSource.deleteFarmer(id);
  }

  @override
  Future<bool> farmerExists(String fullName, String contactNumber) async {
    return _localDataSource.farmerExists(fullName, contactNumber);
  }

  @override
  Future<List<FarmerEntity>> getFarmersByClassification(FarmerClassification classification) async {
    return _localDataSource.getFarmersByClassification(classification);
  }

  @override
  Future<List<FarmerEntity>> getFarmersByVillage(String village) async {
    return _localDataSource.getFarmersByVillage(village);
  }
}
