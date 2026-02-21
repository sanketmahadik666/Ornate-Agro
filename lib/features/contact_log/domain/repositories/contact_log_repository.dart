import '../../../../shared/domain/entities/contact_log_entity.dart';

abstract class ContactLogRepository {
  Future<List<ContactLogEntity>> getContactLogsByFarmerId(String farmerId);
  Future<ContactLogEntity> createContactLog(ContactLogEntity log);
}

class ContactLogException implements Exception {
  ContactLogException(this.message);
  final String message;
  @override
  String toString() => 'ContactLogException: $message';
}
