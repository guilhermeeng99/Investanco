import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/quotes/data/datasources/coingecko_quote_data_source.dart';
import 'package:investanco/features/quotes/domain/entities/quote.dart';
import 'package:mocktail/mocktail.dart';

import '../../../harness/factories/asset_factory.dart';
import '../../../harness/mocks.dart';

Asset _crypto({
  String id = 'c1',
  String ticker = 'BTC',
  Currency currency = Currency.brl,
  Map<String, String> metadata = const {},
}) =>
    assetFactory(
      id: id,
      ticker: ticker,
      name: 'Bitcoin',
      kind: AssetKind.crypto,
      market: Market.global,
      currency: currency,
      metadata: metadata,
    );

void _stub(MockDio dio, Map<String, dynamic> data) {
  when(
    () => dio.get<Map<String, dynamic>>(
      any(),
      queryParameters: any(named: 'queryParameters'),
    ),
  ).thenAnswer(
    (_) async => Response<Map<String, dynamic>>(
      requestOptions: RequestOptions(path: ''),
      data: data,
    ),
  );
}

void main() {
  late MockDio dio;
  late CoinGeckoQuoteDataSource source;

  setUp(() {
    dio = MockDio();
    source = CoinGeckoQuoteDataSource(dio);
  });

  test('prices crypto in BRL and derives previous close from 24h change',
      () async {
    // 110 now, +10% on the day → previous = 110 / 1.1 = 100.
    _stub(dio, {
      'bitcoin': {'brl': 110.0, 'brl_24h_change': 10.0},
    });

    final result = await source.fetch([_crypto()]);
    final quotes = result.getOrElse(() => <Quote>[]);

    expect(quotes.length, 1);
    expect(quotes.first.unitPrice, Money.fromMajor(110, Currency.brl));
    expect(quotes.first.previousClose, Money.fromMajor(100, Currency.brl));
    expect(quotes.first.source, QuoteSource.coingecko);
  });

  test('reads the price in the asset currency (USD) with no change → null close',
      () async {
    _stub(dio, {
      'bitcoin': {'brl': 600000.0, 'usd': 100000.0},
    });

    final result = await source.fetch([_crypto(currency: Currency.usd)]);
    final quote = result.getOrElse(() => <Quote>[]).single;

    expect(quote.unitPrice, Money.fromMajor(100000, Currency.usd));
    expect(quote.previousClose, isNull);
  });

  test('resolves ids from metadata override and the built-in ticker map',
      () async {
    _stub(dio, const <String, dynamic>{});

    await source.fetch([
      _crypto(),
      _crypto(id: 'c2', ticker: 'SHIB', metadata: {'coingeckoId': 'shiba-inu'}),
    ]);

    final params = verify(
      () => dio.get<Map<String, dynamic>>(
        any(),
        queryParameters: captureAny(named: 'queryParameters'),
      ),
    ).captured.single as Map<String, dynamic>;
    final ids = (params['ids'] as String).split(',');
    expect(ids, containsAll(<String>['bitcoin', 'shiba-inu']));
    expect(params['vs_currencies'], 'brl');
  });

  test('returns a failure on DioException', () async {
    when(
      () => dio.get<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenThrow(DioException(requestOptions: RequestOptions(path: '')));

    final result = await source.fetch([_crypto()]);

    expect(result.isLeft(), isTrue);
  });

  test('ignores assets it does not support', () async {
    final result = await source.fetch([
      assetFactory(ticker: 'PETR4'),
    ]);

    expect(result.getOrElse(() => <Quote>[]), isEmpty);
    verifyNever(
      () => dio.get<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    );
  });
}
