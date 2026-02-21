import 'dart:math';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Offline-safe unique ID for farmers (Req 2 - unique farmer ID).
String generateFarmerId() {
  final ts = DateTime.now().millisecondsSinceEpoch;
  final r = Random().nextInt(9999).toString().padLeft(4, '0');
  return 'FRM-$ts-$r';
}

/// Unique IDs for distributions, contacts, etc.
String generateId({String prefix = 'ID'}) => '$prefix-${_uuid.v4()}';
