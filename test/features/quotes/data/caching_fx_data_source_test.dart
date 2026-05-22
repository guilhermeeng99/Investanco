import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/features/quotes/data/datasources/caching_fx_data_source.dart';
import 'package:mocktail/mocktail.dart';

import '../../../harness/mocks.dart';

void main() {
  late MockFxDataSource inner;

  setUp(() {
    inner = MockFxDataSource();
  });

  test('serves a cached rate within the TTL (one fetch for two reads)',
      () async {
    when(() => inner.rate(Currency.usd, Currency.brl))
        .thenAnswer((_) async => const Right(5));
    final ds = CachingFxDataSource(inner, ttl: const Duration(minutes: 10));

    final first = await ds.rate(Currency.usd, Currency.brl);
    final second = await ds.rate(Currency.usd, Currency.brl);

    expect(first, const Right<Failure, double>(5));
    expect(second, const Right<Failure, double>(5));
    verify(() => inner.rate(Currency.usd, Currency.brl)).called(1);
  });

  test('refetches once the TTL has elapsed', () async {
    var clock = DateTime(2026);
    when(() => inner.rate(Currency.usd, Currency.brl))
        .thenAnswer((_) async => const Right(5));
    final ds = CachingFxDataSource(
      inner,
      ttl: const Duration(minutes: 10),
      now: () => clock,
    );

    await ds.rate(Currency.usd, Currency.brl);
    clock = clock.add(const Duration(minutes: 11));
    await ds.rate(Currency.usd, Currency.brl);

    verify(() => inner.rate(Currency.usd, Currency.brl)).called(2);
  });

  test('does not cache a failed fetch', () async {
    when(() => inner.rate(Currency.usd, Currency.brl))
        .thenAnswer((_) async => const Left(NetworkFailure()));
    final ds = CachingFxDataSource(inner);

    await ds.rate(Currency.usd, Currency.brl);
    await ds.rate(Currency.usd, Currency.brl);

    verify(() => inner.rate(Currency.usd, Currency.brl)).called(2);
  });
}
