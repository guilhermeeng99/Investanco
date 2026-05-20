import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/quotes/domain/datasources/quote_data_source.dart';
import 'package:investanco/features/quotes/domain/entities/quote.dart';

/// Prices Tesouro Direto bonds via B3's public market endpoint. A single request
/// returns every bond; each held treasury asset is matched to a bond by name and
/// priced at its redemption unit value (`untrRedVal`) — what the holder receives
/// today, so the right figure for current valuation. See `docs/specs/quotes.md`.
class TesouroDiretoDataSource implements QuoteDataSource {
  /// Creates the adapter over [_dio].
  const TesouroDiretoDataSource(this._dio);

  final Dio _dio;

  static const _endpoint =
      'https://www.tesourodireto.com.br/json/br/com/b3/tesourodireto'
      '/service/api/treasury/getMarket';

  @override
  bool supports(Asset asset) => asset.kind == AssetKind.treasury;

  @override
  Future<Either<Failure, List<Quote>>> fetch(List<Asset> assets) async {
    final supported = assets.where(supports).toList();
    if (supported.isEmpty) return const Right([]);

    try {
      final response = await _dio.get<Map<String, dynamic>>(_endpoint);
      final priceByName = _redemptionPricesByName(response.data);
      final now = DateTime.now();
      final quotes = <Quote>[];
      for (final asset in supported) {
        final price = priceByName[_matchKey(asset)];
        if (price == null) continue;
        quotes.add(
          Quote(
            assetId: asset.id,
            unitPrice: Money.fromMajor(price, asset.currency),
            asOf: now,
            fetchedAt: now,
            source: QuoteSource.tesouro,
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

  /// Redemption unit value (`untrRedVal`) of every bond, keyed by normalized name.
  Map<String, double> _redemptionPricesByName(Map<String, dynamic>? data) {
    final response = data?['response'] as Map<String, dynamic>?;
    final list = (response?['TrsrBdTradgList'] as List<dynamic>?) ?? const [];
    final prices = <String, double>{};
    for (final raw in list) {
      final bond = (raw as Map<String, dynamic>)['TrsrBd'] as Map<String, dynamic>?;
      final name = bond?['nm'] as String?;
      final price = (bond?['untrRedVal'] as num?)?.toDouble();
      if (name == null || price == null) continue;
      prices[_normalize(name)] = price;
    }
    return prices;
  }

  /// Prefers an explicit `tesouroName`; falls back to the asset's display name
  /// so a well-named asset prices without extra setup.
  String _matchKey(Asset asset) {
    final tesouroName = asset.metadata['tesouroName'];
    return _normalize(
      tesouroName == null || tesouroName.isEmpty ? asset.name : tesouroName,
    );
  }

  /// Tolerant comparison key: trimmed, lowercased, single-spaced.
  String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
