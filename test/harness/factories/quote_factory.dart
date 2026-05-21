import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/quotes/domain/entities/quote.dart';

/// Test factory for [Quote]. Defaults to a fresh R$10 brapi quote. Never
/// hardcode entities in tests.
Quote quoteFactory({
  String assetId = 'a1',
  Money? unitPrice,
  Money? previousClose,
  DateTime? asOf,
  DateTime? fetchedAt,
  QuoteSource source = QuoteSource.brapi,
}) {
  final when = asOf ?? DateTime(2026, 5, 20, 12);
  return Quote(
    assetId: assetId,
    unitPrice: unitPrice ?? Money.fromMajor(10, Currency.brl),
    previousClose: previousClose,
    asOf: when,
    fetchedAt: fetchedAt ?? when,
    source: source,
  );
}
