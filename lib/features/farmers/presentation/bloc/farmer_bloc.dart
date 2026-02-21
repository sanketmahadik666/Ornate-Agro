import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../shared/domain/entities/farmer_entity.dart';
import '../../domain/repositories/farmer_repository.dart';

part 'farmer_state.dart';
part 'farmer_event.dart';

class FarmerBloc extends Bloc<FarmerEvent, FarmerState> {
  FarmerBloc(this._farmerRepository) : super(const FarmerState.initial()) {
    on<FarmerLoadRequested>(_onLoadRequested);
    on<FarmerSearchRequested>(_onSearchRequested);
    on<FarmerCreateRequested>(_onCreateRequested);
    on<FarmerUpdateRequested>(_onUpdateRequested);
    on<FarmerDeleteRequested>(_onDeleteRequested);
    on<FarmerLoadByIdRequested>(_onLoadByIdRequested);
    on<FarmerFilterByClassificationRequested>(_onFilterByClassification);
    on<FarmerFilterByVillageRequested>(_onFilterByVillage);
    
    // Load farmers on initialization
    add(const FarmerLoadRequested());
  }

  final FarmerRepository _farmerRepository;

  void _onLoadRequested(FarmerLoadRequested event, Emitter<FarmerState> emit) async {
    emit(const FarmerState.loading());
    try {
      final farmers = await _farmerRepository.getAllFarmers();
      emit(FarmerState.loaded(farmers));
    } catch (e) {
      emit(FarmerState.failure('Failed to load farmers: ${e.toString()}'));
    }
  }

  void _onSearchRequested(FarmerSearchRequested event, Emitter<FarmerState> emit) async {
    if (event.query.isEmpty) {
      add(const FarmerLoadRequested());
      return;
    }

    emit(const FarmerState.loading());
    try {
      final farmers = await _farmerRepository.searchFarmers(event.query);
      emit(FarmerState.loaded(farmers));
    } catch (e) {
      emit(FarmerState.failure('Search failed: ${e.toString()}'));
    }
  }

  void _onCreateRequested(FarmerCreateRequested event, Emitter<FarmerState> emit) async {
    emit(const FarmerState.loading());
    try {
      await _farmerRepository.createFarmer(event.farmer);
      add(const FarmerLoadRequested());
      emit(const FarmerState.success('Farmer created successfully'));
    } on DuplicateFarmerException {
      emit(const FarmerState.failure('Farmer with same name and contact already exists'));
    } catch (e) {
      emit(FarmerState.failure('Failed to create farmer: ${e.toString()}'));
    }
  }

  void _onUpdateRequested(FarmerUpdateRequested event, Emitter<FarmerState> emit) async {
    emit(const FarmerState.loading());
    try {
      await _farmerRepository.updateFarmer(event.farmer);
      add(const FarmerLoadRequested());
      emit(const FarmerState.success('Farmer updated successfully'));
    } on FarmerNotFoundException {
      emit(const FarmerState.failure('Farmer not found'));
    } on DuplicateFarmerException {
      emit(const FarmerState.failure('Farmer with same name and contact already exists'));
    } catch (e) {
      emit(FarmerState.failure('Failed to update farmer: ${e.toString()}'));
    }
  }

  void _onDeleteRequested(FarmerDeleteRequested event, Emitter<FarmerState> emit) async {
    emit(const FarmerState.loading());
    try {
      await _farmerRepository.deleteFarmer(event.id);
      add(const FarmerLoadRequested());
      emit(const FarmerState.success('Farmer deleted successfully'));
    } on FarmerNotFoundException {
      emit(const FarmerState.failure('Farmer not found'));
    } catch (e) {
      emit(FarmerState.failure('Failed to delete farmer: ${e.toString()}'));
    }
  }

  void _onLoadByIdRequested(FarmerLoadByIdRequested event, Emitter<FarmerState> emit) async {
    try {
      final farmer = await _farmerRepository.getFarmerById(event.id);
      if (farmer == null) {
        emit(const FarmerState.failure('Farmer not found'));
      } else {
        emit(FarmerState.farmerLoaded(farmer));
      }
    } catch (e) {
      emit(FarmerState.failure('Failed to load farmer: ${e.toString()}'));
    }
  }

  void _onFilterByClassification(FarmerFilterByClassificationRequested event, Emitter<FarmerState> emit) async {
    emit(const FarmerState.loading());
    try {
      final farmers = await _farmerRepository.getFarmersByClassification(event.classification);
      emit(FarmerState.loaded(farmers));
    } catch (e) {
      emit(FarmerState.failure('Failed to filter farmers: ${e.toString()}'));
    }
  }

  void _onFilterByVillage(FarmerFilterByVillageRequested event, Emitter<FarmerState> emit) async {
    emit(const FarmerState.loading());
    try {
      final farmers = await _farmerRepository.getFarmersByVillage(event.village);
      emit(FarmerState.loaded(farmers));
    } catch (e) {
      emit(FarmerState.failure('Failed to filter farmers: ${e.toString()}'));
    }
  }
}
