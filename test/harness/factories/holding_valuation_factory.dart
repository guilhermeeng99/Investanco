import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/valuation/domain/entities/holding_valuation.dart';

/// Test factory for [HoldingValuation]. Defaults to a R$100 BRL position valued
/// at R$80 cost (R$20 unrealized). Native value mirrors the base unless given.
/// Never hardcode entities in tests.
HoldingValuation holdingValuationFactory({
  String assetId = 'a1',
  String institutionId = 'i1',
  AssetKind assetKind = AssetKind.etfUs,
  double quantity = 1,
  Money? marketValueBase,
  Money? marketValueNative,
  Money? investedBase,
  Money? unrealizedPL,
  Money? totalPL,
  double returnPct = 0,
  Money? dayChangeBase,
  bool priceStale = false,
  bool fxMissing = false,
}) {
  const brl = Currency.brl;
  final base = marketValueBase ?? Money.fromMajor(100, brl);
  final invested = investedBase ?? Money.fromMajor(80, brl);
  final pl = unrealizedPL ?? (base - invested);
  return HoldingValuation(
    assetId: assetId,
    institutionId: institutionId,
    assetKind: assetKind,
    quantity: quantity,
    marketValueBase: base,
    marketValueNative: marketValueNative ?? base,
    investedBase: invested,
    unrealizedPL: pl,
    totalPL: totalPL ?? pl,
    returnPct: returnPct,
    dayChangeBase: dayChangeBase ?? const Money.zero(brl),
    priceStale: priceStale,
    fxMissing: fxMissing,
  );
}
