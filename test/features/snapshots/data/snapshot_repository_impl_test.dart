import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/database/app_database.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/snapshots/data/repositories/snapshot_repository_impl.dart';

import '../../../harness/helpers.dart';

void main() {
  late AppDatabase db;
  late SnapshotRepositoryImpl repository;

  setUp(() {
    db = memoryDatabase();
    repository = SnapshotRepositoryImpl(db);
  });

  test('upsertToday is idempotent per day (last write wins)', () async {
    await repository.upsertToday(
      totalValue: Money.fromMajor(100, Currency.brl),
      totalInvested: Money.fromMajor(80, Currency.brl),
      totalPL: Money.fromMajor(20, Currency.brl),
    );
    await repository.upsertToday(
      totalValue: Money.fromMajor(110, Currency.brl),
      totalInvested: Money.fromMajor(80, Currency.brl),
      totalPL: Money.fromMajor(30, Currency.brl),
    );

    final result = await repository.range(
      DateTime.now().subtract(const Duration(days: 1)),
      DateTime.now().add(const Duration(days: 1)),
    );
    final list = result.getOrElse(() => const []);

    expect(list.length, 1);
    expect(list.single.totalValue, Money.fromMajor(110, Currency.brl));
  });

  test('range excludes snapshots outside the window', () async {
    await repository.upsertToday(
      totalValue: Money.fromMajor(100, Currency.brl),
      totalInvested: const Money.zero(Currency.brl),
      totalPL: const Money.zero(Currency.brl),
    );

    final result = await repository.range(DateTime(2000), DateTime(2001));
    expect(result.getOrElse(() => const []), isEmpty);
  });
}
