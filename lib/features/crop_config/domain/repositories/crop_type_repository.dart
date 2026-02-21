import '../../../../shared/domain/entities/crop_type_entity.dart';

/// Abstract repository for crop type operations (Req 8).
abstract class CropTypeRepository {
  /// Get all crop types.
  Future<List<CropTypeEntity>> getAllCropTypes();

  /// Get a single crop type by ID.
  Future<CropTypeEntity?> getCropTypeById(String id);

  /// Create a new crop type.
  Future<CropTypeEntity> createCropType(CropTypeEntity cropType);

  /// Update an existing crop type's growing period.
  Future<CropTypeEntity> updateCropType(CropTypeEntity cropType);

  /// Delete a crop type (blocked if in active use by distributions).
  Future<void> deleteCropType(String id);

  /// Check if a crop type is used by any distribution.
  Future<bool> isCropTypeInUse(String cropTypeId);
}

/// Crop type exceptions.
class CropTypeException implements Exception {
  CropTypeException(this.message);
  final String message;
  @override
  String toString() => 'CropTypeException: $message';
}

class CropTypeNotFoundException extends CropTypeException {
  CropTypeNotFoundException(String id)
      : super('Crop type with ID $id not found');
}

class CropTypeInUseException extends CropTypeException {
  CropTypeInUseException()
      : super('Cannot delete crop type that is in active use');
}

class DuplicateCropTypeException extends CropTypeException {
  DuplicateCropTypeException()
      : super('Crop type with same name already exists');
}
