import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/database/app_database.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/features/allocation/data/repositories/asset_class_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

import '../../../harness/factories/asset_class_factory.dart';
import '../../../harness/helpers.dart';
import '../../../harness/mocks.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = memoryDatabase();
  });

  test('save then watchAll emits the class', () async {
    final repository = AssetClassRepositoryImpl(db);

    final result = await repository.save(assetClassFactory(targetPercent: 50));

    expect(result, const Right<Failure, Unit>(unit));
    expect(
      await repository.watchAll().first,
      [assetClassFactory(targetPercent: 50)],
    );
  });

  test('watchAll orders by creation time (oldest first)', () async {
    final repository = AssetClassRepositoryImpl(db);
    await repository.save(
      assetClassFactory(id: 'b', createdAt: DateTime(2026, 1, 2)),
    );
    await repository.save(
      assetClassFactory(id: 'a', createdAt: DateTime(2026, 1, 1)),
    );

    final ids = (await repository.watchAll().first).map((c) => c.id).toList();
    expect(ids, ['a', 'b']);
  });

  test('deleting a root cascades to its subclasses, sparing others', () async {
    final repository = AssetClassRepositoryImpl(db);
    await repository.save(assetClassFactory(id: 'root'));
    await repository.save(assetClassFactory(id: 'childA', parentId: 'root'));
    await repository.save(assetClassFactory(id: 'childB', parentId: 'root'));
    await repository.save(assetClassFactory(id: 'other'));

    await repository.delete('root');

    final ids = (await repository.watchAll().first).map((c) => c.id).toList();
    expect(ids, ['other']);
  });

  test('mirrors the write to the cloud (Firestore-first)', () async {
    final mirror = MockRemoteMirror();
    when(() => mirror.upsert(any(), any(), any())).thenAnswer((_) async {});
    final repository = AssetClassRepositoryImpl(db, mirror);

    await repository.save(assetClassFactory(id: 'eq'));

    verify(() => mirror.upsert('asset_classes', 'eq', any())).called(1);
  });

  test('cascade delete mirrors each child and the root to the cloud', () async {
    final mirror = MockRemoteMirror();
    when(() => mirror.upsert(any(), any(), any())).thenAnswer((_) async {});
    when(() => mirror.delete(any(), any())).thenAnswer((_) async {});
    final repository = AssetClassRepositoryImpl(db, mirror);
    await repository.save(assetClassFactory(id: 'root'));
    await repository.save(assetClassFactory(id: 'child', parentId: 'root'));

    await repository.delete('root');

    verify(() => mirror.delete('asset_classes', 'child')).called(1);
    verify(() => mirror.delete('asset_classes', 'root')).called(1);
  });

  test('a failed remote write aborts the save and skips the local cache',
      () async {
    final mirror = MockRemoteMirror();
    when(() => mirror.upsert(any(), any(), any()))
        .thenThrow(Exception('offline'));
    final repository = AssetClassRepositoryImpl(db, mirror);

    final result = await repository.save(assetClassFactory(id: 'eq'));

    expect(result.isLeft(), isTrue);
    expect(await repository.watchAll().first, isEmpty);
  });
}
