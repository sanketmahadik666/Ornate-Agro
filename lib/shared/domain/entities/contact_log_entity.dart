import 'package:equatable/equatable.dart';

/// Req 6: Contact event entity between staff and farmer.
class ContactLogEntity extends Equatable {
  const ContactLogEntity({
    required this.id,
    required this.farmerId,
    required this.contactDate,
    required this.contactMethod,
    required this.notes,
    required this.recordedByStaffId,
    this.createdAt,
  });

  final String id;
  final String farmerId;
  final DateTime contactDate;
  final String contactMethod; // e.g., 'call', 'visit', 'message'
  final String notes;
  final String recordedByStaffId;
  final DateTime? createdAt;

  ContactLogEntity copyWith({
    String? id,
    String? farmerId,
    DateTime? contactDate,
    String? contactMethod,
    String? notes,
    String? recordedByStaffId,
    DateTime? createdAt,
  }) {
    return ContactLogEntity(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      contactDate: contactDate ?? this.contactDate,
      contactMethod: contactMethod ?? this.contactMethod,
      notes: notes ?? this.notes,
      recordedByStaffId: recordedByStaffId ?? this.recordedByStaffId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        farmerId,
        contactDate,
        contactMethod,
        notes,
        recordedByStaffId,
      ];
}
