import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/format/money_input.dart';
import 'package:investanco/core/network/guarded_fetch.dart';
import 'package:investanco/features/quotes/domain/datasources/index_data_source.dart';
import 'package:investanco/features/quotes/domain/entities/index_point.dart';

/// Fetches economic index series from the Banco Central SGS public API. Each
/// index maps to an SGS series code; values are period rates in percent.
/// See `docs/specs/quotes.md`.
class BcbSgsIndexDataSource implements IndexDataSource {
  /// Creates the adapter over [_dio].
  const BcbSgsIndexDataSource(this._dio);

  final Dio _dio;

  /// SGS series codes: CDI daily, Selic daily, IPCA monthly.
  static const Map<EconomicIndex, int> seriesCode = {
    EconomicIndex.cdi: 12,
    EconomicIndex.selic: 11,
    EconomicIndex.ipca: 433,
  };

  @override
  Future<Either<Failure, List<IndexPoint>>> series(
    EconomicIndex index,
    DateTime from,
  ) async {
    final code = seriesCode[index]!;
    return guardedFetch(() async {
      final response = await _dio.get<List<dynamic>>(
        'https://api.bcb.gov.br/dados/serie/bcdata.sgs.$code/dados',
        queryParameters: {'formato': 'json', 'dataInicial': _formatDate(from)},
      );
      final rows = response.data ?? const [];
      final points = <IndexPoint>[];
      for (final raw in rows) {
        final map = raw as Map<String, dynamic>;
        final date = _parseDate(map['data'] as String?);
        final rate = _parseRate(map['valor'] as String?);
        if (date == null || rate == null) continue;
        points.add(IndexPoint(date: date, rate: rate));
      }
      return Right(points);
    });
  }

  /// BCB expects and returns `dd/MM/yyyy`.
  String _formatDate(DateTime date) =>
      '${_two(date.day)}/${_two(date.month)}/${date.year}';

  DateTime? _parseDate(String? value) {
    final parts = value?.split('/');
    if (parts == null || parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  /// BCB sends decimals with a dot, but tolerate a comma just in case.
  double? _parseRate(String? value) =>
      value == null ? null : parseMajor(value);

  String _two(int n) => n.toString().padLeft(2, '0');
}
