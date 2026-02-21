import 'package:flutter_test/flutter_test.dart';
import 'package:ornate_agro/features/distribution/data/repositories/distribution_repository_impl.dart';
import 'package:ornate_agro/features/distribution/data/datasources/distribution_local_datasource.dart';
import 'package:ornate_agro/features/distribution/domain/repositories/distribution_repository.dart';
import 'package:ornate_agro/shared/domain/entities/distribution_entity.dart';

// Create a simple mock using Mockito or just write a manual mock.
// Writing a manual mock for simplicity since we don't want to run build_runner.

class MockLocalDataSource implements DistributionLocalDataSource {
  DistributionEntity? mockEntity;
  DistributionEntity? updatedEntity;

  @override
  Future<DistributionEntity?> getDistributionById(String id) async {
    return mockEntity;
  }

  @override
  Future<void> updateDistribution(DistributionEntity entity) async {
    updatedEntity = entity;
  }

  // Not implemented methods
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Yield Return Logic', () {
    late DistributionRepositoryImpl repository;
    late MockLocalDataSource mockDataSource;

    setUp(() {
      mockDataSource = MockLocalDataSource();
      repository = DistributionRepositoryImpl(mockDataSource);
    });

    test('Throws exception if returning quantity is <= 0', () async {
      expect(
        () => repository.recordYieldReturn(
            id: 'dist_1', quantityReturned: 0, staffId: 'staff_1'),
        throwsA(isA<DistributionException>()),
      );
    });

    test('Throws exception if returning more than outstanding', () async {
      mockDataSource.mockEntity = DistributionEntity(
        id: 'dist_1',
        farmerId: 'farmer_1',
        seedType: 'Wheat',
        quantityDistributed: 100,
        distributionDate: DateTime.now(),
        expectedYieldDueDate: DateTime.now().add(const Duration(days: 30)),
        recordedByStaffId: 'staff_1',
        status: DistributionStatus.pending,
        quantityReturned: 20, // 80 outstanding
      );

      expect(
        () => repository.recordYieldReturn(
            id: 'dist_1', quantityReturned: 81, staffId: 'staff_1'),
        throwsA(isA<DistributionException>()),
      );
    });

    test('Records partial return properly', () async {
      mockDataSource.mockEntity = DistributionEntity(
        id: 'dist_1',
        farmerId: 'farmer_1',
        seedType: 'Wheat',
        quantityDistributed: 100,
        distributionDate: DateTime.now(),
        expectedYieldDueDate: DateTime.now().add(const Duration(days: 30)),
        recordedByStaffId: 'staff_1',
        status: DistributionStatus.pending,
        quantityReturned: 20, // 80 outstanding
      );

      final updated = await repository.recordYieldReturn(
          id: 'dist_1', quantityReturned: 30, staffId: 'staff_1');

      expect(updated.quantityReturned, 50); // 20 previous + 30 new
      expect(updated.status, DistributionStatus.partiallyFulfilled);
      expect(mockDataSource.updatedEntity, updated);
    });

    test('Records full return properly and updates status to fulfilled',
        () async {
      mockDataSource.mockEntity = DistributionEntity(
        id: 'dist_1',
        farmerId: 'farmer_1',
        seedType: 'Wheat',
        quantityDistributed: 100,
        distributionDate: DateTime.now(),
        expectedYieldDueDate: DateTime.now().add(const Duration(days: 30)),
        recordedByStaffId: 'staff_1',
        status: DistributionStatus.partiallyFulfilled,
        quantityReturned: 50, // 50 outstanding
      );

      final updated = await repository.recordYieldReturn(
          id: 'dist_1', quantityReturned: 50, staffId: 'staff_1');

      expect(updated.quantityReturned, 100);
      expect(updated.status, DistributionStatus.fulfilled);
      expect(mockDataSource.updatedEntity, updated);
    });
  });
}
