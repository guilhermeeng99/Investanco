import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/holdings/domain/entities/holding.dart';

/// Test factory for [Holding]. Defaults to 10 units at R$10 average cost.
/// Never hardcode entities in tests.
Holding holdingFactory({
  String assetId = 'a1',
  String institutionId = 'i1',
  double quantity = 10,
  Money? avgCost,
  Money? realizedPL,
  Money? dividends,
}) {
  const brl = Currency.brl;
  return Holding(
    assetId: assetId,
    institutionId: institutionId,
    quantity: quantity,
    avgCost: avgCost ?? const Money(1000, brl),
    realizedPL: realizedPL ?? const Money.zero(brl),
    dividends: dividends ?? const Money.zero(brl),
  );
}
