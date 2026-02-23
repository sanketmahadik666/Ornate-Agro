import '../../shared/domain/entities/farmer_entity.dart';
import '../../shared/domain/entities/distribution_entity.dart';
import '../../features/distribution/data/datasources/distribution_local_datasource.dart';
import '../../features/farmers/data/datasources/farmer_local_datasource.dart';
import '../constants/app_constants.dart';
import 'demo_clock.dart';

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
    this.demoClock,
  });

  final DistributionLocalDataSource distributionDataSource;
  final FarmerLocalDataSource farmerDataSource;
  DemoClock? demoClock;

  /// Compute and apply classification for a single farmer.
  /// Returns the new classification.
  Future<FarmerClassification> classifyFarmer(FarmerEntity farmer) async {
    // Blacklisted farmers stay blacklisted (only authority can change).
    if (farmer.classification == FarmerClassification.blacklist) {
      return FarmerClassification.blacklist;
    }

    final distributions =
        await distributionDataSource.getDistributionsByFarmer(farmer.id);

    // No distributions → Regular (nothing to evaluate)
    if (distributions.isEmpty) {
      return FarmerClassification.regular;
    }

    final now = demoClock?.now() ?? DateTime.now();

    // Auto-update distribution statuses based on time
    for (final d in distributions) {
      if (d.status != DistributionStatus.fulfilled &&
          now.isAfter(d.expectedYieldDueDate)) {
        // Past due date — mark as overdue if not already
        if (d.status != DistributionStatus.overdue &&
            d.status != DistributionStatus.partiallyFulfilled) {
          final updated = d.copyWith(
            status: DistributionStatus.overdue,
            updatedAt: DateTime.now(),
          );
          await distributionDataSource.updateDistribution(updated);
        }
      }
    }

    // Re-fetch after potential updates
    final refreshed =
        await distributionDataSource.getDistributionsByFarmer(farmer.id);

    // Check if ALL distributions' growing periods have elapsed
    final allPlotsComplete = refreshed.every(
      (d) => now.isAfter(d.expectedYieldDueDate),
    );

    if (!allPlotsComplete) {
      // Still within growing period — stay Regular
      return FarmerClassification.regular;
    }

    // Check yield return status
    final allYieldReturned = refreshed.every(
      (d) => d.status == DistributionStatus.fulfilled,
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
      // Yield NOT fully returned — start as Reminder
      if (!isInContact) {
        // Check how long since the earliest plot completed (due date passed)
        final earliestDueDate = refreshed
            .where((d) => d.status != DistributionStatus.fulfilled)
            .map((d) => d.expectedYieldDueDate)
            .reduce((a, b) => a.isBefore(b) ? a : b);

        final daysSinceDue = now.difference(earliestDueDate).inDays;

        // If 5+ days past due with no contact → auto-escalate to Blacklist
        if (daysSinceDue >= AppConstants.reminderEscalationDays) {
          return FarmerClassification.blacklist;
        }
      }
      return FarmerClassification.reminder;
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
