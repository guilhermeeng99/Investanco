import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/database/app_database.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/features/quotes/data/market_cache_store_impl.dart';
import 'package:investanco/features/quotes/domain/entities/index_point.dart';

import '../../../harness/factories/index_point_factory.dart';
import '../../../harness/helpers.dart';

void main() {
  late AppDatabase db;
  late DriftMarketCacheStore store;

  setUp(() {
    db = memoryDatabase();
    store = DriftMarketCacheStore(db);
  });

  test('lastFxRate is null before anything is saved', () async {
    expect(await store.lastFxRate(Currency.usd, Currency.brl), isNull);
  });

  test('saveFxRate round-trips and upserts by pair (newest wins)', () async {
    await store.saveFxRate(Currency.usd, Currency.brl, 5.12);
    expect(await store.lastFxRate(Currency.usd, Currency.brl), 5.12);

    await store.saveFxRate(Currency.usd, Currency.brl, 5.40);
    expect(await store.lastFxRate(Currency.usd, Currency.brl), 5.40);
  });

  test('allIndexSeries groups saved points by index, oldest first', () async {
    await store.saveIndexSeries(EconomicIndex.cdi, [
      indexPointFactory(date: DateTime(2026, 1, 3), rate: 0.04),
      indexPointFactory(date: DateTime(2026, 1, 2), rate: 0.05),
    ]);
    await store.saveIndexSeries(EconomicIndex.ipca, [
      indexPointFactory(date: DateTime(2026), rate: 0.3),
    ]);

    final series = await store.allIndexSeries();

    expect(series.keys.toSet(), {EconomicIndex.cdi, EconomicIndex.ipca});
    expect(
      series[EconomicIndex.cdi]!.map((p) => p.date).toList(),
      [DateTime(2026, 1, 2), DateTime(2026, 1, 3)],
    );
    expect(series[EconomicIndex.ipca]!.single.rate, 0.3);
  });

  test('saveIndexSeries upserts by date and accumulates new dates', () async {
    await store.saveIndexSeries(EconomicIndex.cdi, [
      indexPointFactory(date: DateTime(2026, 1, 2), rate: 0.04),
    ]);
    await store.saveIndexSeries(EconomicIndex.cdi, [
      indexPointFactory(date: DateTime(2026, 1, 2), rate: 0.09), // revised
      indexPointFactory(date: DateTime(2026, 1, 3), rate: 0.05), // appended
    ]);

    final points = (await store.allIndexSeries())[EconomicIndex.cdi]!;
    expect(points.length, 2);
    expect(points.first.rate, 0.09);
    expect(points.last.date, DateTime(2026, 1, 3));
  });

  test('an empty series write is a no-op', () async {
    await store.saveIndexSeries(EconomicIndex.cdi, const []);
    expect(await store.allIndexSeries(), isEmpty);
  });

  test('clearUserData wipes the persisted FX + index caches', () async {
    await store.saveFxRate(Currency.usd, Currency.brl, 5);
    await store.saveIndexSeries(EconomicIndex.cdi, [indexPointFactory()]);

    await db.clearUserData();

    expect(await store.lastFxRate(Currency.usd, Currency.brl), isNull);
    expect(await store.allIndexSeries(), isEmpty);
  });
}
