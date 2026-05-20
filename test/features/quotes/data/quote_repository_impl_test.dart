import 'package:dartz/dartz.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/database/app_database.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/quotes/data/repositories/quote_repository_impl.dart';
import 'package:investanco/features/quotes/domain/datasources/quote_data_source.dart';
import 'package:investanco/features/quotes/domain/entities/quote.dart';

import '../../../harness/factories/asset_factory.dart';

class _FakeSource implements QuoteDataSource {
  _FakeSource(this.quotes, {this.fail = false});

  final List<Quote> quotes;
  final bool fail;

  @override
  bool supports(Asset asset) => true;

  @override
  Future<Either<Failure, List<Quote>>> fetch(List<Asset> assets) async =>
      fail ? const Left(NetworkFailure()) : Right(quotes);
}

void main() {
  late AppDatabase db;
  final now = DateTime(2026, 5, 20);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Quote quote() => Quote(
        assetId: 'a1',
        unitPrice: Money.fromMajor(10, Currency.brl),
        asOf: now,
        fetchedAt: now,
        source: QuoteSource.brapi,
      );

  test('refresh caches quotes; getCached returns them', () async {
    final repository = QuoteRepositoryImpl(db, [
      _FakeSource([quote()]),
    ]);

    final result = await repository.refresh([assetFactory()]);
    expect(result.isRight(), isTrue);

    final cached = await repository.getCached(['a1']);
    expect(cached.length, 1);
    expect(cached.first.unitPrice, Money.fromMajor(10, Currency.brl));
  });

  test('refresh returns a failure when every source fails', () async {
    final repository = QuoteRepositoryImpl(db, [
      _FakeSource([], fail: true),
    ]);

    final result = await repository.refresh([assetFactory()]);

    expect(result.isLeft(), isTrue);
  });

  test('getCached returns empty for unknown ids', () async {
    final repository = QuoteRepositoryImpl(db, [
      _FakeSource([quote()]),
    ]);

    expect(await repository.getCached([]), isEmpty);
    expect(await repository.getCached(['nope']), isEmpty);
  });
}
