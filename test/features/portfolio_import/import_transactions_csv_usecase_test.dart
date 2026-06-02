import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/utils/id_generator.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/institutions/domain/entities/institution.dart';
import 'package:investanco/features/portfolio_import/domain/import_transactions_csv_usecase.dart';
import 'package:investanco/features/transactions/domain/entities/asset_transaction.dart';
import 'package:mocktail/mocktail.dart';

import '../../harness/factories/asset_factory.dart';
import '../../harness/factories/institution_factory.dart';
import '../../harness/mocks.dart';

class _SeqIdGenerator implements IdGenerator {
  int _n = 0;

  @override
  String newId() => 'id${++_n}';
}

void main() {
  late MockAssetRepository assets;
  late MockInstitutionRepository institutions;
  late MockTransactionRepository transactions;
  late ImportTransactionsCsvUseCase useCase;

  setUp(() {
    assets = MockAssetRepository();
    institutions = MockInstitutionRepository();
    transactions = MockTransactionRepository();
    useCase = ImportTransactionsCsvUseCase(
      assets,
      institutions,
      transactions,
      _SeqIdGenerator(),
    );
  });

  List<TransactionImportRow> parse(String csv) =>
      useCase.parseRows(csv).getOrElse(() => throw StateError('parse failed'));

  const header = 'ticker,institution,operation,quantity,price';

  group('parseRows', () {
    test('defaults operation to buy and date to today', () {
      final row = parse(
        'ticker,institution,quantity,price\nSOXX,Avenue,2,100',
      ).single;

      expect(row.operation, TransactionKind.buy);
      final now = DateTime.now();
      expect(row.date, DateTime(now.year, now.month, now.day));
    });

    test('fails when the institution column is missing', () {
      expect(
        useCase.parseRows('ticker,quantity,price\nSOXX,2,100').isLeft(),
        isTrue,
      );
    });

    test('fails when a dividend has no amount', () {
      expect(
        useCase
            .parseRows('ticker,institution,operation\nSOXX,Avenue,dividend')
            .isLeft(),
        isTrue,
      );
    });

    test('fails when quantity is zero', () {
      expect(
        useCase.parseRows('$header\nSOXX,Avenue,buy,0,100').isLeft(),
        isTrue,
      );
    });

    test('parses a dividend with amount and zero quantity', () {
      final row = parse(
        'ticker,institution,operation,amount\nSOXX,Avenue,dividend,15.5',
      ).single;

      expect(row.operation, TransactionKind.dividend);
      expect(row.quantity, 0);
      expect(row.amountMajor, 15.5);
    });
  });

  group('previewRows', () {
    Future<TransactionImportPreview> preview(
      String csv, {
      List<Asset> existingAssets = const [],
      List<Institution> existingInstitutions = const [],
    }) {
      when(assets.watchAll).thenAnswer((_) => Stream.value(existingAssets));
      when(
        institutions.watchAll,
      ).thenAnswer((_) => Stream.value(existingInstitutions));
      return useCase.previewRows(parse(csv));
    }

    test('flags a missing asset and blocks import', () async {
      final result = await preview('$header\nSOXX,Avenue,buy,2,100');

      expect(result.rows.single.assetExists, isFalse);
      expect(result.missingTickers, ['SOXX']);
      expect(result.canImport, isFalse);
    });

    test('allows import when asset institution matches the CSV', () async {
      final result = await preview(
        '$header\nSOXX,Avenue,buy,2,100',
        existingAssets: [assetFactory(ticker: 'SOXX', institutionId: 'i1')],
        existingInstitutions: [institutionFactory(id: 'i1', name: 'Avenue')],
      );

      expect(result.rows.single.assetExists, isTrue);
      expect(result.rows.single.assetHasInstitution, isTrue);
      expect(result.rows.single.institutionMatchesAsset, isTrue);
      expect(result.canImport, isTrue);
      expect(result.newInstitutionCount, 0);
    });

    test('blocks assets that are not linked to an institution', () async {
      final result = await preview(
        '$header\nSOXX,Avenue,buy,2,100',
        existingAssets: [assetFactory(ticker: 'SOXX', institutionId: null)],
      );

      expect(result.rows.single.assetHasInstitution, isFalse);
      expect(result.unlinkedTickers, ['SOXX']);
      expect(result.canImport, isFalse);
    });

    test('blocks rows whose CSV institution differs from the asset', () async {
      final result = await preview(
        '$header\nSOXX,Nubank,buy,2,100',
        existingAssets: [assetFactory(ticker: 'SOXX', institutionId: 'i1')],
        existingInstitutions: [institutionFactory(id: 'i1', name: 'Avenue')],
      );

      expect(result.rows.single.institutionMatchesAsset, isFalse);
      expect(result.institutionMismatchTickers, ['SOXX']);
      expect(result.canImport, isFalse);
    });
  });

  group('importRows', () {
    test('creates a transaction using the asset institution', () async {
      when(assets.watchAll).thenAnswer(
        (_) => Stream.value([
          assetFactory(
            ticker: 'SOXX',
            currency: Currency.usd,
            institutionId: 'i1',
          ),
        ]),
      );
      when(institutions.watchAll).thenAnswer(
        (_) => Stream.value([
          institutionFactory(id: 'i1', name: 'Avenue', currency: Currency.usd),
        ]),
      );
      when(
        () => transactions.save(any()),
      ).thenAnswer((_) async => const Right(unit));

      final result = await useCase.importRows(
        parse('$header\nSOXX,Avenue,buy,2,100'),
      );

      final tally = result.getOrElse(() => throw StateError('unexpected'));
      expect(tally.transactionsCreated, 1);
      expect(tally.institutionsCreated, 0);
      final saved =
          verify(() => transactions.save(captureAny())).captured.single
              as AssetTransaction;
      expect(saved.institutionId, 'i1');
      verifyNever(() => institutions.save(any()));
    });

    test('returns a ValidationFailure when the asset does not exist', () async {
      when(assets.watchAll).thenAnswer((_) => Stream.value(const <Asset>[]));
      when(
        institutions.watchAll,
      ).thenAnswer((_) => Stream.value(const <Institution>[]));

      final result = await useCase.importRows(
        parse('$header\nSOXX,Avenue,buy,2,100'),
      );

      expect(
        result.swap().getOrElse(() => throw StateError('x')),
        isA<ValidationFailure>(),
      );
      verifyNever(() => transactions.save(any()));
    });

    test(
      'returns a ValidationFailure when the asset has no institution',
      () async {
        when(assets.watchAll).thenAnswer(
          (_) =>
              Stream.value([assetFactory(ticker: 'SOXX', institutionId: null)]),
        );
        when(
          institutions.watchAll,
        ).thenAnswer((_) => Stream.value(const <Institution>[]));

        final result = await useCase.importRows(
          parse('$header\nSOXX,Avenue,buy,2,100'),
        );

        final failure =
            result.swap().getOrElse(() => throw StateError('x'))
                as ValidationFailure;
        expect(failure.code, ValidationCode.assetInstitutionRequired);
      },
    );

    test(
      'returns a ValidationFailure when the CSV institution mismatches',
      () async {
        when(assets.watchAll).thenAnswer(
          (_) =>
              Stream.value([assetFactory(ticker: 'SOXX', institutionId: 'i1')]),
        );
        when(institutions.watchAll).thenAnswer(
          (_) => Stream.value([institutionFactory(id: 'i1', name: 'Avenue')]),
        );

        final result = await useCase.importRows(
          parse('$header\nSOXX,Nubank,buy,2,100'),
        );

        final failure =
            result.swap().getOrElse(() => throw StateError('x'))
                as ValidationFailure;
        expect(failure.code, ValidationCode.transactionInstitutionMismatch);
      },
    );

    test('returns a CacheFailure when reading existing data fails', () async {
      when(
        assets.watchAll,
      ).thenAnswer((_) => Stream.error(Exception('db down')));
      when(
        institutions.watchAll,
      ).thenAnswer((_) => Stream.value(const <Institution>[]));

      final result = await useCase.importRows(
        parse('$header\nSOXX,Avenue,buy,2,100'),
      );

      expect(
        result.swap().getOrElse(() => throw StateError('x')),
        isA<CacheFailure>(),
      );
    });
  });
}
