import '../../shared/domain/entities/farmer_entity.dart';
import '../../shared/domain/entities/distribution_entity.dart';
import '../../features/distribution/data/datasources/distribution_local_datasource.dart';
import '../../features/farmers/data/datasources/farmer_local_datasource.dart';
import '../constants/app_constants.dart';

/// Req 5: Automatic farmer classification engine.
///
/// Evaluates a farmer's distributions and contact history to compute
/// the correct [FarmerClassification].
///
/// Classification rules (all based on plots whose growing period has elapsed):
/// - **Regular**: all yield returned
/// - **Sleepy**: all yield returned, but no contact for 20-30 days after plots done
/// - **Reminder**: yield NOT returned, but farmer is in contact
/// - **Blacklist**: yield NOT returned AND no contact for 20-30 days (authority override only)
class ClassificationService {
  ClassificationService({
    required this.distributionDataSource,
    required this.farmerDataSource,
  });

  final DistributionLocalDataSource distributionDataSource;
  final FarmerLocalDataSource farmerDataSource;

  /// Compute and apply classification for a single farmer.
  /// Returns the new classification.
  Future<FarmerClassification> classifyFarmer(FarmerEntity farmer) async {
    final distributions =
        await distributionDataSource.getDistributionsByFarmer(farmer.id);

    // No distributions → Regular (nothing to evaluate)
    if (distributions.isEmpty) {
      return FarmerClassification.regular;
    }

    final now = DateTime.now();

    // Check if ALL distributions' growing periods have elapsed
    final allPlotsComplete = distributions.every(
      (d) => now.isAfter(d.expectedYieldDueDate),
    );

    if (!allPlotsComplete) {
      // Still within growing period — stay Regular
      return FarmerClassification.regular;
    }

    // Check yield return status
    final allYieldReturned = distributions.every(
      (d) => d.status == DistributionStatus.fulfilled,
    );

    final hasAnyYieldReturn = distributions.any(
      (d) =>
          d.status == DistributionStatus.fulfilled ||
          d.status == DistributionStatus.partiallyFulfilled,
    );

    // Check contact status
    final bool isInContact = _isInContact(farmer, now);

    if (allYieldReturned) {
      // Yield fully returned
      if (isInContact) {
        return FarmerClassification.regular;
      } else {
        return FarmerClassification.sleepy;
      }
    } else {
      // Yield NOT fully returned
      if (isInContact) {
        return FarmerClassification.reminder;
      } else {
        // Note: we classify as reminder here, NOT blacklist.
        // Blacklist requires explicit authority action.
        // But if they have zero yield AND no contact, mark as reminder
        // so authority can review and decide.
        return FarmerClassification.reminder;
      }
    }
  }

  /// Check if farmer has had contact within the escalation window.
  bool _isInContact(FarmerEntity farmer, DateTime now) {
    if (farmer.lastContactAt == null) return false;
    final daysSinceContact = now.difference(farmer.lastContactAt!).inDays;
    return daysSinceContact <= AppConstants.contactEscalationDays;
  }

  /// Evaluate and update classification for a single farmer.
  /// Returns true if classification changed.
  Future<bool> evaluateAndUpdate(FarmerEntity farmer) async {
    final newClassification = await classifyFarmer(farmer);

    if (newClassification != farmer.classification) {
      final updated = FarmerEntity(
        id: farmer.id,
        fullName: farmer.fullName,
        contactNumber: farmer.contactNumber,
        village: farmer.village,
        plotCount: farmer.plotCount,
        areaPerPlot: farmer.areaPerPlot,
        assignedCropTypeId: farmer.assignedCropTypeId,
        classification: newClassification,
        lastContactAt: farmer.lastContactAt,
        createdAt: farmer.createdAt,
        updatedAt: DateTime.now(),
      );
      await farmerDataSource.updateFarmer(updated);
      return true;
    }
    return false;
  }

  /// Evaluate and update classification for ALL farmers.
  /// Returns count of farmers whose classification changed.
  Future<int> evaluateAllFarmers() async {
    final farmers = await farmerDataSource.getAllFarmers();
    int changedCount = 0;
    for (final farmer in farmers) {
      final changed = await evaluateAndUpdate(farmer);
      if (changed) changedCount++;
    }
    return changedCount;
  }
}
