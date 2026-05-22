import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/features/assets/domain/asset_kind_defaults.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';

void main() {
  test('BR market kinds default to (br, brl)', () {
    for (final kind in [
      AssetKind.stockBr,
      AssetKind.fiiBr,
      AssetKind.etfBr,
      AssetKind.bdrBr,
    ]) {
      expect(assetKindDefaults(kind), (Market.br, Currency.brl), reason: '$kind');
    }
  });

  test('US market kinds default to (us, usd)', () {
    for (final kind in [AssetKind.stockUs, AssetKind.etfUs]) {
      expect(assetKindDefaults(kind), (Market.us, Currency.usd), reason: '$kind');
    }
  });

  test(r'crypto defaults to (global, brl) — BR users buy coins in R$', () {
    expect(assetKindDefaults(AssetKind.crypto), (Market.global, Currency.brl));
  });

  test('treasury / fixedIncome / fund / cash default to (br, brl)', () {
    for (final kind in [
      AssetKind.treasury,
      AssetKind.fixedIncome,
      AssetKind.fund,
      AssetKind.cash,
    ]) {
      expect(assetKindDefaults(kind), (Market.br, Currency.brl), reason: '$kind');
    }
  });

  test('every AssetKind resolves a default (switch stays exhaustive)', () {
    for (final kind in AssetKind.values) {
      expect(() => assetKindDefaults(kind), returnsNormally, reason: '$kind');
    }
  });
}
