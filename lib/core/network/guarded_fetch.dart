import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:investanco/core/error/failures.dart';

/// Runs a remote [fetch] (which returns its own `Either`), translating the
/// transport/parse exceptions every quote/FX/index adapter shares: a
/// [DioException] → [NetworkFailure], anything else → [ParseFailure]. Centralizes
/// the try/catch so adapters keep only their request and mapping — the network
/// counterpart to `guardedWrite`.
///
/// Unlike `guardedWrite` (which catches only `Exception`), this catches every
/// `Object`: a malformed payload typically throws a cast `Error`, and adapters
/// rely on that surfacing as a [ParseFailure] rather than crashing the refresh.
///
/// Example:
/// ```dart
/// return guardedFetch(() async {
///   final response = await _dio.get<Map<String, dynamic>>(url);
///   return Right(parse(response.data));
/// });
/// ```
Future<Either<Failure, T>> guardedFetch<T>(
  Future<Either<Failure, T>> Function() fetch,
) async {
  try {
    return await fetch();
  } on DioException {
    return const Left(NetworkFailure());
  } on Object {
    return const Left(ParseFailure());
  }
}
