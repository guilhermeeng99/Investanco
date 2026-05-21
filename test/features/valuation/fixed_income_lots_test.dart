import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/transactions/domain/entities/asset_transaction.dart';
import 'package:investanco/features/valuation/domain/fixed_income_lots.dart';

import '../../harness/factories/transaction_factory.dart';

void main() {
  const brl = Currency.brl;

  AssetTransaction buy(double price, DateTime date, {double qty = 1}) =>
      transactionFactory(
        unitPrice: Money.fromMajor(price, brl),
        quantity: qty,
        date: date,
      );

  test('single buy → one lot holding the whole invested cost', () {
    final lots = buildFixedIncomeLots(
      Money.fromMajor(3000, brl),
      [buy(3000, DateTime(2025, 11, 6))],
    );

    expect(lots, hasLength(1));
    expect(lots.single.principal, Money.fromMajor(3000, brl));
    expect(lots.single.date, DateTime(2025, 11, 6));
  });

  test('no sells → lots equal each buy amount, oldest first, summing to invested',
      () {
    final lots = buildFixedIncomeLots(
      Money.fromMajor(400, brl),
      [
        buy(300, DateTime(2026, 2)),
        buy(100, DateTime(2026)),
      ],
    );

    expect(lots.map((l) => l.date), [DateTime(2026), DateTime(2026, 2)]);
    expect(lots.map((l) => l.principal),
        [Money.fromMajor(100, brl), Money.fromMajor(300, brl)]);
  });

  test('sells reduce invested → lots scale proportionally and still sum exactly',
      () {
    // Buys total 400, but only 200 remains invested (a redemption halved it).
    final lots = buildFixedIncomeLots(
      Money.fromMajor(200, brl),
      [
        buy(100, DateTime(2026)),
        buy(300, DateTime(2026, 2)),
      ],
    );

    // 1:3 weighting preserved → 50 / 150.
    expect(lots.map((l) => l.principal),
        [Money.fromMajor(50, brl), Money.fromMajor(150, brl)]);
    final sum = lots.fold(0, (s, l) => s + l.principal.minorUnits);
    expect(sum, Money.fromMajor(200, brl).minorUnits);
  });

  test('rounding remainder lands on the last lot so lots sum to the cent', () {
    // 100 / 3 does not divide evenly into cents.
    final lots = buildFixedIncomeLots(
      Money.fromMajor(100, brl),
      [
        buy(100, DateTime(2026)),
        buy(100, DateTime(2026, 2)),
        buy(100, DateTime(2026, 3)),
      ],
    );

    final sum = lots.fold(0, (s, l) => s + l.principal.minorUnits);
    expect(sum, Money.fromMajor(100, brl).minorUnits);
    expect(lots.last.principal, const Money(3334, brl)); // 3333 + 3333 + 3334
  });

  test('empty when there are no buys or nothing invested', () {
    expect(buildFixedIncomeLots(Money.fromMajor(100, brl), const []), isEmpty);
    expect(
      buildFixedIncomeLots(
        const Money.zero(brl),
        [buy(100, DateTime(2026))],
      ),
      isEmpty,
    );
  });
}
