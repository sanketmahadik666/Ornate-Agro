import '../../../../shared/domain/entities/distribution_entity.dart';
import '../../domain/repositories/distribution_repository.dart';
import '../datasources/distribution_local_datasource.dart';

/// Implementation of [DistributionRepository].
class DistributionRepositoryImpl implements DistributionRepository {
  DistributionRepositoryImpl(this._localDataSource);

  final DistributionLocalDataSource _localDataSource;

  @override
  Future<List<DistributionEntity>> getAllDistributions() {
    return _localDataSource.getAllDistributions();
  }

  @override
  Future<DistributionEntity?> getDistributionById(String id) {
    return _localDataSource.getDistributionById(id);
  }

  @override
  Future<List<DistributionEntity>> getDistributionsByFarmer(String farmerId) {
    return _localDataSource.getDistributionsByFarmer(farmerId);
  }

  @override
  Future<DistributionEntity> createDistribution(
      DistributionEntity distribution) async {
    final withTimestamps = distribution.copyWith(
      createdAt: DateTime.now(),
    );
    await _localDataSource.insertDistribution(withTimestamps);
    return withTimestamps;
  }

  @override
  Future<DistributionEntity> amendDistribution({
    required String id,
    required String reason,
    required String authorityId,
    double? quantityDistributed,
    String? seedType,
    DateTime? distributionDate,
  }) async {
    final existing = await _localDataSource.getDistributionById(id);
    if (existing == null) {
      throw DistributionNotFoundException(id);
    }

    if (reason.trim().isEmpty) {
      throw DistributionException('Amendment reason is required');
    }

    final amended = existing.copyWith(
      quantityDistributed: quantityDistributed,
      seedType: seedType,
      distributionDate: distributionDate,
      amendmentReason: reason,
      amendedByAuthorityId: authorityId,
      updatedAt: DateTime.now(),
    );

    await _localDataSource.updateDistribution(amended);
    return amended;
  }

  @override
  Future<DistributionEntity> recordYieldReturn({
    required String id,
    required double quantityReturned,
    required String staffId,
  }) async {
    if (quantityReturned <= 0) {
      throw DistributionException('Quantity returned must be positive');
    }

    final existing = await _localDataSource.getDistributionById(id);
    if (existing == null) {
      throw DistributionNotFoundException(id);
    }

    if (quantityReturned > existing.outstandingQuantity) {
      throw DistributionException(
          'Cannot return $quantityReturned. Outstanding quantity is only ${existing.outstandingQuantity}.');
    }

    final newTotalReturned = existing.quantityReturned + quantityReturned;

    // Status logic: if total returned >= distributed, it's fulfilled.
    // Else if they returned *some*, it's partially fulfilled.
    DistributionStatus newStatus;
    if (newTotalReturned >= existing.quantityDistributed) {
      newStatus = DistributionStatus.fulfilled;
    } else {
      newStatus = DistributionStatus.partiallyFulfilled;
    }

    final updated = existing.copyWith(
      quantityReturned: newTotalReturned,
      status: newStatus,
      actualReturnDate: DateTime.now(),
      updatedAt: DateTime.now(),
      // Assuming recordedByStaffId tracks the *creator*, we might not overwrite it here
      // unless we want to track the returning staff member. For now we just update the entity.
    );

    await _localDataSource.updateDistribution(updated);
    return updated;
  }

  @override
  Future<List<DistributionEntity>> getFilteredDistributions({
    DateTime? startDate,
    DateTime? endDate,
    String? seedType,
    String? farmerId,
    DistributionStatus? status,
  }) {
    return _localDataSource.getFilteredDistributions(
      startDate: startDate,
      endDate: endDate,
      seedType: seedType,
      farmerId: farmerId,
      status: status,
    );
  }
}
