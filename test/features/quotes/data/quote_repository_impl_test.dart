import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/database/app_database.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/quotes/data/repositories/quote_repository_impl.dart';

import '../../../harness/factories/asset_factory.dart';
import '../../../harness/factories/quote_factory.dart';
import '../../../harness/helpers.dart';
import '../../../harness/mocks.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDatabase());

  test('refresh caches quotes; getCached returns them', () async {
    final repository = QuoteRepositoryImpl(db, [
      FakeQuoteDataSource([quoteFactory()]),
    ]);

    final result = await repository.refresh([assetFactory()]);
    expect(result.isRight(), isTrue);

    final cached = (await repository.getCached(['a1'])).getOrElse(() => const []);
    expect(cached.length, 1);
    expect(cached.first.unitPrice, Money.fromMajor(10, Currency.brl));
  });

  test('refresh returns a failure when every source fails', () async {
    final repository = QuoteRepositoryImpl(db, [
      FakeQuoteDataSource([], fail: true),
    ]);

    final result = await repository.refresh([assetFactory()]);

    expect(result.isLeft(), isTrue);
  });

  test('getCached returns empty for unknown ids', () async {
    final repository = QuoteRepositoryImpl(db, [
      FakeQuoteDataSource([quoteFactory()]),
    ]);

    expect((await repository.getCached([])).getOrElse(() => const []), isEmpty);
    expect(
      (await repository.getCached(['nope'])).getOrElse(() => const []),
      isEmpty,
    );
  });

  test('lastFetchedAt returns the newest fetchedAt among the given ids',
      () async {
    final repository = QuoteRepositoryImpl(db, [
      FakeQuoteDataSource([
        quoteFactory(assetId: 'a1', fetchedAt: DateTime(2026, 5, 1)),
        quoteFactory(assetId: 'a2', fetchedAt: DateTime(2026, 5, 10)),
      ]),
    ]);
    await repository.refresh([assetFactory()]);

    expect(await repository.lastFetchedAt(['a1', 'a2']), DateTime(2026, 5, 10));
    expect(await repository.lastFetchedAt(['a1']), DateTime(2026, 5, 1));
    expect(await repository.lastFetchedAt(['nope']), isNull);
    expect(await repository.lastFetchedAt([]), isNull);
  });
}
