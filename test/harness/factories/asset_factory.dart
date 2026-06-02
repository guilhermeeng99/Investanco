import 'package:investanco/core/money/currency.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';

/// Test factory for [Asset]. Never hardcode entities in tests.
Asset assetFactory({
  String id = 'a1',
  String ticker = 'PETR4',
  String name = 'Petrobras PN',
  AssetKind kind = AssetKind.stockBr,
  Market market = Market.br,
  Currency currency = Currency.brl,
  String? institutionId = 'i1',
  Map<String, String> metadata = const {},
  DateTime? createdAt,
}) {
  return Asset(
    id: id,
    ticker: ticker,
    name: name,
    kind: kind,
    market: market,
    currency: currency,
    institutionId: institutionId,
    metadata: metadata,
    createdAt: createdAt ?? DateTime(2026),
  );
}
