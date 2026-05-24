import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/sync/remote_mirror.dart';

void main() {
  group('NoopRemoteMirror', () {
    const mirror = NoopRemoteMirror();

    test('upsert is a no-op that completes without throwing', () {
      expect(
        mirror.upsert('institutions', 'i1', const {'name': 'Nubank'}),
        completes,
      );
    });

    test('delete is a no-op that completes without throwing', () {
      expect(mirror.delete('institutions', 'i1'), completes);
    });
  });
}
