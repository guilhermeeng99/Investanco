import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/features/allocation/domain/usecases/save_asset_class_usecase.dart';
import 'package:mocktail/mocktail.dart';

import '../../../harness/factories/asset_class_factory.dart';
import '../../../harness/mocks.dart';

void main() {
  late MockAssetClassRepository repository;
  late SaveAssetClassUseCase useCase;

  setUp(() {
    repository = MockAssetClassRepository();
    useCase = SaveAssetClassUseCase(repository);
    when(() => repository.save(any()))
        .thenAnswer((_) async => const Right(unit));
  });

  test('saves a valid root class', () async {
    final result = await useCase(
      assetClassFactory(id: 'eq', targetPercent: 60),
      existing: const [],
    );

    expect(result, const Right<Failure, Unit>(unit));
    verify(() => repository.save(any())).called(1);
  });

  test('rejects an empty name without saving', () async {
    final result = await useCase(
      assetClassFactory(id: 'eq', name: '   ', targetPercent: 10),
      existing: const [],
    );

    expect(result.isLeft(), isTrue);
    verifyNever(() => repository.save(any()));
  });

  test('rejects a target outside 0..100', () async {
    final result = await useCase(
      assetClassFactory(id: 'eq', targetPercent: 150),
      existing: const [],
    );

    expect(result.isLeft(), isTrue);
    verifyNever(() => repository.save(any()));
  });

  test('rejects when the class target sum exceeds 100%', () async {
    final existing = [
      assetClassFactory(id: 'a', targetPercent: 80),
    ];
    final result = await useCase(
      assetClassFactory(id: 'b', targetPercent: 30),
      existing: existing,
    );

    expect(result.isLeft(), isTrue);
    verifyNever(() => repository.save(any()));
  });

  test('allows updating a class in place (excludes itself from the sum)',
      () async {
    final existing = [
      assetClassFactory(id: 'a', targetPercent: 60),
      assetClassFactory(id: 'b', targetPercent: 40),
    ];
    // Re-saving 'a' at 60 must not count its own old value twice.
    final result = await useCase(
      assetClassFactory(id: 'a', targetPercent: 60),
      existing: existing,
    );

    expect(result, const Right<Failure, Unit>(unit));
    verify(() => repository.save(any())).called(1);
  });
}
