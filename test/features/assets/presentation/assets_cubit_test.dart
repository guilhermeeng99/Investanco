import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/assets/presentation/cubit/assets_cubit.dart';
import 'package:investanco/features/assets/presentation/cubit/assets_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../../harness/factories/asset_factory.dart';
import '../../../harness/mocks.dart';

void main() {
  late MockAssetRepository repository;
  final sample = assetFactory();

  setUp(() {
    repository = MockAssetRepository();
    when(repository.watchAll).thenAnswer((_) => Stream.value([sample]));
  });

  blocTest<AssetsCubit, AssetsState>(
    'emits Loaded from the repository stream',
    build: () => AssetsCubit(repository, const FakeIdGenerator()),
    expect: () => [
      AssetsLoaded([sample]),
    ],
  );

  blocTest<AssetsCubit, AssetsState>(
    'add() upper-cases the ticker and persists',
    build: () => AssetsCubit(repository, const FakeIdGenerator()),
    setUp: () => when(() => repository.save(any()))
        .thenAnswer((_) async => const Right(unit)),
    act: (cubit) => cubit.add(
      ticker: 'aapl',
      name: 'Apple',
      kind: AssetKind.stockUs,
      market: Market.us,
      currency: Currency.usd,
    ),
    verify: (_) {
      final captured =
          verify(() => repository.save(captureAny())).captured.single;
      expect((captured as Asset).ticker, 'AAPL');
      expect(captured.id, 'generated-id');
    },
  );

  blocTest<AssetsCubit, AssetsState>(
    'remove() surfaces InUseFailure from the repository',
    build: () => AssetsCubit(repository, const FakeIdGenerator()),
    setUp: () => when(() => repository.delete(any()))
        .thenAnswer((_) async => const Left(InUseFailure())),
    act: (cubit) async {
      final failure = await cubit.remove('a1');
      expect(failure, isA<InUseFailure>());
    },
  );
}
