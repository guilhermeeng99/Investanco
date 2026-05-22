import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/allocation/domain/asset_allocation.dart';
import 'package:investanco/features/allocation/domain/entities/asset_class.dart';
import 'package:investanco/features/allocation/domain/entities/investment_overview.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/valuation/domain/entities/holding_valuation.dart';

/// Gaps smaller than R$1 (in minor units) are noise — no rebalance action.
const int _minRebalanceMinor = 100;

/// Builds an [InvestmentOverview] from the user's [classes], [assets] (each
/// carrying its class + target via metadata), and the valued [holdings].
///
/// Each **asset** is a "subclass" of its class — the link is set on the asset,
/// not by creating subclass records. Current values come from real market
/// values, never manual amounts. Pure + synchronous. See
/// `docs/specs/allocation.md`.
InvestmentOverview computeInvestmentOverview({
  required List<AssetClass> classes,
  required List<Asset> assets,
  required List<HoldingValuation> holdings,
  required Currency base,
}) {
  Money money(int minor) => Money(minor, base);

  final classById = {for (final c in classes) c.id: c};

  // Market value per asset (summed across institutions; skip fx-missing).
  final valueByAsset = <String, int>{};
  var totalMinor = 0;
  for (final h in holdings) {
    if (h.fxMissing) continue;
    final minor = h.marketValueBase.minorUnits;
    totalMinor += minor;
    valueByAsset[h.assetId] = (valueByAsset[h.assetId] ?? 0) + minor;
  }

  // Group assets under their class.
  final assetsByClass = <String, List<Asset>>{};
  var allocatedMinor = 0;
  for (final asset in assets) {
    final classId = allocationClassIdOf(asset);
    if (classId == null || !classById.containsKey(classId)) continue;
    (assetsByClass[classId] ??= []).add(asset);
    allocatedMinor += valueByAsset[asset.id] ?? 0;
  }
  final pendingMinor = totalMinor - allocatedMinor;

  final classSlices = <InvestmentClassSlice>[];
  for (final root in classes.where((c) => c.isRoot)) {
    final classAssets = (assetsByClass[root.id] ?? [])
      ..sort((a, b) =>
          (valueByAsset[b.id] ?? 0).compareTo(valueByAsset[a.id] ?? 0));
    final classTotalMinor = classAssets.fold<int>(
      0,
      (sum, a) => sum + (valueByAsset[a.id] ?? 0),
    );
    final targetValueMinor = (totalMinor * root.targetFraction).round();

    final subSlices = [
      for (final asset in classAssets)
        () {
          final v = valueByAsset[asset.id] ?? 0;
          final at = allocationTargetOf(asset);
          final suggestedMinor = (targetValueMinor * at / 100).round();
          return InvestmentSubclassSlice(
            id: asset.id,
            name: asset.ticker,
            currentValue: money(v),
            percentOfClass: classTotalMinor == 0 ? 0 : v / classTotalMinor,
            percentOfTotal: totalMinor == 0 ? 0 : v / totalMinor,
            targetPercent: at,
            suggestedValue: money(suggestedMinor),
            suggestedDelta: money(suggestedMinor - v),
          );
        }(),
    ];

    classSlices.add(
      InvestmentClassSlice(
        id: root.id,
        name: root.name,
        iconKey: root.iconKey,
        colorValue: root.colorValue,
        currentValue: money(classTotalMinor),
        currentPercent: totalMinor == 0 ? 0 : classTotalMinor / totalMinor,
        targetPercent: root.targetPercent,
        targetValue: money(targetValueMinor),
        deltaValue: money(targetValueMinor - classTotalMinor),
        subclasses: subSlices,
      ),
    );
  }
  classSlices.sort((a, b) {
    final byValue =
        b.currentValue.minorUnits.compareTo(a.currentValue.minorUnits);
    return byValue != 0 ? byValue : a.name.compareTo(b.name);
  });

  final actions = classSlices
      .where((s) => s.deltaValue.minorUnits.abs() >= _minRebalanceMinor)
      .map(
        (s) => RebalanceAction(
          classId: s.id,
          className: s.name,
          direction:
              s.isUnderTarget ? RebalanceDirection.buy : RebalanceDirection.sell,
          amount: money(s.deltaValue.minorUnits.abs()),
        ),
      )
      .toList()
    ..sort((a, b) => b.amount.minorUnits.compareTo(a.amount.minorUnits));

  final targetSum =
      classes.where((c) => c.isRoot).fold<double>(0, (s, r) => s + r.targetPercent);

  return InvestmentOverview(
    total: money(totalMinor),
    allocated: money(allocatedMinor),
    pending: money(pendingMinor),
    classes: classSlices,
    rebalanceActions: actions,
    targetSumPercent: targetSum,
  );
}
