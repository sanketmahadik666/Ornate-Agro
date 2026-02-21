import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../shared/domain/entities/contact_log_entity.dart';
import '../../domain/repositories/contact_log_repository.dart';

part 'contact_log_event.dart';
part 'contact_log_state.dart';

class ContactLogBloc extends Bloc<ContactLogEvent, ContactLogState> {
  ContactLogBloc(this._repository) : super(const ContactLogState.initial()) {
    on<ContactLogLoadRequested>(_onLoadRequested);
    on<ContactLogCreateRequested>(_onCreateRequested);
  }

  final ContactLogRepository _repository;

  Future<void> _onLoadRequested(
    ContactLogLoadRequested event,
    Emitter<ContactLogState> emit,
  ) async {
    emit(const ContactLogState.loading());
    try {
      final logs = await _repository.getContactLogsByFarmerId(event.farmerId);
      emit(ContactLogState.loaded(logs));
    } catch (e) {
      emit(ContactLogState.failure('Failed to load contact logs: $e'));
    }
  }

  Future<void> _onCreateRequested(
    ContactLogCreateRequested event,
    Emitter<ContactLogState> emit,
  ) async {
    emit(const ContactLogState.loading());
    try {
      await _repository.createContactLog(event.contactLog);
      emit(const ContactLogState.success('Contact log saved successfully'));
      // Reload logs after saving
      add(ContactLogLoadRequested(event.contactLog.farmerId));
    } catch (e) {
      emit(ContactLogState.failure('Failed to save contact log: $e'));
    }
  }
}
