import 'package:investanco/core/money/currency.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';

/// The usual (market, currency) pairing for an [AssetKind]: US kinds → US/USD,
/// BR kinds → BR/BRL, crypto → Global/USD. Used to pre-fill the asset form and
/// to default missing columns on CSV import. Both remain user-editable.
(Market, Currency) assetKindDefaults(AssetKind kind) => switch (kind) {
      AssetKind.stockBr ||
      AssetKind.fiiBr ||
      AssetKind.etfBr ||
      AssetKind.bdrBr =>
        (Market.br, Currency.brl),
      AssetKind.stockUs || AssetKind.etfUs => (Market.us, Currency.usd),
      AssetKind.crypto => (Market.global, Currency.usd),
      AssetKind.treasury ||
      AssetKind.fixedIncome ||
      AssetKind.fund ||
      AssetKind.cash =>
        (Market.br, Currency.brl),
    };
