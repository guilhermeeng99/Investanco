import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/quotes/domain/datasources/quote_data_source.dart';
import 'package:investanco/features/quotes/domain/entities/quote.dart';

/// Prices Brazilian equities, FIIs, ETFs and BDRs via brapi.dev. Tickers are
/// batched into a single request. Crypto is **not** handled here: brapi's free
/// `/quote/{ticker}` resolves `BTC` to a US ETF, not the coin — crypto goes to
/// `CoinGeckoQuoteDataSource` instead. See `docs/specs/quotes.md`.
class BrapiQuoteDataSource implements QuoteDataSource {
  /// Creates the adapter. [token] defaults to the `BRAPI_TOKEN` dart-define
  /// (empty uses the free tier, limited to popular tickers).
  const BrapiQuoteDataSource(
    this._dio, {
    this.token = const String.fromEnvironment('BRAPI_TOKEN'),
  });

  final Dio _dio;

  /// brapi API token (optional).
  final String token;

  @override
  bool supports(Asset asset) => switch (asset.kind) {
        AssetKind.stockBr ||
        AssetKind.fiiBr ||
        AssetKind.etfBr ||
        AssetKind.bdrBr =>
          true,
        _ => false,
      };

  @override
  Future<Either<Failure, List<Quote>>> fetch(List<Asset> assets) async {
    final supported = assets.where(supports).toList();
    if (supported.isEmpty) return const Right([]);

    final byTicker = {for (final a in supported) a.ticker.toUpperCase(): a};
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://brapi.dev/api/quote/${byTicker.keys.join(',')}',
        queryParameters: token.isEmpty ? null : {'token': token},
      );
      final results = (response.data?['results'] as List<dynamic>?) ?? const [];
      final now = DateTime.now();
      final quotes = <Quote>[];
      for (final raw in results) {
        final map = raw as Map<String, dynamic>;
        final asset = byTicker[(map['symbol'] as String?)?.toUpperCase()];
        final price = (map['regularMarketPrice'] as num?)?.toDouble();
        if (asset == null || price == null) continue;
        final previous =
            (map['regularMarketPreviousClose'] as num?)?.toDouble();
        quotes.add(
          Quote(
            assetId: asset.id,
            unitPrice: Money.fromMajor(price, asset.currency),
            previousClose: previous == null
                ? null
                : Money.fromMajor(previous, asset.currency),
            asOf: now,
            fetchedAt: now,
            source: QuoteSource.brapi,
          ),
        );
      }
      return Right(quotes);
    } on DioException {
      return const Left(NetworkFailure());
    } on Object {
      return const Left(ParseFailure());
    }
  }
}
