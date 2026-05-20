// Single-method port so it can be injected and faked in tests.
// ignore_for_file: one_member_abstracts
import 'package:dartz/dartz.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/features/quotes/domain/entities/index_point.dart';

/// A source of economic index series (CDI/Selic/IPCA) for fixed-income accrual.
abstract class IndexDataSource {
  /// Series for [index] from [from] (inclusive) to today, oldest first.
  Future<Either<Failure, List<IndexPoint>>> series(
    EconomicIndex index,
    DateTime from,
  );
}
