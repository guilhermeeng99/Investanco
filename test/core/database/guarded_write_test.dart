import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/database/guarded_write.dart';
import 'package:investanco/core/error/failures.dart';

void main() {
  group('guardedWrite', () {
    test('returns unit when the write succeeds', () async {
      final result = await guardedWrite(() async {});
      expect(result, const Right<Failure, Unit>(unit));
    });

    test('maps an Exception to CacheFailure', () async {
      final result =
          await guardedWrite(() async => throw Exception('drift down'));
      result.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('lets an Error propagate (bugs are not masked)', () async {
      await expectLater(
        guardedWrite(() async => throw StateError('bug')),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('guardedRead', () {
    test('returns the value when the read succeeds', () async {
      final result = await guardedRead<int>(() async => 7);
      expect(result.getOrElse(() => -1), 7);
    });

    test('maps an Exception to CacheFailure', () async {
      final result =
          await guardedRead<int>(() async => throw Exception('boom'));
      result.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });

  group('guardedDeleteIfUnreferenced', () {
    test('deletes and returns unit when nothing references the row', () async {
      var deleted = false;
      final result = await guardedDeleteIfUnreferenced(
        isReferenced: () async => false,
        delete: () async => deleted = true,
      );
      expect(result, const Right<Failure, Unit>(unit));
      expect(deleted, isTrue);
    });

    test('returns InUseFailure and skips the delete when referenced', () async {
      var deleted = false;
      final result = await guardedDeleteIfUnreferenced(
        isReferenced: () async => true,
        delete: () async => deleted = true,
      );
      result.fold(
        (f) => expect(f, isA<InUseFailure>()),
        (_) => fail('expected Left'),
      );
      expect(deleted, isFalse);
    });

    test('maps an Exception to CacheFailure', () async {
      final result = await guardedDeleteIfUnreferenced(
        isReferenced: () async => false,
        delete: () async => throw Exception('drift down'),
      );
      result.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });
}
