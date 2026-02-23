import '../../../../shared/domain/entities/distribution_entity.dart';

/// Abstract repository for distribution operations (Req 3).
abstract class DistributionRepository {
  /// Get all distributions.
  Future<List<DistributionEntity>> getAllDistributions();

  /// Get a single distribution by ID.
  Future<DistributionEntity?> getDistributionById(String id);

  /// Get all distributions for a specific farmer.
  Future<List<DistributionEntity>> getDistributionsByFarmer(String farmerId);

  /// Record a new distribution (no deletion allowed per Req 3).
  Future<DistributionEntity> createDistribution(
      DistributionEntity distribution);

  /// Amend an existing distribution entry (requires reason + authority).
  Future<DistributionEntity> amendDistribution({
    required String id,
    required String reason,
    required String authorityId,
    double? quantityDistributed,
    String? seedType,
    DateTime? distributionDate,
  });

  /// Record a yield return for this distribution.
  Future<DistributionEntity> recordYieldReturn({
    required String id,
    required double quantityReturned,
    required String staffId,
  });

  /// Force-fulfill a distribution (authority override — Clinchit).
  /// Sets status to fulfilled regardless of outstanding quantity.
  Future<DistributionEntity> forceFullfill({
    required String id,
    required String authorityId,
  });

  /// Get distributions matching the given filters.
  Future<List<DistributionEntity>> getFilteredDistributions({
    DateTime? startDate,
    DateTime? endDate,
    String? seedType,
    String? farmerId,
    DistributionStatus? status,
  });
}

/// Distribution-specific exceptions.
class DistributionException implements Exception {
  DistributionException(this.message);
  final String message;
  @override
  String toString() => 'DistributionException: $message';
}

class DistributionNotFoundException extends DistributionException {
  DistributionNotFoundException(String id)
      : super('Distribution with ID $id not found');
}
