import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/quotes/data/datasources/brapi_quote_data_source.dart';
import 'package:investanco/features/quotes/domain/entities/quote.dart';
import 'package:mocktail/mocktail.dart';

import '../../../harness/factories/asset_factory.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late BrapiQuoteDataSource source;

  setUp(() {
    dio = _MockDio();
    source = BrapiQuoteDataSource(dio);
  });

  test('parses brapi results into quotes', () async {
    when(
      () => dio.get<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: ''),
        data: {
          'results': [
            {
              'symbol': 'PETR4',
              'regularMarketPrice': 38.5,
              'regularMarketPreviousClose': 38.0,
            },
          ],
        },
      ),
    );

    final result = await source.fetch([assetFactory(ticker: 'PETR4')]);
    final quotes = result.getOrElse(() => <Quote>[]);

    expect(quotes.length, 1);
    expect(quotes.first.unitPrice, Money.fromMajor(38.5, Currency.brl));
    expect(quotes.first.previousClose, Money.fromMajor(38, Currency.brl));
    expect(quotes.first.source, QuoteSource.brapi);
  });

  test('returns a failure on DioException', () async {
    when(
      () => dio.get<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenThrow(DioException(requestOptions: RequestOptions(path: '')));

    final result = await source.fetch([assetFactory(ticker: 'PETR4')]);

    expect(result.isLeft(), isTrue);
  });

  test('ignores assets it does not support', () async {
    final result = await source.fetch([
      assetFactory(ticker: 'AAPL', kind: AssetKind.stockUs),
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
