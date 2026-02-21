import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../shared/domain/entities/distribution_entity.dart';
import '../../domain/repositories/distribution_repository.dart';

part 'distribution_event.dart';
part 'distribution_state.dart';

class DistributionBloc extends Bloc<DistributionEvent, DistributionState> {
  DistributionBloc(this._repository)
      : super(const DistributionState.initial()) {
    on<DistributionLoadRequested>(_onLoadRequested);
    on<DistributionCreateRequested>(_onCreateRequested);
    on<DistributionAmendRequested>(_onAmendRequested);
    on<DistributionFilterRequested>(_onFilterRequested);
    on<DistributionLoadByFarmerRequested>(_onLoadByFarmerRequested);
    on<DistributionYieldReturnRequested>(_onYieldReturnRequested);
  }

  final DistributionRepository _repository;

  Future<void> _onLoadRequested(
    DistributionLoadRequested event,
    Emitter<DistributionState> emit,
  ) async {
    emit(const DistributionState.loading());
    try {
      final distributions = await _repository.getAllDistributions();
      emit(DistributionState.loaded(distributions));
    } catch (e) {
      emit(DistributionState.failure('Failed to load distributions: $e'));
    }
  }

  Future<void> _onCreateRequested(
    DistributionCreateRequested event,
    Emitter<DistributionState> emit,
  ) async {
    emit(const DistributionState.loading());
    try {
      await _repository.createDistribution(event.distribution);
      emit(const DistributionState.success(
          'Distribution recorded successfully'));
      add(const DistributionLoadRequested());
    } catch (e) {
      emit(DistributionState.failure('Failed to record distribution: $e'));
    }
  }

  Future<void> _onAmendRequested(
    DistributionAmendRequested event,
    Emitter<DistributionState> emit,
  ) async {
    emit(const DistributionState.loading());
    try {
      await _repository.amendDistribution(
        id: event.id,
        reason: event.reason,
        authorityId: event.authorityId,
        quantityDistributed: event.quantityDistributed,
        seedType: event.seedType,
        distributionDate: event.distributionDate,
      );
      emit(const DistributionState.success('Distribution amended'));
      add(const DistributionLoadRequested());
    } on DistributionNotFoundException {
      emit(const DistributionState.failure('Distribution not found'));
    } catch (e) {
      emit(DistributionState.failure('Failed to amend distribution: $e'));
    }
  }

  Future<void> _onFilterRequested(
    DistributionFilterRequested event,
    Emitter<DistributionState> emit,
  ) async {
    emit(const DistributionState.loading());
    try {
      final distributions = await _repository.getFilteredDistributions(
        startDate: event.startDate,
        endDate: event.endDate,
        seedType: event.seedType,
        farmerId: event.farmerId,
        status: event.status,
      );
      emit(DistributionState.loaded(distributions));
    } catch (e) {
      emit(DistributionState.failure('Filter failed: $e'));
    }
  }

  Future<void> _onLoadByFarmerRequested(
    DistributionLoadByFarmerRequested event,
    Emitter<DistributionState> emit,
  ) async {
    emit(const DistributionState.loading());
    try {
      final distributions =
          await _repository.getDistributionsByFarmer(event.farmerId);
      emit(DistributionState.loaded(distributions));
    } catch (e) {
      emit(DistributionState.failure('Failed to load distributions: $e'));
    }
  }

  Future<void> _onYieldReturnRequested(
    DistributionYieldReturnRequested event,
    Emitter<DistributionState> emit,
  ) async {
    emit(const DistributionState.loading());
    try {
      await _repository.recordYieldReturn(
        id: event.id,
        quantityReturned: event.quantityReturned,
        staffId: event.staffId,
      );
      emit(const DistributionState.success('Yield return recorded'));
      // Reload distributions after recording
      add(const DistributionLoadRequested());
    } on DistributionNotFoundException {
      emit(const DistributionState.failure('Distribution not found'));
    } catch (e) {
      emit(DistributionState.failure('Failed to record yield return: $e'));
    }
  }
}
