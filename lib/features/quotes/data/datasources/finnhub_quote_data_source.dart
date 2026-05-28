import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/core/network/guarded_fetch.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/quotes/domain/datasources/quote_data_source.dart';
import 'package:investanco/features/quotes/domain/entities/quote.dart';

/// Prices US equities/ETFs via Finnhub. Unlike Yahoo/Stooq, Finnhub sends CORS
/// headers, so it works from the browser. The free API token is baked in at
/// build time via the `FINNHUB_TOKEN` dart-define (CI passes it from a GitHub
/// secret); without one, US holdings simply show their cost basis.
/// See `docs/specs/quotes.md`.
class FinnhubQuoteDataSource implements QuoteDataSource {
  /// Creates the adapter. [token] defaults to the `FINNHUB_TOKEN` dart-define.
  const FinnhubQuoteDataSource(
    this._dio, {
    this.token = const String.fromEnvironment('FINNHUB_TOKEN'),
  });

  final Dio _dio;

  /// Finnhub API token. Empty disables US pricing.
  final String token;

  @override
  bool supports(Asset asset) =>
      asset.kind == AssetKind.stockUs || asset.kind == AssetKind.etfUs;

  @override
  Future<Either<Failure, List<Quote>>> fetch(List<Asset> assets) async {
    final supported = assets.where(supports).toList();
    if (supported.isEmpty || token.isEmpty) return const Right([]);

    // Wrap the batch in guardedFetch so a malformed payload surfaces as a
    // ParseFailure instead of being silently swallowed (the old `on Object`
    // masked cast/type bugs). Per-ticker transport errors are still tolerated
    // inside _fetchOne so one unreachable symbol doesn't lose the batch — and
    // when every symbol fails, the loop simply yields an empty list (US
    // holdings then show cost basis), never a hard failure.
    return guardedFetch(() async {
      final now = DateTime.now();
      final quotes = <Quote>[];
      for (final asset in supported) {
        final quote = await _fetchOne(asset, now);
        if (quote != null) quotes.add(quote);
      }
      return Right(quotes);
    });
  }

  Future<Quote?> _fetchOne(Asset asset, DateTime now) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://finnhub.io/api/v1/quote',
        queryParameters: {'symbol': asset.ticker, 'token': token},
      );
      final data = response.data;
      final current = (data?['c'] as num?)?.toDouble();
      if (current == null || current == 0) return null;
      final previous = (data?['pc'] as num?)?.toDouble();
      return Quote(
        assetId: asset.id,
        unitPrice: Money.fromMajor(current, asset.currency),
        previousClose: previous == null || previous == 0
            ? null
            : Money.fromMajor(previous, asset.currency),
        asOf: now,
        fetchedAt: now,
        source: QuoteSource.finnhub,
      );
    } on DioException {
      // Transient transport failure for this one symbol — skip it, keep the
      // rest of the batch. A parse/type error is NOT caught here: it propagates
      // to guardedFetch and becomes a ParseFailure rather than a silent drop.
      return null;
    }
  }
}
