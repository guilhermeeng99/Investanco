import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/features/quotes/data/datasources/awesomeapi_fx_data_source.dart';
import 'package:mocktail/mocktail.dart';

import '../../../harness/mocks.dart';

void main() {
  late MockDio dio;
  late AwesomeApiFxDataSource source;

  setUp(() {
    dio = MockDio();
    source = AwesomeApiFxDataSource(dio);
  });

  test('returns 1 without a request when both currencies match', () async {
    final result = await source.rate(Currency.brl, Currency.brl);

    expect(result, const Right<Failure, double>(1));
    verifyNever(() => dio.get<Map<String, dynamic>>(any()));
  });

  test('parses the USDBRL bid into a rate', () async {
    when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: ''),
        data: {
          'USDBRL': {'bid': '5.43'},
        },
      ),
    );

    final result = await source.rate(Currency.usd, Currency.brl);

    expect(result.getOrElse(() => 0), 5.43);
  });

  test('returns ParseFailure when the bid is missing', () async {
    when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: ''),
        data: const {'USDBRL': <String, dynamic>{}},
      ),
    );

    final result = await source.rate(Currency.usd, Currency.brl);

    expect(result, const Left<Failure, double>(ParseFailure()));
  });

  test('returns NetworkFailure on DioException', () async {
    when(() => dio.get<Map<String, dynamic>>(any()))
        .thenThrow(DioException(requestOptions: RequestOptions(path: '')));

    final result = await source.rate(Currency.usd, Currency.brl);

    expect(result, const Left<Failure, double>(NetworkFailure()));
  });
}
