import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/features/quotes/data/datasources/bcb_sgs_index_data_source.dart';
import 'package:investanco/features/quotes/domain/entities/index_point.dart';
import 'package:mocktail/mocktail.dart';

import '../../../harness/mocks.dart';

void main() {
  late MockDio dio;
  late BcbSgsIndexDataSource source;

  setUp(() {
    dio = MockDio();
    source = BcbSgsIndexDataSource(dio);
  });

  test('parses the SGS series into dated rate points', () async {
    when(
      () => dio.get<List<dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response<List<dynamic>>(
        requestOptions: RequestOptions(path: ''),
        data: [
          {'data': '02/01/2026', 'valor': '0.041242'},
          {'data': '03/01/2026', 'valor': '0.041242'},
        ],
      ),
    );

    final result = await source.series(EconomicIndex.cdi, DateTime(2026));
    final points = result.getOrElse(() => <IndexPoint>[]);

    expect(points.length, 2);
    expect(points.first, IndexPoint(date: DateTime(2026, 1, 2), rate: 0.041242));
  });

  test('sends formato=json and dataInicial as dd/MM/yyyy', () async {
    when(
      () => dio.get<List<dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response<List<dynamic>>(
        requestOptions: RequestOptions(path: ''),
        data: const [],
      ),
    );

    await source.series(EconomicIndex.cdi, DateTime(2025, 3, 7));

    final captured = verify(
      () => dio.get<List<dynamic>>(
        captureAny(),
        queryParameters: captureAny(named: 'queryParameters'),
      ),
    ).captured;
    expect(captured[0], contains('bcdata.sgs.12/dados'));
    expect(
      captured[1],
      {'formato': 'json', 'dataInicial': '07/03/2025'},
    );
  });

  test('maps each index to its SGS code', () {
    expect(BcbSgsIndexDataSource.seriesCode[EconomicIndex.cdi], 12);
    expect(BcbSgsIndexDataSource.seriesCode[EconomicIndex.selic], 11);
    expect(BcbSgsIndexDataSource.seriesCode[EconomicIndex.ipca], 433);
  });

  test('returns a failure on DioException', () async {
    when(
      () => dio.get<List<dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenThrow(DioException(requestOptions: RequestOptions(path: '')));

    final result = await source.series(EconomicIndex.selic, DateTime(2026));

    expect(result.isLeft(), isTrue);
  });
}
