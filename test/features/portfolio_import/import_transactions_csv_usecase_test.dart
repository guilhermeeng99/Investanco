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
      final row = parse('ticker,institution,quantity,price\nSOXX,Avenue,2,100')
          .single;
      expect(row.operation, TransactionKind.buy);
      final now = DateTime.now();
      expect(row.date, DateTime(now.year, now.month, now.day));
    });

    test('fails when the institution column is missing', () {
      expect(useCase.parseRows('ticker,quantity,price\nSOXX,2,100').isLeft(),
          isTrue);
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
      expect(useCase.parseRows('$header\nSOXX,Avenue,buy,0,100').isLeft(),
          isTrue);
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
      when(institutions.watchAll)
          .thenAnswer((_) => Stream.value(existingInstitutions));
      return useCase.previewRows(parse(csv));
    }

    test('flags a missing asset and blocks import', () async {
      final result = await preview('$header\nSOXX,Avenue,buy,2,100');
      expect(result.rows.single.assetExists, isFalse);
      expect(result.missingTickers, ['SOXX']);
      expect(result.canImport, isFalse);
    });

    test('allows import when the asset exists; flags new institution',
        () async {
      final result = await preview(
        '$header\nSOXX,Avenue,buy,2,100',
        existingAssets: [assetFactory(ticker: 'SOXX')],
      );
      expect(result.rows.single.assetExists, isTrue);
      expect(result.rows.single.institutionIsNew, isTrue);
      expect(result.canImport, isTrue);
      expect(result.newInstitutionCount, 1);
    });

    test('missingTickers is distinct', () async {
      final result = await preview(
        '$header\nSOXX,Avenue,buy,2,100\nSOXX,Avenue,buy,1,110',
      );
      expect(result.missingTickers, ['SOXX']);
    });
  });

  group('importRows', () {
    test('creates a transaction and auto-creates the institution in the '
        "asset's currency", () async {
      when(assets.watchAll).thenAnswer(
        (_) => Stream.value([assetFactory(ticker: 'SOXX', currency: Currency.usd)]),
      );
      when(institutions.watchAll)
          .thenAnswer((_) => Stream.value(const <Institution>[]));
      when(() => institutions.save(any()))
          .thenAnswer((_) async => const Right(unit));
      when(() => transactions.save(any()))
          .thenAnswer((_) async => const Right(unit));

      final result =
          await useCase.importRows(parse('$header\nSOXX,Avenue,buy,2,100'));

      final tally = result.getOrElse(() => throw StateError('unexpected'));
      expect(tally.transactionsCreated, 1);
      expect(tally.institutionsCreated, 1);
      final savedInstitution = verify(() => institutions.save(captureAny()))
          .captured
          .single as Institution;
      expect(savedInstitution.name, 'Avenue');
      expect(savedInstitution.currency, Currency.usd); // from the asset
    });

    test('reuses an existing institution (by name, case-insensitive)',
        () async {
      when(assets.watchAll).thenAnswer(
        (_) => Stream.value([assetFactory(ticker: 'SOXX')]),
      );
      when(institutions.watchAll).thenAnswer(
        (_) => Stream.value([institutionFactory(name: 'Avenue')]),
      );
      when(() => transactions.save(any()))
          .thenAnswer((_) async => const Right(unit));

      final result =
          await useCase.importRows(parse('$header\nSOXX,avenue,buy,2,100'));

      expect(result.getOrElse(() => throw StateError('x')).institutionsCreated,
          0);
      verifyNever(() => institutions.save(any()));
    });

    test('returns a ValidationFailure when the asset does not exist', () async {
      when(assets.watchAll).thenAnswer((_) => Stream.value(const <Asset>[]));
      when(institutions.watchAll)
          .thenAnswer((_) => Stream.value(const <Institution>[]));

      final result =
          await useCase.importRows(parse('$header\nSOXX,Avenue,buy,2,100'));

      expect(result.swap().getOrElse(() => throw StateError('x')),
          isA<ValidationFailure>());
      verifyNever(() => transactions.save(any()));
    });

    test('returns a CacheFailure when reading existing data fails', () async {
      when(assets.watchAll)
          .thenAnswer((_) => Stream.error(Exception('db down')));
      when(institutions.watchAll)
          .thenAnswer((_) => Stream.value(const <Institution>[]));

      final result =
          await useCase.importRows(parse('$header\nSOXX,Avenue,buy,2,100'));

      expect(result.swap().getOrElse(() => throw StateError('x')),
          isA<CacheFailure>());
    });
  });
}
