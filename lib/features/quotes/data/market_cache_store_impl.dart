import 'package:drift/drift.dart';
import 'package:investanco/core/database/app_database.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/features/quotes/domain/entities/index_point.dart';
import 'package:investanco/features/quotes/domain/market_cache_store.dart';

/// Drift-backed [MarketCacheStore]. FX rates are stored one row per pair; index
/// observations one row per (index, date), so a series accumulates across
/// refreshes and a single read returns the whole history for an index.
class DriftMarketCacheStore implements MarketCacheStore {
  /// Creates the store over [_db].
  const DriftMarketCacheStore(this._db);

  final AppDatabase _db;

  String _pairKey(Currency from, Currency to) => '${from.code}->${to.code}';

  @override
  Future<double?> lastFxRate(Currency from, Currency to) async {
    final row = await (_db.select(_db.fxRates)
          ..where((t) => t.pair.equals(_pairKey(from, to))))
        .getSingleOrNull();
    return row?.rate;
  }

  @override
  Future<void> saveFxRate(Currency from, Currency to, double rate) {
    // `insertOrReplace` (INSERT OR REPLACE), like the quotes cache — broadly
    // supported, including the sqlite3 WASM build used on web.
    return _db.into(_db.fxRates).insert(
          FxRatesCompanion.insert(
            pair: _pairKey(from, to),
            rate: rate,
            fetchedAt: DateTime.now(),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  @override
  Future<Map<EconomicIndex, List<IndexPoint>>> allIndexSeries() async {
    final rows = await (_db.select(_db.indexPoints)
          ..orderBy([(t) => OrderingTerm(expression: t.date)]))
        .get();
    final byIndex = <EconomicIndex, List<IndexPoint>>{};
    for (final row in rows) {
      final index = _indexByName(row.index);
      if (index == null) continue; // tolerate an unknown stored name
      (byIndex[index] ??= []).add(IndexPoint(date: row.date, rate: row.rate));
    }
    return byIndex;
  }

  @override
  Future<void> saveIndexSeries(EconomicIndex index, List<IndexPoint> points) {
    if (points.isEmpty) return Future.value();
    return _db.batch((batch) {
      for (final point in points) {
        batch.insert(
          _db.indexPoints,
          IndexPointsCompanion.insert(
            index: index.name,
            date: point.date,
            rate: point.rate,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  EconomicIndex? _indexByName(String name) {
    for (final value in EconomicIndex.values) {
      if (value.name == name) return value;
    }
    return null;
  }
}
