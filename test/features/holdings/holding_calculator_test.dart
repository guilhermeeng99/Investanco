import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/holdings/domain/holding_calculator.dart';
import 'package:investanco/features/transactions/domain/entities/asset_transaction.dart';

import '../../harness/factories/transaction_factory.dart';

void main() {
  const calculator = HoldingCalculator();
  const brl = Currency.brl;

  test('single buy sets quantity and average cost (fees included)', () {
    final holding = calculator.derive([
      transactionFactory(
        quantity: 10,
        unitPrice: Money.fromMajor(10, brl),
        fees: Money.fromMajor(5, brl),
      ),
    ]).single;

    expect(holding.quantity, 10);
    // (10 * 1000 + 500) / 10 = 1050 minor units = R$10.50
    expect(holding.avgCost, const Money(1050, brl));
  });

  test('weighted average across two buys', () {
    final holding = calculator.derive([
      transactionFactory(
        id: 't1',
        quantity: 10,
        unitPrice: Money.fromMajor(10, brl),
        date: DateTime(2026, 1, 1),
      ),
      transactionFactory(
        id: 't2',
        quantity: 10,
        unitPrice: Money.fromMajor(20, brl),
        date: DateTime(2026, 1, 2),
      ),
    ]).single;

    expect(holding.quantity, 20);
    expect(holding.avgCost, const Money(1500, brl)); // R$15.00
  });

  test('sell realizes profit, reduces quantity, keeps average cost', () {
    final holding = calculator.derive([
      transactionFactory(
        id: 't1',
        quantity: 10,
        unitPrice: Money.fromMajor(10, brl),
        date: DateTime(2026, 1, 1),
      ),
      transactionFactory(
        id: 't2',
        kind: TransactionKind.sell,
        quantity: 4,
        unitPrice: Money.fromMajor(15, brl),
        date: DateTime(2026, 1, 2),
      ),
    ]).single;

    expect(holding.quantity, 6);
    expect(holding.avgCost, const Money(1000, brl));
    expect(holding.realizedPL, const Money(2000, brl)); // (1500-1000)*4
  });

  test('selling everything closes the holding but keeps average cost', () {
    final holding = calculator.derive([
      transactionFactory(
        id: 't1',
        quantity: 5,
        unitPrice: Money.fromMajor(10, brl),
        date: DateTime(2026, 1, 1),
      ),
      transactionFactory(
        id: 't2',
        kind: TransactionKind.sell,
        quantity: 5,
        unitPrice: Money.fromMajor(12, brl),
        date: DateTime(2026, 1, 2),
      ),
    ]).single;

    expect(holding.quantity, 0);
    expect(holding.isClosed, isTrue);
    expect(holding.avgCost, const Money(1000, brl));
  });

  test('dividends accumulate without changing quantity', () {
    final holding = calculator.derive([
      transactionFactory(
        id: 't1',
        quantity: 10,
        unitPrice: Money.fromMajor(10, brl),
        date: DateTime(2026, 1, 1),
      ),
      transactionFactory(
        id: 't2',
        kind: TransactionKind.dividend,
        quantity: 0,
        amount: Money.fromMajor(7.5, brl),
        date: DateTime(2026, 1, 2),
      ),
    ]).single;

    expect(holding.quantity, 10);
    expect(holding.dividends, const Money(750, brl));
  });

  test('same asset at two institutions yields two holdings', () {
    final holdings = calculator.derive([
      transactionFactory(id: 't1', institutionId: 'i1'),
      transactionFactory(id: 't2', institutionId: 'i2'),
    ]);

    expect(holdings.length, 2);
  });
}
