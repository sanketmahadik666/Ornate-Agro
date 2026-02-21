import 'package:equatable/equatable.dart';

/// Req 8: Crop type and growing period (days).
class CropTypeEntity extends Equatable {
  const CropTypeEntity({
    required this.id,
    required this.name,
    required this.growingPeriodDays,
  });

  final String id;
  final String name;
  final int growingPeriodDays;

  @override
  List<Object?> get props => [id, name, growingPeriodDays];
}
