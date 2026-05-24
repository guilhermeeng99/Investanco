import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/quotes/data/datasources/finnhub_quote_data_source.dart';
import 'package:investanco/features/quotes/domain/entities/quote.dart';
import 'package:mocktail/mocktail.dart';

import '../../../harness/factories/asset_factory.dart';
import '../../../harness/mocks.dart';

void main() {
  late MockDio dio;

  setUp(() {
    dio = MockDio();
  });

  test('parses a Finnhub quote (c / pc) into a Quote', () async {
    final source = FinnhubQuoteDataSource(dio, token: 'k');
    when(
      () => dio.get<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: ''),
        data: {'c': 496.74, 'pc': 489.0},
      ),
    );

    final result = await source.fetch([
      assetFactory(
        ticker: 'SOXX',
        kind: AssetKind.stockUs,
        market: Market.us,
        currency: Currency.usd,
      ),
    ]);
    final quotes = result.getOrElse(() => <Quote>[]);

    expect(quotes.length, 1);
    expect(quotes.first.unitPrice, Money.fromMajor(496.74, Currency.usd));
    expect(quotes.first.previousClose, Money.fromMajor(489, Currency.usd));
    expect(quotes.first.source, QuoteSource.finnhub);
  });

  test('without a token, returns no quotes and makes no request', () async {
    final source = FinnhubQuoteDataSource(dio, token: '');

    final result = await source.fetch([
      assetFactory(kind: AssetKind.stockUs, currency: Currency.usd),
    ]);

    expect(result.getOrElse(() => <Quote>[]), isEmpty);
    verifyNever(
      () => dio.get<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    );
  });

  test('supports US assets only', () {
    final source = FinnhubQuoteDataSource(dio, token: 'k');

    expect(source.supports(assetFactory(kind: AssetKind.stockUs)), isTrue);
    expect(source.supports(assetFactory(kind: AssetKind.etfUs)), isTrue);
    expect(source.supports(assetFactory(kind: AssetKind.stockBr)), isFalse);
  });

  test('a failing request for one ticker is skipped; others still return',
      () async {
    final source = FinnhubQuoteDataSource(dio, token: 'k');
    when(
      () => dio.get<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer((invocation) async {
      final params =
          invocation.namedArguments[#queryParameters] as Map<String, dynamic>;
      if (params['symbol'] == 'BAD') {
        throw DioException(requestOptions: RequestOptions(path: ''));
      }
      return Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: ''),
        data: {'c': 100.0, 'pc': 90.0},
      );
    });

    final result = await source.fetch([
      assetFactory(
        id: 'a1',
        ticker: 'AAPL',
        kind: AssetKind.stockUs,
        currency: Currency.usd,
      ),
      assetFactory(
        id: 'a2',
        ticker: 'BAD',
        kind: AssetKind.stockUs,
        currency: Currency.usd,
      ),
    ]);
    final quotes = result.getOrElse(() => <Quote>[]);

    // Per-ticker resilience: one bad symbol does not lose the batch.
    expect(quotes.length, 1);
    expect(quotes.single.assetId, 'a1');
  });

  test('every request failing degrades to an empty list, not a Left', () async {
    final source = FinnhubQuoteDataSource(dio, token: 'k');
    when(
      () => dio.get<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenThrow(DioException(requestOptions: RequestOptions(path: '')));

    final result = await source.fetch([
      assetFactory(kind: AssetKind.stockUs, currency: Currency.usd),
    ]);

    // US holdings simply show cost basis until a quote arrives — never a failure.
    expect(result.isRight(), isTrue);
    expect(result.getOrElse(() => <Quote>[]), isEmpty);
  });
}
