import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/quotes/data/datasources/tesouro_direto_data_source.dart';
import 'package:investanco/features/quotes/domain/entities/quote.dart';
import 'package:mocktail/mocktail.dart';

import '../../../harness/factories/asset_factory.dart';

class _MockDio extends Mock implements Dio {}

Response<Map<String, dynamic>> _market(List<Map<String, dynamic>> bonds) {
  return Response<Map<String, dynamic>>(
    requestOptions: RequestOptions(path: ''),
    data: {
      'response': {
        'TrsrBdTradgList': [
          for (final bond in bonds) {'TrsrBd': bond},
        ],
      },
    },
  );
}

void main() {
  late _MockDio dio;
  late TesouroDiretoDataSource source;

  setUp(() {
    dio = _MockDio();
    source = TesouroDiretoDataSource(dio);
  });

  Asset treasury({String name = 'Tesouro Selic 2027', String? tesouroName}) {
    return assetFactory(
      ticker: 'TD-SELIC-2027',
      name: name,
      kind: AssetKind.treasury,
      metadata: tesouroName == null ? const {} : {'tesouroName': tesouroName},
    );
  }

  void stubMarket(List<Map<String, dynamic>> bonds) {
    when(() => dio.get<Map<String, dynamic>>(any()))
        .thenAnswer((_) async => _market(bonds));
  }

  test('prices a bond matched by tesouroName at its redemption value', () async {
    stubMarket([
      {'nm': 'Tesouro Selic 2027', 'untrRedVal': 14000.55},
      {'nm': 'Tesouro IPCA+ 2029', 'untrRedVal': 3200.10},
    ]);

    final result = await source.fetch([
      treasury(name: 'LFT', tesouroName: 'Tesouro Selic 2027'),
    ]);
    final quotes = result.getOrElse(() => <Quote>[]);

    expect(quotes.length, 1);
    expect(quotes.first.unitPrice, Money.fromMajor(14000.55, Currency.brl));
    expect(quotes.first.previousClose, isNull);
    expect(quotes.first.source, QuoteSource.tesouro);
  });

  test('falls back to asset name, ignoring case and spacing', () async {
    stubMarket([
      {'nm': 'Tesouro Selic 2027', 'untrRedVal': 14000.55},
    ]);

    final result = await source.fetch([treasury(name: '  tesouro   selic 2027 ')]);
    final quotes = result.getOrElse(() => <Quote>[]);

    expect(quotes.length, 1);
    expect(quotes.first.unitPrice, Money.fromMajor(14000.55, Currency.brl));
  });

  test('skips a treasury asset with no matching bond', () async {
    stubMarket([
      {'nm': 'Tesouro IPCA+ 2029', 'untrRedVal': 3200.10},
    ]);

    final result = await source.fetch([treasury(name: 'Tesouro Selic 2027')]);

    expect(result.getOrElse(() => <Quote>[]), isEmpty);
  });

  test('returns a failure on DioException', () async {
    when(() => dio.get<Map<String, dynamic>>(any()))
        .thenThrow(DioException(requestOptions: RequestOptions(path: '')));

    final result = await source.fetch([treasury()]);

    expect(result.isLeft(), isTrue);
  });

  test('ignores assets it does not support', () async {
    final result = await source.fetch([
      assetFactory(ticker: 'PETR4'),
    ]);

    expect(result.getOrElse(() => <Quote>[]), isEmpty);
    verifyNever(() => dio.get<Map<String, dynamic>>(any()));
  });
}
