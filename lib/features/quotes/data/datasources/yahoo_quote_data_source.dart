import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/quotes/domain/datasources/quote_data_source.dart';
import 'package:investanco/features/quotes/domain/entities/quote.dart';

/// Prices US equities and ETFs (Avenue holdings) via Yahoo Finance's public
/// chart endpoint. One request per symbol; a failed symbol is skipped so the
/// rest still resolve. See `docs/specs/quotes.md`.
class YahooQuoteDataSource implements QuoteDataSource {
  /// Creates the adapter.
  const YahooQuoteDataSource(this._dio);

  final Dio _dio;

  @override
  bool supports(Asset asset) =>
      asset.kind == AssetKind.stockUs || asset.kind == AssetKind.etfUs;

  @override
  Future<Either<Failure, List<Quote>>> fetch(List<Asset> assets) async {
    final supported = assets.where(supports).toList();
    if (supported.isEmpty) return const Right([]);

    final now = DateTime.now();
    final quotes = <Quote>[];
    for (final asset in supported) {
      final quote = await _fetchOne(asset, now);
      if (quote != null) quotes.add(quote);
    }
    return Right(quotes);
  }

  Future<Quote?> _fetchOne(Asset asset, DateTime now) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://query1.finance.yahoo.com/v8/finance/chart/${asset.ticker}',
      );
      final results =
          (response.data?['chart'] as Map<String, dynamic>?)?['result']
              as List<dynamic>?;
      if (results == null || results.isEmpty) return null;
      final meta = (results.first as Map<String, dynamic>)['meta']
          as Map<String, dynamic>?;
      final price = (meta?['regularMarketPrice'] as num?)?.toDouble();
      if (price == null) return null;
      final previous = (meta?['chartPreviousClose'] as num?)?.toDouble() ??
          (meta?['previousClose'] as num?)?.toDouble();
      return Quote(
        assetId: asset.id,
        unitPrice: Money.fromMajor(price, asset.currency),
        previousClose:
            previous == null ? null : Money.fromMajor(previous, asset.currency),
        asOf: now,
        fetchedAt: now,
        source: QuoteSource.yahoo,
      );
    } on Object {
      return null;
    }
  }
}
