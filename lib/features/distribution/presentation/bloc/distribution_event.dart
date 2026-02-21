part of 'distribution_bloc.dart';

sealed class DistributionEvent extends Equatable {
  const DistributionEvent();
  @override
  List<Object?> get props => [];
}

final class DistributionLoadRequested extends DistributionEvent {
  const DistributionLoadRequested();
}

final class DistributionCreateRequested extends DistributionEvent {
  const DistributionCreateRequested(this.distribution);
  final DistributionEntity distribution;

  @override
  List<Object?> get props => [distribution];
}

final class DistributionAmendRequested extends DistributionEvent {
  const DistributionAmendRequested({
    required this.id,
    required this.reason,
    required this.authorityId,
    this.quantityDistributed,
    this.seedType,
    this.distributionDate,
  });

  final String id;
  final String reason;
  final String authorityId;
  final double? quantityDistributed;
  final String? seedType;
  final DateTime? distributionDate;

  @override
  List<Object?> get props => [
        id,
        reason,
        authorityId,
        quantityDistributed,
        seedType,
        distributionDate
      ];
}

final class DistributionFilterRequested extends DistributionEvent {
  const DistributionFilterRequested({
    this.startDate,
    this.endDate,
    this.seedType,
    this.farmerId,
    this.status,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final String? seedType;
  final String? farmerId;
  final DistributionStatus? status;

  @override
  List<Object?> get props => [startDate, endDate, seedType, farmerId, status];
}

final class DistributionLoadByFarmerRequested extends DistributionEvent {
  const DistributionLoadByFarmerRequested(this.farmerId);
  final String farmerId;

  @override
  List<Object?> get props => [farmerId];
}

final class DistributionYieldReturnRequested extends DistributionEvent {
  const DistributionYieldReturnRequested({
    required this.id,
    required this.quantityReturned,
    required this.staffId,
  });

  final String id;
  final double quantityReturned;
  final String staffId;

  @override
  List<Object?> get props => [id, quantityReturned, staffId];
}
