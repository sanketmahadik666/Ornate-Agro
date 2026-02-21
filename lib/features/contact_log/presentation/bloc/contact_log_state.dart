part of 'contact_log_bloc.dart';

enum ContactLogBlocStatus { initial, loading, loaded, success, failure }

class ContactLogState extends Equatable {
  const ContactLogState({
    this.status = ContactLogBlocStatus.initial,
    this.logs,
    this.errorMessage,
    this.successMessage,
  });

  const ContactLogState.initial() : this();
  const ContactLogState.loading() : this(status: ContactLogBlocStatus.loading);
  const ContactLogState.loaded(List<ContactLogEntity> logs)
      : this(status: ContactLogBlocStatus.loaded, logs: logs);
  const ContactLogState.success(String message)
      : this(status: ContactLogBlocStatus.success, successMessage: message);
  const ContactLogState.failure(String message)
      : this(status: ContactLogBlocStatus.failure, errorMessage: message);

  final ContactLogBlocStatus status;
  final List<ContactLogEntity>? logs;
  final String? errorMessage;
  final String? successMessage;

  @override
  List<Object?> get props => [status, logs, errorMessage, successMessage];
}
