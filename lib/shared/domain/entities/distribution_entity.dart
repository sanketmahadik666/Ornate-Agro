import 'package:equatable/equatable.dart';

/// Req 3: Seed distribution yield status.
enum DistributionStatus { pending, due, fulfilled, partiallyFulfilled, overdue }

/// Req 3: Seed distribution log entity.
class DistributionEntity extends Equatable {
  const DistributionEntity({
    required this.id,
    required this.farmerId,
    required this.seedType,
    required this.quantityDistributed,
    required this.distributionDate,
    required this.recordedByStaffId,
    required this.expectedYieldDueDate,
    this.status = DistributionStatus.pending,
    this.quantityReturned = 0,
    this.actualReturnDate,
    this.amendmentReason,
    this.amendedByAuthorityId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String farmerId;
  final String seedType;
  final double quantityDistributed;
  final DateTime distributionDate;
  final String recordedByStaffId;
  final DateTime expectedYieldDueDate;
  final DistributionStatus status;
  final double quantityReturned;
  final DateTime? actualReturnDate;
  final String? amendmentReason;
  final String? amendedByAuthorityId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Outstanding quantity still owed by the farmer.
  double get outstandingQuantity => quantityDistributed - quantityReturned;

  DistributionEntity copyWith({
    String? id,
    String? farmerId,
    String? seedType,
    double? quantityDistributed,
    DateTime? distributionDate,
    String? recordedByStaffId,
    DateTime? expectedYieldDueDate,
    DistributionStatus? status,
    double? quantityReturned,
    DateTime? actualReturnDate,
    String? amendmentReason,
    String? amendedByAuthorityId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DistributionEntity(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      seedType: seedType ?? this.seedType,
      quantityDistributed: quantityDistributed ?? this.quantityDistributed,
      distributionDate: distributionDate ?? this.distributionDate,
      recordedByStaffId: recordedByStaffId ?? this.recordedByStaffId,
      expectedYieldDueDate: expectedYieldDueDate ?? this.expectedYieldDueDate,
      status: status ?? this.status,
      quantityReturned: quantityReturned ?? this.quantityReturned,
      actualReturnDate: actualReturnDate ?? this.actualReturnDate,
      amendmentReason: amendmentReason ?? this.amendmentReason,
      amendedByAuthorityId: amendedByAuthorityId ?? this.amendedByAuthorityId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        farmerId,
        seedType,
        quantityDistributed,
        distributionDate,
        recordedByStaffId,
        expectedYieldDueDate,
        status,
        quantityReturned,
      ];
}
