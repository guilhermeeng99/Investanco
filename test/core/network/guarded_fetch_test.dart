import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/network/guarded_fetch.dart';

void main() {
  group('guardedFetch', () {
    test('returns the fetch result on success', () async {
      final result = await guardedFetch<int>(() async => const Right(42));
      expect(result.getOrElse(() => -1), 42);
    });

    test('passes through a Left returned by the body', () async {
      final result =
          await guardedFetch<int>(() async => const Left(ParseFailure()));
      result.fold(
        (f) => expect(f, isA<ParseFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('maps a DioException to NetworkFailure', () async {
      final result = await guardedFetch<int>(
        () async => throw DioException(requestOptions: RequestOptions(path: '')),
      );
      result.fold(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('maps any other exception to ParseFailure', () async {
      final result = await guardedFetch<int>(
        () async => throw const FormatException('bad'),
      );
      result.fold(
        (f) => expect(f, isA<ParseFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('maps an Error (not Exception) to ParseFailure', () async {
      // A malformed payload throws an Error (e.g. a cast/range error), not an
      // Exception — adapters depend on guardedFetch catching it too.
      final result =
          await guardedFetch<int>(() async => throw RangeError('boom'));
      result.fold(
        (f) => expect(f, isA<ParseFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });
}
