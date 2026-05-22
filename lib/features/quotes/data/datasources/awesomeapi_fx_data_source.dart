import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/network/guarded_fetch.dart';
import 'package:investanco/features/quotes/domain/datasources/quote_data_source.dart';

/// FX rates via AwesomeAPI (e.g. USD→BRL). See `docs/specs/quotes.md`.
class AwesomeApiFxDataSource implements FxDataSource {
  /// Creates the adapter.
  const AwesomeApiFxDataSource(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, double>> rate(Currency from, Currency to) async {
    if (from == to) return const Right(1);

    final pair = '${from.code}-${to.code}';
    final key = '${from.code}${to.code}';
    return guardedFetch(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://economia.awesomeapi.com.br/json/last/$pair',
      );
      final node = response.data?[key] as Map<String, dynamic>?;
      final bid = double.tryParse(node?['bid'] as String? ?? '');
      if (bid == null) return const Left(ParseFailure());
      return Right(bid);
    });
  }
}
