import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/utils/id_generator.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/portfolio_import/domain/import_assets_csv_usecase.dart';
import 'package:mocktail/mocktail.dart';

import '../../harness/factories/asset_factory.dart';
import '../../harness/mocks.dart';

/// Sequential id generator so created assets get distinct ids.
class _SeqIdGenerator implements IdGenerator {
  int _n = 0;
  @override
  String newId() => 'id${++_n}';
}

void main() {
  late MockAssetRepository assets;
  late ImportAssetsCsvUseCase useCase;

  setUp(() {
    assets = MockAssetRepository();
    useCase = ImportAssetsCsvUseCase(assets, _SeqIdGenerator());
  });

  List<AssetImportRow> parse(String csv) =>
      useCase.parseRows(csv).getOrElse(() => throw StateError('parse failed'));

  group('parseRows', () {
    test('defaults market/currency/name from the kind', () {
      final row = parse('ticker,kind\nSOXX,etfUs').single;
      expect(row.ticker, 'SOXX');
      expect(row.name, 'SOXX'); // empty name → ticker
      expect(row.kind, AssetKind.etfUs);
      expect(row.market, Market.us);
      expect(row.currency, Currency.usd);
    });

    test('accepts a friendly kind label', () {
      expect(parse('ticker,kind\nPETR4,Ação (BR)').single.kind,
          AssetKind.stockBr);
    });

    test('skips blank lines between rows', () {
      expect(parse('ticker,kind\nSOXX,etfUs\n\nQQQ,etfUs'), hasLength(2));
    });

    test('fails when the ticker column is missing', () {
      expect(useCase.parseRows('kind\netfUs').isLeft(), isTrue);
    });

    test('fails when the kind column is missing', () {
      expect(useCase.parseRows('ticker\nSOXX').isLeft(), isTrue);
    });

    test('fails on an empty file', () {
      expect(useCase.parseRows('').isLeft(), isTrue);
    });

    test('fails on an unknown kind, tagging the row', () {
      final failure = useCase
          .parseRows('ticker,kind\nSOXX,banana')
          .swap()
          .getOrElse(() => throw StateError('unexpected'));
      expect(failure, isA<ValidationFailure>());
      expect(failure.message, contains('Row 2'));
    });
  });

  group('previewRows', () {
    Future<AssetImportPreview> preview(
      String csv, {
      List<Asset> existing = const [],
    }) {
      when(assets.watchAll).thenAnswer((_) => Stream.value(existing));
      return useCase.previewRows(parse(csv));
    }

    test('tags everything new on an empty portfolio', () async {
      final result = await preview('ticker,kind\nSOXX,etfUs\nQQQ,etfUs');
      expect(result.rows.every((r) => r.isNew), isTrue);
      expect(result.newCount, 2);
      expect(result.reusedCount, 0);
    });

    test('reuses an existing ticker (case-insensitive)', () async {
      final result = await preview(
        'ticker,kind\nsoxx,etfUs',
        existing: [assetFactory(ticker: 'SOXX')],
      );
      expect(result.rows.single.isNew, isFalse);
      expect(result.newCount, 0);
      expect(result.reusedCount, 1);
    });

    test('counts a repeated new ticker once', () async {
      final result = await preview('ticker,kind\nSOXX,etfUs\nSOXX,etfUs');
      expect(result.newCount, 1);
    });
  });

  group('importRows', () {
    test('creates new assets and skips existing ones', () async {
      when(assets.watchAll).thenAnswer(
        (_) => Stream.value([assetFactory(id: 'ex', ticker: 'SOXX')]),
      );
      when(() => assets.save(any())).thenAnswer((_) async => const Right(unit));

      final result =
          await useCase.importRows(parse('ticker,kind\nSOXX,etfUs\nQQQ,etfUs'));

      expect(result.getOrElse(() => throw StateError('x')).assetsCreated, 1);
      verify(() => assets.save(any())).called(1); // only QQQ
    });

    test('creates a repeated new ticker only once', () async {
      when(assets.watchAll).thenAnswer((_) => Stream.value(const <Asset>[]));
      when(() => assets.save(any())).thenAnswer((_) async => const Right(unit));

      final result =
          await useCase.importRows(parse('ticker,kind\nSOXX,etfUs\nSOXX,etfUs'));

      expect(result.getOrElse(() => throw StateError('x')).assetsCreated, 1);
      verify(() => assets.save(any())).called(1);
    });

    test('returns a CacheFailure when reading existing assets fails', () async {
      when(assets.watchAll)
          .thenAnswer((_) => Stream.error(Exception('db down')));

      final result = await useCase.importRows(parse('ticker,kind\nSOXX,etfUs'));

      expect(result.swap().getOrElse(() => throw StateError('x')),
          isA<CacheFailure>());
      verifyNever(() => assets.save(any()));
    });
  });
}
