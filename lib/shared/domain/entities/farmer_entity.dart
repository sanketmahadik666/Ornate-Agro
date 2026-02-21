import 'package:equatable/equatable.dart';

/// Req 2: Farmer profile. Classification from Req 5.
enum FarmerClassification { regular, sleepy, blacklist, reminder }

class FarmerEntity extends Equatable {
  const FarmerEntity({
    required this.id,
    required this.fullName,
    required this.contactNumber,
    required this.village,
    required this.plotCount,
    required this.areaPerPlot,
    required this.assignedCropTypeId,
    this.classification = FarmerClassification.regular,
    this.lastContactAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String fullName;
  final String contactNumber;
  final String village;
  final int plotCount;
  final double areaPerPlot;
  final String assignedCropTypeId;
  final FarmerClassification classification;
  final DateTime? lastContactAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FarmerEntity copyWith({
    String? id,
    String? fullName,
    String? contactNumber,
    String? village,
    int? plotCount,
    double? areaPerPlot,
    String? assignedCropTypeId,
    FarmerClassification? classification,
    DateTime? lastContactAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FarmerEntity(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      contactNumber: contactNumber ?? this.contactNumber,
      village: village ?? this.village,
      plotCount: plotCount ?? this.plotCount,
      areaPerPlot: areaPerPlot ?? this.areaPerPlot,
      assignedCropTypeId: assignedCropTypeId ?? this.assignedCropTypeId,
      classification: classification ?? this.classification,
      lastContactAt: lastContactAt ?? this.lastContactAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        contactNumber,
        village,
        plotCount,
        areaPerPlot,
        assignedCropTypeId,
        classification
      ];
}
