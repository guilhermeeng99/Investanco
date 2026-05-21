import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/transactions/domain/entities/asset_transaction.dart';
import 'package:investanco/features/valuation/domain/fixed_income_cash_flows.dart';

import '../../harness/factories/transaction_factory.dart';

void main() {
  const brl = Currency.brl;

  AssetTransaction tx(TransactionKind kind, double price, DateTime date) =>
      transactionFactory(
        kind: kind,
        unitPrice: Money.fromMajor(price, brl),
        date: date,
      );

  test('buy → deposit (positive), sell → redemption (negative)', () {
    final flows = buildFixedIncomeCashFlows([
      tx(TransactionKind.buy, 3000, DateTime(2025, 11, 6)),
      tx(TransactionKind.sell, 500, DateTime(2025, 12)),
    ]);

    expect(flows.map((f) => f.date),
        [DateTime(2025, 11, 6), DateTime(2025, 12)]);
    expect(flows.map((f) => f.amount),
        [Money.fromMajor(3000, brl), Money.fromMajor(-500, brl)]);
  });

  test('orders flows oldest-first regardless of input order', () {
    final flows = buildFixedIncomeCashFlows([
      tx(TransactionKind.buy, 100, DateTime(2026, 3)),
      tx(TransactionKind.buy, 200, DateTime(2026)),
    ]);

    expect(flows.map((f) => f.date), [DateTime(2026), DateTime(2026, 3)]);
  });

  test('ignores dividends and empty input', () {
    expect(buildFixedIncomeCashFlows(const []), isEmpty);
    expect(
      buildFixedIncomeCashFlows([tx(TransactionKind.dividend, 0, DateTime(2026))]),
      isEmpty,
    );
  });
}
