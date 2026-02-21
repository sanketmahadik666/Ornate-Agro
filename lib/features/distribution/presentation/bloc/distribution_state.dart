part of 'distribution_bloc.dart';

enum DistributionBlocStatus { initial, loading, loaded, failure, success }

final class DistributionState extends Equatable {
  const DistributionState._({
    required this.status,
    this.distributions,
    this.errorMessage,
    this.successMessage,
  });

  const DistributionState.initial()
      : this._(status: DistributionBlocStatus.initial);

  const DistributionState.loading()
      : this._(status: DistributionBlocStatus.loading);

  const DistributionState.loaded(List<DistributionEntity> d)
      : this._(status: DistributionBlocStatus.loaded, distributions: d);

  const DistributionState.failure(String msg)
      : this._(status: DistributionBlocStatus.failure, errorMessage: msg);

  const DistributionState.success(String msg)
      : this._(status: DistributionBlocStatus.success, successMessage: msg);

  final DistributionBlocStatus status;
  final List<DistributionEntity>? distributions;
  final String? errorMessage;
  final String? successMessage;

  @override
  List<Object?> get props =>
      [status, distributions, errorMessage, successMessage];
}
