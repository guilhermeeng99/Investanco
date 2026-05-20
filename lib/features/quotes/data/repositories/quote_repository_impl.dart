import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:investanco/core/database/app_database.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/quotes/domain/datasources/quote_data_source.dart';
import 'package:investanco/features/quotes/domain/entities/quote.dart';
import 'package:investanco/features/quotes/domain/repositories/quote_repository.dart';

/// Caches quotes in Drift and routes refreshes to the registered data sources.
class QuoteRepositoryImpl implements QuoteRepository {
  /// Creates the repository over the database and the ordered [_sources].
  const QuoteRepositoryImpl(this._db, this._sources);

  final AppDatabase _db;
  final List<QuoteDataSource> _sources;

  @override
  Future<List<Quote>> getCached(List<String> assetIds) async {
    if (assetIds.isEmpty) return [];
    final rows = await (_db.select(_db.quotes)
          ..where((t) => t.assetId.isIn(assetIds)))
        .get();
    return rows.map(_toQuote).toList();
  }

  @override
  Future<Either<Failure, List<Quote>>> refresh(List<Asset> assets) async {
    final collected = <Quote>[];
    var attempted = false;
    var succeeded = false;

    for (final source in _sources) {
      final supported = assets.where(source.supports).toList();
      if (supported.isEmpty) continue;
      attempted = true;
      final result = await source.fetch(supported);
      result.fold((_) {}, (quotes) {
        collected.addAll(quotes);
        succeeded = true;
      });
    }

    if (collected.isNotEmpty) await _cache(collected);
    if (attempted && !succeeded) return const Left(NetworkFailure());
    return Right(collected);
  }

  Future<void> _cache(List<Quote> quotes) async {
    await _db.batch((batch) {
      for (final quote in quotes) {
        batch.insert(
          _db.quotes,
          _toCompanion(quote),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Quote _toQuote(QuoteRow row) {
    final currency = Currency.values.byName(row.currency);
    final previous = row.previousCloseMinor;
    return Quote(
      assetId: row.assetId,
      unitPrice: Money(row.unitPriceMinor, currency),
      previousClose: previous == null ? null : Money(previous, currency),
      asOf: row.asOf,
      fetchedAt: row.fetchedAt,
      source: QuoteSource.values.byName(row.source),
    );
  }

  QuotesCompanion _toCompanion(Quote quote) {
    return QuotesCompanion(
      assetId: Value(quote.assetId),
      unitPriceMinor: Value(quote.unitPrice.minorUnits),
      previousCloseMinor: Value(quote.previousClose?.minorUnits),
      currency: Value(quote.unitPrice.currency.name),
      asOf: Value(quote.asOf),
      fetchedAt: Value(quote.fetchedAt),
      source: Value(quote.source.name),
    );
  }
}
