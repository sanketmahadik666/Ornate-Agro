import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../shared/domain/entities/crop_type_entity.dart';
import '../../domain/repositories/crop_type_repository.dart';

part 'crop_type_event.dart';
part 'crop_type_state.dart';

class CropTypeBloc extends Bloc<CropTypeEvent, CropTypeState> {
  CropTypeBloc(this._repository) : super(const CropTypeState.initial()) {
    on<CropTypeLoadRequested>(_onLoadRequested);
    on<CropTypeCreateRequested>(_onCreateRequested);
    on<CropTypeUpdateRequested>(_onUpdateRequested);
    on<CropTypeDeleteRequested>(_onDeleteRequested);

    // Load on init
    add(const CropTypeLoadRequested());
  }

  final CropTypeRepository _repository;

  Future<void> _onLoadRequested(
    CropTypeLoadRequested event,
    Emitter<CropTypeState> emit,
  ) async {
    emit(const CropTypeState.loading());
    try {
      final cropTypes = await _repository.getAllCropTypes();
      emit(CropTypeState.loaded(cropTypes));
    } catch (e) {
      emit(CropTypeState.failure('Failed to load crop types: $e'));
    }
  }

  Future<void> _onCreateRequested(
    CropTypeCreateRequested event,
    Emitter<CropTypeState> emit,
  ) async {
    emit(const CropTypeState.loading());
    try {
      await _repository.createCropType(event.cropType);
      emit(const CropTypeState.success('Crop type added'));
      add(const CropTypeLoadRequested());
    } on DuplicateCropTypeException {
      emit(const CropTypeState.failure(
          'Crop type with this name already exists'));
    } catch (e) {
      emit(CropTypeState.failure('Failed to create: $e'));
    }
  }

  Future<void> _onUpdateRequested(
    CropTypeUpdateRequested event,
    Emitter<CropTypeState> emit,
  ) async {
    emit(const CropTypeState.loading());
    try {
      await _repository.updateCropType(event.cropType);
      emit(const CropTypeState.success('Crop type updated'));
      add(const CropTypeLoadRequested());
    } catch (e) {
      emit(CropTypeState.failure('Failed to update: $e'));
    }
  }

  Future<void> _onDeleteRequested(
    CropTypeDeleteRequested event,
    Emitter<CropTypeState> emit,
  ) async {
    emit(const CropTypeState.loading());
    try {
      await _repository.deleteCropType(event.id);
      emit(const CropTypeState.success('Crop type deleted'));
      add(const CropTypeLoadRequested());
    } on CropTypeInUseException {
      emit(const CropTypeState.failure(
          'Cannot delete — crop type is used in active distributions'));
    } catch (e) {
      emit(CropTypeState.failure('Failed to delete: $e'));
    }
  }
}
