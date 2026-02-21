import '../../../../shared/domain/entities/crop_type_entity.dart';
import '../../domain/repositories/crop_type_repository.dart';
import '../datasources/crop_type_local_datasource.dart';

/// Implementation of [CropTypeRepository].
class CropTypeRepositoryImpl implements CropTypeRepository {
  CropTypeRepositoryImpl(this._localDataSource);

  final CropTypeLocalDataSource _localDataSource;

  @override
  Future<List<CropTypeEntity>> getAllCropTypes() {
    return _localDataSource.getAllCropTypes();
  }

  @override
  Future<CropTypeEntity?> getCropTypeById(String id) {
    return _localDataSource.getCropTypeById(id);
  }

  @override
  Future<CropTypeEntity> createCropType(CropTypeEntity cropType) async {
    // Check for duplicate name
    final existing = await _localDataSource.getCropTypeByName(cropType.name);
    if (existing != null) {
      throw DuplicateCropTypeException();
    }
    await _localDataSource.insertCropType(cropType);
    return cropType;
  }

  @override
  Future<CropTypeEntity> updateCropType(CropTypeEntity cropType) async {
    final existing = await _localDataSource.getCropTypeById(cropType.id);
    if (existing == null) {
      throw CropTypeNotFoundException(cropType.id);
    }
    await _localDataSource.updateCropType(cropType);
    return cropType;
  }

  @override
  Future<void> deleteCropType(String id) async {
    final existing = await _localDataSource.getCropTypeById(id);
    if (existing == null) {
      throw CropTypeNotFoundException(id);
    }
    // Block deletion if in use
    final inUse = await _localDataSource.isCropTypeInUse(existing.name);
    if (inUse) {
      throw CropTypeInUseException();
    }
    await _localDataSource.deleteCropType(id);
  }

  @override
  Future<bool> isCropTypeInUse(String cropTypeId) async {
    final cropType = await _localDataSource.getCropTypeById(cropTypeId);
    if (cropType == null) return false;
    return _localDataSource.isCropTypeInUse(cropType.name);
  }
}
