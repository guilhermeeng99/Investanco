import 'package:investanco/features/allocation/domain/entities/asset_class.dart';

/// Test factory for [AssetClass]. Defaults to a root named by [id] with no
/// target. Never hardcode entities in tests.
AssetClass assetClassFactory({
  String id = 'c1',
  String? name,
  String iconKey = 'chartPie',
  int colorValue = 0xFF00A868,
  double targetPercent = 0,
  String? parentId,
  DateTime? createdAt,
}) {
  return AssetClass(
    id: id,
    name: name ?? id,
    iconKey: iconKey,
    colorValue: colorValue,
    targetPercent: targetPercent,
    parentId: parentId,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
  );
}
