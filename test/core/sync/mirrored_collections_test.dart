import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/sync/mirrored_collections.dart';

void main() {
  group('MirroredCollections', () {
    // The sign-in pull and clear iterate exactly `all`. If a repository writes
    // to a collection missing here, that data is silently dropped on the next
    // authoritative sign-in. This pins the contract so adding/removing a mirror
    // is a deliberate, visible change. See `docs/specs/cloud_sync.md`.
    test('all lists every mirrored collection in pull/clear order', () {
      expect(MirroredCollections.all, const [
        'institutions',
        'assets',
        'transactions',
        'snapshots',
        'asset_classes',
      ]);
    });

    test('all matches the individual collection constants', () {
      expect(MirroredCollections.all, const [
        MirroredCollections.institutions,
        MirroredCollections.assets,
        MirroredCollections.transactions,
        MirroredCollections.snapshots,
        MirroredCollections.assetClasses,
      ]);
    });

    test('all has no duplicate collection names', () {
      expect(
        MirroredCollections.all.toSet().length,
        MirroredCollections.all.length,
      );
    });
  });
}
