import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/transactions/domain/entities/asset_transaction.dart';
import 'package:investanco/features/transactions/domain/oversell_check.dart';

import '../../../harness/factories/transaction_factory.dart';

void main() {
  AssetTransaction buy(double qty, DateTime date, {DateTime? createdAt}) =>
      transactionFactory(
        kind: TransactionKind.buy,
        quantity: qty,
        date: date,
        createdAt: createdAt ?? date,
      );
  AssetTransaction sell(double qty, DateTime date, {DateTime? createdAt}) =>
      transactionFactory(
        kind: TransactionKind.sell,
        quantity: qty,
        date: date,
        createdAt: createdAt ?? date,
      );

  test('an empty position never oversells', () {
    expect(oversellsTimeline(const []), isFalse);
  });

  test('a sell within the held quantity is fine', () {
    expect(
      oversellsTimeline([buy(10, DateTime(2026)), sell(4, DateTime(2026, 2))]),
      isFalse,
    );
  });

  test('a lone sell oversells (nothing is held)', () {
    expect(oversellsTimeline([sell(1, DateTime(2026))]), isTrue);
  });

  test('a sell exceeding the held quantity oversells', () {
    expect(
      oversellsTimeline([buy(3, DateTime(2026)), sell(5, DateTime(2026, 2))]),
      isTrue,
    );
  });

  test('a sell dated before its covering buy oversells', () {
    expect(
      oversellsTimeline([buy(10, DateTime(2026, 2)), sell(4, DateTime(2026))]),
      isTrue,
    );
  });

  test('dividends never change the running quantity', () {
    final dividend = transactionFactory(
      kind: TransactionKind.dividend,
      quantity: 0,
      amount: Money.fromMajor(5, Currency.brl),
      date: DateTime(2026, 1, 5),
    );
    expect(
      oversellsTimeline(
        [buy(1, DateTime(2026)), dividend, sell(1, DateTime(2026, 2))],
      ),
      isFalse,
    );
  });

  test('a deposit covers a same-instant redemption (tie settles buy first)', () {
    final at = DateTime(2026);
    expect(
      oversellsTimeline([sell(1, at, createdAt: at), buy(1, at, createdAt: at)]),
      isFalse,
    );
  });

  test('more redemptions than deposits oversells', () {
    expect(
      oversellsTimeline([
        buy(1, DateTime(2026, 1, 1)),
        buy(1, DateTime(2026, 1, 2)),
        sell(1, DateTime(2026, 1, 3)),
        sell(1, DateTime(2026, 1, 4)),
        sell(1, DateTime(2026, 1, 5)),
      ]),
      isTrue,
    );
  });
}
