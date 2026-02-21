part of 'contact_log_bloc.dart';

sealed class ContactLogEvent extends Equatable {
  const ContactLogEvent();
  @override
  List<Object?> get props => [];
}

final class ContactLogLoadRequested extends ContactLogEvent {
  const ContactLogLoadRequested(this.farmerId);
  final String farmerId;

  @override
  List<Object?> get props => [farmerId];
}

final class ContactLogCreateRequested extends ContactLogEvent {
  const ContactLogCreateRequested(this.contactLog);
  final ContactLogEntity contactLog;

  @override
  List<Object?> get props => [contactLog];
}
