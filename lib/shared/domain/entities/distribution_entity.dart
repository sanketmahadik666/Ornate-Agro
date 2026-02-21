import 'package:equatable/equatable.dart';

/// Req 3: Seed distribution log. Yield status from Req 4.
enum YieldReturnStatus { pending, due, fulfilled, partiallyFulfilled, overdue }

class DistributionEntity extends Equatable {
  const DistributionEntity({
    required this.id,
    required this.farmerId,
    required this.seedType,
    required this.quantityDistributed,
    required this.distributionDate,
    required this.recordedByStaffId,
    required this.expectedYieldDueDate,
    this.yieldReturnStatus = YieldReturnStatus.pending,
    this.quantityReturned,
    this.actualReturnDate,
  });

  final String id;
  final String farmerId;
  final String seedType;
  final double quantityDistributed;
  final DateTime distributionDate;
  final String recordedByStaffId;
  final DateTime expectedYieldDueDate;
  final YieldReturnStatus yieldReturnStatus;
  final double? quantityReturned;
  final DateTime? actualReturnDate;

  @override
  List<Object?> get props => [id, farmerId, seedType, quantityDistributed, distributionDate];
}
