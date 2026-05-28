import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/database/guarded_write.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/sync/remote_mirror.dart';

void main() {
  group('guardedMirroredUpsert', () {
    test('mirrors to the cloud BEFORE writing to the local cache', () async {
      // The write-through contract for EVERY repository save: the authoritative
      // cloud write must land before the local cache write.
      final calls = <String>[];
      final result = await guardedMirroredUpsert(
        mirror: _RecordingMirror(calls),
        collection: 'institutions',
        id: 'i1',
        json: const {'id': 'i1'},
        localUpsert: () async => calls.add('local'),
      );

      expect(result, const Right<Failure, Unit>(unit));
      expect(calls, ['mirror:institutions/i1', 'local']);
    });

    test('skips the local write and returns CacheFailure if the mirror throws',
        () async {
      // A write that can't reach the cloud must NOT live only in the local
      // cache (the next sign-in pull would wipe it).
      var localWritten = false;
      final result = await guardedMirroredUpsert(
        mirror: _ThrowingMirror(),
        collection: 'assets',
        id: 'a1',
        json: const {'id': 'a1'},
        localUpsert: () async => localWritten = true,
      );

      result.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('expected Left'),
      );
      expect(localWritten, isFalse);
    });
  });

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

/// Records the order of mirror/local calls so write-through ordering can be
/// asserted without mocktail fallbacks.
class _RecordingMirror implements RemoteMirror {
  _RecordingMirror(this.calls);

  final List<String> calls;

  @override
  Future<void> upsert(String collection, String id, Map<String, dynamic> _) async =>
      calls.add('mirror:$collection/$id');

  @override
  Future<void> delete(String collection, String id) async =>
      calls.add('delete:$collection/$id');
}

/// A mirror whose cloud write always fails (simulates offline/permission).
class _ThrowingMirror implements RemoteMirror {
  @override
  Future<void> upsert(String collection, String id, Map<String, dynamic> _) async =>
      throw Exception('cloud unreachable');

  @override
  Future<void> delete(String collection, String id) async {}
}
