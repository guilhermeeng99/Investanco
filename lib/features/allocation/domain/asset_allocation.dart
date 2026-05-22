import 'package:investanco/features/assets/domain/entities/asset.dart';

/// Metadata key: which allocation class an asset belongs to (the asset is the
/// "subclass"). Stored in `Asset.metadata` so no Assets schema change is needed
/// and the link mirrors to Firestore with the asset. See `docs/specs/allocation.md`.
const String allocationClassIdKey = 'allocationClassId';

/// Metadata key: the asset's target share **within its class** (percent).
const String allocationTargetKey = 'allocationTargetPercent';

/// The class id an asset is assigned to, or null if none.
String? allocationClassIdOf(Asset asset) {
  final value = asset.metadata[allocationClassIdKey];
  return (value == null || value.isEmpty) ? null : value;
}

/// The asset's target share within its class (`[0, 100]`; 0 when unset).
double allocationTargetOf(Asset asset) =>
    double.tryParse(asset.metadata[allocationTargetKey] ?? '') ?? 0;

/// Writes the allocation keys into a metadata map (mutating a copy is caller's
/// job). Pass a null/empty [classId] to clear both keys.
Map<String, String> applyAllocation(
  Map<String, String> metadata, {
  required String? classId,
  required double targetPercent,
}) {
  final next = Map<String, String>.from(metadata);
  if (classId == null || classId.isEmpty) {
    next..remove(allocationClassIdKey)
      ..remove(allocationTargetKey);
  } else {
    next[allocationClassIdKey] = classId;
    next[allocationTargetKey] = targetPercent == targetPercent.roundToDouble()
        ? targetPercent.toStringAsFixed(0)
        : '$targetPercent';
  }
  return next;
}
