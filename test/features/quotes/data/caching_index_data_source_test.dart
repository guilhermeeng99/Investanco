import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/features/quotes/data/datasources/caching_index_data_source.dart';
import 'package:investanco/features/quotes/domain/entities/index_point.dart';
import 'package:mocktail/mocktail.dart';

import '../../../harness/factories/index_point_factory.dart';
import '../../../harness/mocks.dart';

void main() {
  late MockIndexDataSource inner;

  setUp(() {
    inner = MockIndexDataSource();
  });

  test('serves a cached series within the TTL', () async {
    final from = DateTime(2026);
    when(() => inner.series(EconomicIndex.cdi, from))
        .thenAnswer((_) async => Right([indexPointFactory()]));
    final ds = CachingIndexDataSource(inner, ttl: const Duration(hours: 12));

    await ds.series(EconomicIndex.cdi, from);
    await ds.series(EconomicIndex.cdi, from);

    verify(() => inner.series(EconomicIndex.cdi, from)).called(1);
  });

  test('keys the cache by (index, from) — a new start date refetches', () async {
    when(() => inner.series(any(), any()))
        .thenAnswer((_) async => Right([indexPointFactory()]));
    final ds = CachingIndexDataSource(inner);

    await ds.series(EconomicIndex.cdi, DateTime(2026, 1, 1));
    await ds.series(EconomicIndex.cdi, DateTime(2025, 1, 1));

    verify(() => inner.series(any(), any())).called(2);
  });

  test('refetches once the TTL has elapsed', () async {
    var clock = DateTime(2026);
    final from = DateTime(2020);
    when(() => inner.series(EconomicIndex.cdi, from))
        .thenAnswer((_) async => Right([indexPointFactory()]));
    final ds = CachingIndexDataSource(
      inner,
      ttl: const Duration(hours: 12),
      now: () => clock,
    );

    await ds.series(EconomicIndex.cdi, from);
    clock = clock.add(const Duration(hours: 13));
    await ds.series(EconomicIndex.cdi, from);

    verify(() => inner.series(EconomicIndex.cdi, from)).called(2);
  });
}
