import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/utils/id_generator.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/institutions/domain/entities/institution.dart';
import 'package:investanco/features/portfolio_import/domain/import_portfolio_csv_usecase.dart';
import 'package:investanco/features/transactions/domain/entities/asset_transaction.dart';
import 'package:mocktail/mocktail.dart';

import '../../harness/factories/asset_factory.dart';
import '../../harness/factories/institution_factory.dart';
import '../../harness/mocks.dart';

/// Sequential id generator so created institution/asset/transaction get distinct
/// ids and references can be asserted.
class _SeqIdGenerator implements IdGenerator {
  int _n = 0;
  @override
  String newId() => 'id${++_n}';
}

void main() {
  late MockAssetRepository assets;
  late MockInstitutionRepository institutions;
  late MockTransactionRepository transactions;
  late ImportPortfolioCsvUseCase useCase;

  setUp(() {
    assets = MockAssetRepository();
    institutions = MockInstitutionRepository();
    transactions = MockTransactionRepository();
    useCase = ImportPortfolioCsvUseCase(
      assets,
      institutions,
      transactions,
      _SeqIdGenerator(),
    );
  });

  // Stubs every repo with empty state and successful saves.
  void stubEmpty() {
    when(assets.watchAll).thenAnswer((_) => Stream.value(const <Asset>[]));
    when(institutions.watchAll)
        .thenAnswer((_) => Stream.value(const <Institution>[]));
    when(() => assets.save(any())).thenAnswer((_) async => const Right(unit));
    when(() => institutions.save(any()))
        .thenAnswer((_) async => const Right(unit));
    when(() => transactions.save(any()))
        .thenAnswer((_) async => const Right(unit));
  }

  const header = 'ticker,name,kind,institution,quantity,price';

  group('parseRows', () {
    test('parses a row and defaults market/currency/operation/name', () {
      final result = useCase.parseRows('$header\nSOXX,,etfUs,Avenue,2,100');

      final rows = result.getOrElse(() => []);
      expect(rows, hasLength(1));
      final row = rows.single;
      expect(row.ticker, 'SOXX');
      expect(row.name, 'SOXX'); // empty name → ticker
      expect(row.kind, AssetKind.etfUs);
      expect(row.market, Market.us); // defaulted from kind
      expect(row.currency, Currency.usd);
      expect(row.operation, TransactionKind.buy);
      expect(row.quantity, 2);
      expect(row.unitPriceMajor, 100);
    });

    test('accepts a friendly kind label and fractional quantity', () {
      final result = useCase.parseRows(
        'ticker,kind,institution,quantity,price\n'
        'SOXX,ETF (US),Avenue,1.92012,233.91',
      );

      final row = result.getOrElse(() => []).single;
      expect(row.kind, AssetKind.etfUs);
      expect(row.quantity, closeTo(1.92012, 1e-9));
      expect(row.unitPriceMajor, closeTo(233.91, 1e-9));
    });

    test('parses Brazilian number grouping', () {
      final result = useCase.parseRows(
        'ticker,kind,institution,quantity,price\n'
        'VNQI,etfUs,Avenue,1,"1.234,56"',
      );

      expect(result.getOrElse(() => []).single.unitPriceMajor, 1234.56);
    });

    test('fails when a required column is missing', () {
      final result = useCase.parseRows('ticker,kind\nSOXX,etfUs');
      expect(result.isLeft(), isTrue);
      expect(result.swap().getOrElse(() => throw StateError('unexpected')), isA<ValidationFailure>());
    });

    test('fails on an unknown kind, tagging the row', () {
      final result = useCase.parseRows('$header\nSOXX,,banana,Avenue,2,100');
      final failure = result.swap().getOrElse(() => throw StateError('unexpected'));
      expect(failure, isA<ValidationFailure>());
      expect(failure.message, contains('Row 2'));
    });

    test('fails on an invalid number', () {
      final result = useCase.parseRows('$header\nSOXX,,etfUs,Avenue,abc,100');
      expect(result.isLeft(), isTrue);
    });
  });

  group('importRows', () {
    test('creates institution, asset and a buy transaction when none exist',
        () async {
      stubEmpty();

      final result = await useCase.call('$header\nSOXX,iShares,etfUs,Avenue,2,100');

      expect(result.isRight(), isTrue);
      final tally = result.getOrElse(() => throw StateError('unexpected'));
      expect(tally.institutionsCreated, 1);
      expect(tally.assetsCreated, 1);
      expect(tally.transactionsCreated, 1);

      final savedAsset =
          verify(() => assets.save(captureAny())).captured.single as Asset;
      expect(savedAsset.ticker, 'SOXX');
      expect(savedAsset.kind, AssetKind.etfUs);

      final tx = verify(() => transactions.save(captureAny())).captured.single
          as AssetTransaction;
      expect(tx.kind, TransactionKind.buy);
      expect(tx.quantity, 2);
      expect(tx.unitPrice.major, 100);
      expect(tx.amount.major, 200); // price * quantity
      expect(tx.assetId, savedAsset.id);
    });

    test('reuses an existing asset (by ticker) and institution (by name)',
        () async {
      when(assets.watchAll).thenAnswer(
        (_) => Stream.value([
          assetFactory(id: 'existing-a', ticker: 'SOXX', kind: AssetKind.etfUs),
        ]),
      );
      when(institutions.watchAll).thenAnswer(
        (_) => Stream.value([institutionFactory(id: 'existing-i', name: 'Avenue')]),
      );
      when(() => transactions.save(any()))
          .thenAnswer((_) async => const Right(unit));

      final result =
          await useCase.call('$header\nsoxx,iShares,etfUs,avenue,2,100');

      final tally = result.getOrElse(() => throw StateError('unexpected'));
      expect(tally.institutionsCreated, 0);
      expect(tally.assetsCreated, 0);
      expect(tally.transactionsCreated, 1);
      verifyNever(() => assets.save(any()));
      verifyNever(() => institutions.save(any()));

      final tx = verify(() => transactions.save(captureAny())).captured.single
          as AssetTransaction;
      expect(tx.assetId, 'existing-a');
      expect(tx.institutionId, 'existing-i');
    });

    test('builds a dividend with zero quantity and the given amount', () async {
      stubEmpty();

      final result = await useCase.call(
        'ticker,kind,institution,operation,amount\n'
        'IVV,etfUs,Avenue,dividend,15.50',
      );

      expect(result.isRight(), isTrue);
      final tx = verify(() => transactions.save(captureAny())).captured.single
          as AssetTransaction;
      expect(tx.kind, TransactionKind.dividend);
      expect(tx.quantity, 0);
      expect(tx.amount.major, 15.5);
    });

    test('stops and returns the failure when a save fails', () async {
      when(assets.watchAll).thenAnswer((_) => Stream.value(const <Asset>[]));
      when(institutions.watchAll)
          .thenAnswer((_) => Stream.value(const <Institution>[]));
      when(() => institutions.save(any()))
          .thenAnswer((_) async => const Right(unit));
      when(() => assets.save(any()))
          .thenAnswer((_) async => const Left(ServerFailure('boom')));

      final result = await useCase.call('$header\nSOXX,iShares,etfUs,Avenue,2,100');

      expect(result.isLeft(), isTrue);
      verifyNever(() => transactions.save(any()));
    });
  });
}
