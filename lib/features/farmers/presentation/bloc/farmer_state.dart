part of 'farmer_bloc.dart';

enum FarmerStatus { initial, loading, loaded, failure, success }

final class FarmerState extends Equatable {
  const FarmerState._({
    required this.status,
    this.farmers,
    this.farmer,
    this.errorMessage,
    this.successMessage,
  });

  const FarmerState.initial()
      : this._(status: FarmerStatus.initial);

  const FarmerState.loading()
      : this._(status: FarmerStatus.loading);

  const FarmerState.loaded(List<FarmerEntity> f)
      : this._(status: FarmerStatus.loaded, farmers: f);

  const FarmerState.farmerLoaded(FarmerEntity f)
      : this._(status: FarmerStatus.loaded, farmer: f);

  const FarmerState.failure(String msg)
      : this._(status: FarmerStatus.failure, errorMessage: msg);

  const FarmerState.success(String msg)
      : this._(status: FarmerStatus.success, successMessage: msg);

  final FarmerStatus status;
  final List<FarmerEntity>? farmers;
  final FarmerEntity? farmer;
  final String? errorMessage;
  final String? successMessage;

  @override
  List<Object?> get props => [status, farmers, farmer, errorMessage, successMessage];
}
