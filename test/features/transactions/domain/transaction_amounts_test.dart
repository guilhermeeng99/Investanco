import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/transactions/domain/entities/asset_transaction.dart';
import 'package:investanco/features/transactions/domain/transaction_amounts.dart';

void main() {
  test('a buy derives amount = unitPrice * quantity', () {
    final m = resolveTransactionAmounts(
      kind: TransactionKind.buy,
      quantity: 2,
      unitPrice: Money.fromMajor(100, Currency.usd),
      amount: const Money.zero(Currency.usd),
      currency: Currency.usd,
    );

    expect(m.quantity, 2);
    expect(m.unitPrice, Money.fromMajor(100, Currency.usd));
    expect(m.amount, Money.fromMajor(200, Currency.usd));
  });

  test('a sell derives its amount the same way', () {
    final m = resolveTransactionAmounts(
      kind: TransactionKind.sell,
      quantity: 3,
      unitPrice: Money.fromMajor(10, Currency.brl),
      amount: const Money.zero(Currency.brl),
      currency: Currency.brl,
    );

    expect(m.amount, Money.fromMajor(30, Currency.brl));
  });

  test('a dividend keeps its amount and zeroes quantity + unit price', () {
    final m = resolveTransactionAmounts(
      kind: TransactionKind.dividend,
      quantity: 5,
      unitPrice: Money.fromMajor(99, Currency.brl),
      amount: Money.fromMajor(15, Currency.brl),
      currency: Currency.brl,
    );

    expect(m.quantity, 0);
    expect(m.unitPrice, const Money.zero(Currency.brl));
    expect(m.amount, Money.fromMajor(15, Currency.brl));
  });
}
