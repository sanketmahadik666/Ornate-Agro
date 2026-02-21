part of 'crop_type_bloc.dart';

sealed class CropTypeEvent extends Equatable {
  const CropTypeEvent();
  @override
  List<Object?> get props => [];
}

final class CropTypeLoadRequested extends CropTypeEvent {
  const CropTypeLoadRequested();
}

final class CropTypeCreateRequested extends CropTypeEvent {
  const CropTypeCreateRequested(this.cropType);
  final CropTypeEntity cropType;

  @override
  List<Object?> get props => [cropType];
}

final class CropTypeUpdateRequested extends CropTypeEvent {
  const CropTypeUpdateRequested(this.cropType);
  final CropTypeEntity cropType;

  @override
  List<Object?> get props => [cropType];
}

final class CropTypeDeleteRequested extends CropTypeEvent {
  const CropTypeDeleteRequested(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}
