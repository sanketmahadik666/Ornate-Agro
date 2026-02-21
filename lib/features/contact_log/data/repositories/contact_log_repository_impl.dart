import '../../../../shared/domain/entities/contact_log_entity.dart';
import '../../../../features/farmers/domain/repositories/farmer_repository.dart';
import '../../../../core/services/classification_service.dart';
import '../../domain/repositories/contact_log_repository.dart';
import '../datasources/contact_log_local_datasource.dart';

/// Implementation of [ContactLogRepository].
class ContactLogRepositoryImpl implements ContactLogRepository {
  ContactLogRepositoryImpl(
    this._localDataSource,
    this._farmerRepository,
    this._classificationService,
  );

  final ContactLogLocalDataSource _localDataSource;
  final FarmerRepository _farmerRepository;
  final ClassificationService _classificationService;

  @override
  Future<List<ContactLogEntity>> getContactLogsByFarmerId(String farmerId) {
    return _localDataSource.getContactLogsByFarmerId(farmerId);
  }

  @override
  Future<ContactLogEntity> createContactLog(ContactLogEntity log) async {
    if (log.notes.trim().isEmpty) {
      throw ContactLogException('Notes cannot be empty');
    }

    final withTimestamp = log.copyWith(createdAt: DateTime.now());
    await _localDataSource.insertContactLog(withTimestamp);

    // Update farmer's lastContactAt and run classification
    final farmer = await _farmerRepository.getFarmerById(log.farmerId);
    if (farmer != null) {
      // Create updated farmer with new last contact date
      final updatedFarmer = farmer.copyWith(
        lastContactAt: log.contactDate,
        updatedAt: DateTime.now(),
      );

      // We must first update the DB so the classification service sees it
      await _farmerRepository.updateFarmer(updatedFarmer);

      // Then re-evaluate the farmer's classification (Req 5)
      await _classificationService.evaluateAndUpdate(updatedFarmer);
    }

    return withTimestamp;
  }
}
