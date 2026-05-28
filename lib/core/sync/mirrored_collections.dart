/// The Firestore collections mirrored 1:1 from the Drift cache — the
/// source-of-truth set. Each repository references one of these for its
/// write-through `collection`, and `FirestoreSyncService` pulls **and** clears
/// exactly [all]. Keeping the names in one place stops a repository from writing
/// to a collection the sync service forgets to pull, which would silently drop
/// that data on the next authoritative sign-in. See `docs/specs/cloud_sync.md`.
abstract final class MirroredCollections {
  /// `users/{uid}/institutions`.
  static const String institutions = 'institutions';

  /// `users/{uid}/assets`.
  static const String assets = 'assets';

  /// `users/{uid}/transactions`.
  static const String transactions = 'transactions';

  /// `users/{uid}/snapshots`.
  static const String snapshots = 'snapshots';

  /// `users/{uid}/asset_classes`.
  static const String assetClasses = 'asset_classes';

  /// Every mirrored collection, in pull/clear order.
  static const List<String> all = [
    institutions,
    assets,
    transactions,
    snapshots,
    assetClasses,
  ];
}
