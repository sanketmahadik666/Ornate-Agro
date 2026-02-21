part of 'crop_type_bloc.dart';

enum CropTypeBlocStatus { initial, loading, loaded, failure, success }

final class CropTypeState extends Equatable {
  const CropTypeState._({
    required this.status,
    this.cropTypes,
    this.errorMessage,
    this.successMessage,
  });

  const CropTypeState.initial() : this._(status: CropTypeBlocStatus.initial);

  const CropTypeState.loading() : this._(status: CropTypeBlocStatus.loading);

  const CropTypeState.loaded(List<CropTypeEntity> ct)
      : this._(status: CropTypeBlocStatus.loaded, cropTypes: ct);

  const CropTypeState.failure(String msg)
      : this._(status: CropTypeBlocStatus.failure, errorMessage: msg);

  const CropTypeState.success(String msg)
      : this._(status: CropTypeBlocStatus.success, successMessage: msg);

  final CropTypeBlocStatus status;
  final List<CropTypeEntity>? cropTypes;
  final String? errorMessage;
  final String? successMessage;

  @override
  List<Object?> get props => [status, cropTypes, errorMessage, successMessage];
}
