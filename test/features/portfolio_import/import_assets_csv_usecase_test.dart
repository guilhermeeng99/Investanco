import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/utils/id_generator.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/institutions/domain/entities/institution.dart';
import 'package:investanco/features/portfolio_import/domain/import_assets_csv_usecase.dart';
import 'package:mocktail/mocktail.dart';

import '../../harness/factories/asset_factory.dart';
import '../../harness/factories/institution_factory.dart';
import '../../harness/mocks.dart';

/// Sequential id generator so created institutions/assets get distinct ids.
class _SeqIdGenerator implements IdGenerator {
  int _n = 0;

  @override
  String newId() => 'id${++_n}';
}

void main() {
  late MockAssetRepository assets;
  late MockInstitutionRepository institutions;
  late ImportAssetsCsvUseCase useCase;

  setUp(() {
    assets = MockAssetRepository();
    institutions = MockInstitutionRepository();
    useCase = ImportAssetsCsvUseCase(
      assets,
      institutions,
      _SeqIdGenerator(),
    );
  });

  List<AssetImportRow> parse(String csv) =>
      useCase.parseRows(csv).getOrElse(() => throw StateError('parse failed'));

  group('parseRows', () {
    test('defaults market/currency/name from the kind', () {
      final row = parse('ticker,kind,institution\nSOXX,etfUs,Avenue').single;

      expect(row.ticker, 'SOXX');
      expect(row.name, 'SOXX'); // empty name -> ticker
      expect(row.kind, AssetKind.etfUs);
      expect(row.market, Market.us);
      expect(row.currency, Currency.usd);
      expect(row.institutionName, 'Avenue');
    });

    test('accepts a friendly kind label', () {
      final row = parse(
        'ticker,kind,institution\nPETR4,ETF (EUA),Avenue',
      ).single;

      expect(row.kind, AssetKind.etfUs);
    });

    test('skips blank lines between rows', () {
      expect(
        parse('ticker,kind,institution\nSOXX,etfUs,Avenue\n\nQQQ,etfUs,Avenue'),
        hasLength(2),
      );
    });

    test('fails when the ticker column is missing', () {
      expect(
        useCase.parseRows('kind,institution\netfUs,Avenue').isLeft(),
        isTrue,
      );
    });

    test('fails when the kind column is missing', () {
      expect(
        useCase.parseRows('ticker,institution\nSOXX,Avenue').isLeft(),
        isTrue,
      );
    });

    test('fails when the institution column is missing', () {
      expect(useCase.parseRows('ticker,kind\nSOXX,etfUs').isLeft(), isTrue);
    });

    test('fails on an empty file', () {
      expect(useCase.parseRows('').isLeft(), isTrue);
    });

    test('fails on an unknown kind, tagging the row', () {
      final failure = useCase
          .parseRows('ticker,kind,institution\nSOXX,banana,Avenue')
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
      final result = await preview(
        'ticker,kind,institution\nSOXX,etfUs,Avenue\nQQQ,etfUs,Avenue',
      );

      expect(result.rows.every((r) => r.isNew), isTrue);
      expect(result.newCount, 2);
      expect(result.reusedCount, 0);
    });

    test('reuses an existing ticker (case-insensitive)', () async {
      final result = await preview(
        'ticker,kind,institution\nsoxx,etfUs,Avenue',
        existing: [assetFactory(ticker: 'SOXX')],
      );

      expect(result.rows.single.isNew, isFalse);
      expect(result.newCount, 0);
      expect(result.reusedCount, 1);
    });

    test('counts a repeated new ticker once', () async {
      final result = await preview(
        'ticker,kind,institution\nSOXX,etfUs,Avenue\nSOXX,etfUs,Avenue',
      );

      expect(result.newCount, 1);
    });
  });

  group('importRows', () {
    test('creates new assets and skips existing ones', () async {
      when(assets.watchAll).thenAnswer(
        (_) => Stream.value([assetFactory(id: 'ex', ticker: 'SOXX')]),
      );
      when(
        institutions.watchAll,
      ).thenAnswer((_) => Stream.value(const <Institution>[]));
      when(
        () => institutions.save(any()),
      ).thenAnswer((_) async => const Right(unit));
      when(() => assets.save(any())).thenAnswer((_) async => const Right(unit));

      final result = await useCase.importRows(
        parse('ticker,kind,institution\nSOXX,etfUs,Avenue\nQQQ,etfUs,Avenue'),
      );

      expect(result.getOrElse(() => throw StateError('x')).assetsCreated, 1);
      verify(() => assets.save(any())).called(1); // only QQQ
      verify(() => institutions.save(any())).called(1);
    });

    test('creates a repeated new ticker only once', () async {
      when(assets.watchAll).thenAnswer((_) => Stream.value(const <Asset>[]));
      when(
        institutions.watchAll,
      ).thenAnswer((_) => Stream.value(const <Institution>[]));
      when(
        () => institutions.save(any()),
      ).thenAnswer((_) async => const Right(unit));
      when(() => assets.save(any())).thenAnswer((_) async => const Right(unit));

      final result = await useCase.importRows(
        parse('ticker,kind,institution\nSOXX,etfUs,Avenue\nSOXX,etfUs,Avenue'),
      );

      expect(result.getOrElse(() => throw StateError('x')).assetsCreated, 1);
      verify(() => assets.save(any())).called(1);
      verify(() => institutions.save(any())).called(1);
    });

    test('reuses an existing institution by name', () async {
      when(assets.watchAll).thenAnswer((_) => Stream.value(const <Asset>[]));
      when(institutions.watchAll).thenAnswer(
        (_) => Stream.value([institutionFactory(name: 'Avenue')]),
      );
      when(() => assets.save(any())).thenAnswer((_) async => const Right(unit));

      final result = await useCase.importRows(
        parse('ticker,kind,institution\nSOXX,etfUs,avenue'),
      );

      expect(result.getOrElse(() => throw StateError('x')).assetsCreated, 1);
      verifyNever(() => institutions.save(any()));
    });

    test('returns a CacheFailure when reading existing data fails', () async {
      when(
        assets.watchAll,
      ).thenAnswer((_) => Stream.error(Exception('db down')));

      final result = await useCase.importRows(
        parse('ticker,kind,institution\nSOXX,etfUs,Avenue'),
      );

      expect(
        result.swap().getOrElse(() => throw StateError('x')),
        isA<CacheFailure>(),
      );
      verifyNever(() => assets.save(any()));
    });
  });
}
