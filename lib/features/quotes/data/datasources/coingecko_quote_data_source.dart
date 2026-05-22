import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/core/network/guarded_fetch.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/quotes/domain/datasources/quote_data_source.dart';
import 'package:investanco/features/quotes/domain/entities/quote.dart';

/// Prices crypto via CoinGecko's free, keyless `simple/price` endpoint.
///
/// brapi cannot do this: its free tier rejects `/v2/crypto`, and `/quote/BTC`
/// resolves to a US ETF literally named "BTC" (Grayscale Bitcoin Mini Trust),
/// not the coin — which silently mispriced every holding. CoinGecko quotes the
/// coin directly in the asset's own currency (BRL or USD), so no FX guess is
/// needed and a BR user who bought via Nubank in R$ sees prices in R$.
///
/// CoinGecko keys coins by *id* (e.g. `bitcoin`), not ticker (`BTC`). The id is
/// taken from `asset.metadata['coingeckoId']` when present, else a built-in map
/// for common coins, else the lowercased ticker as a last resort.
/// See `docs/specs/quotes.md`.
class CoinGeckoQuoteDataSource implements QuoteDataSource {
  /// Creates the adapter over [_dio].
  const CoinGeckoQuoteDataSource(this._dio);

  final Dio _dio;

  /// Ticker → CoinGecko id, for coins whose id differs from the lowercased
  /// ticker. Extend as needed; `metadata['coingeckoId']` overrides this.
  static const _idByTicker = {
    'BTC': 'bitcoin',
    'ETH': 'ethereum',
    'USDT': 'tether',
    'USDC': 'usd-coin',
    'BNB': 'binancecoin',
    'SOL': 'solana',
    'XRP': 'ripple',
    'ADA': 'cardano',
    'DOGE': 'dogecoin',
    'AVAX': 'avalanche-2',
    'MATIC': 'matic-network',
    'DOT': 'polkadot',
    'LTC': 'litecoin',
    'LINK': 'chainlink',
  };

  @override
  bool supports(Asset asset) => asset.kind == AssetKind.crypto;

  @override
  Future<Either<Failure, List<Quote>>> fetch(List<Asset> assets) async {
    final supported = assets.where(supports).toList();
    if (supported.isEmpty) return const Right([]);

    final ids = supported.map(_coinId).toSet().join(',');
    final vsCurrencies =
        supported.map((a) => a.currency.name).toSet().join(',');
    return guardedFetch(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.coingecko.com/api/v3/simple/price',
        queryParameters: {
          'ids': ids,
          'vs_currencies': vsCurrencies,
          'include_24hr_change': 'true',
        },
      );
      final data = response.data ?? const {};
      final now = DateTime.now();
      final quotes = <Quote>[];
      for (final asset in supported) {
        final quote = _parse(asset, data[_coinId(asset)], now);
        if (quote != null) quotes.add(quote);
      }
      return Right(quotes);
    });
  }

  /// CoinGecko id for [asset]: explicit metadata, then the built-in map, then
  /// the lowercased ticker.
  String _coinId(Asset asset) {
    final override = asset.metadata['coingeckoId'];
    if (override != null && override.isNotEmpty) return override;
    return _idByTicker[asset.ticker.toUpperCase()] ??
        asset.ticker.toLowerCase();
  }

  /// Builds a quote from a per-coin map like
  /// `{ "brl": 387869, "brl_24h_change": 0.05 }`. The price is read in the
  /// asset's currency; previous close is derived from the 24h % change because
  /// the endpoint reports no absolute previous value.
  Quote? _parse(Asset asset, dynamic raw, DateTime now) {
    if (raw is! Map<String, dynamic>) return null;
    final vs = asset.currency.name;
    final price = (raw[vs] as num?)?.toDouble();
    if (price == null) return null;
    final change = (raw['${vs}_24h_change'] as num?)?.toDouble();
    final previous = change == null ? null : price / (1 + change / 100);
    return Quote(
      assetId: asset.id,
      unitPrice: Money.fromMajor(price, asset.currency),
      previousClose:
          previous == null ? null : Money.fromMajor(previous, asset.currency),
      asOf: now,
      fetchedAt: now,
      source: QuoteSource.coingecko,
    );
  }
}
