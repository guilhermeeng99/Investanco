import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/assets/presentation/asset_labels.dart';
import 'package:investanco/features/dashboard/presentation/asset_kind_color.dart';
import 'package:investanco/gen/strings.g.dart';

/// Donut chart of value allocation by asset class, with a legend.
class AllocationChart extends StatelessWidget {
  /// Creates the chart.
  const AllocationChart({required this.byClass, super.key});

  /// Value per asset class.
  final Map<AssetKind, Money> byClass;

  @override
  Widget build(BuildContext context) {
    final entries =
        byClass.entries.where((e) => e.value.minorUnits > 0).toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    final totalMinor =
        entries.fold<int>(0, (sum, e) => sum + e.value.minorUnits);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.dashboard.allocation, style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 170,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 48,
                  sections: [
                    for (final e in entries)
                      PieChartSectionData(
                        value: e.value.major,
                        color: assetKindColor(e.key),
                        radius: 38,
                        showTitle: false,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                for (final e in entries)
                  _LegendDot(
                    color: assetKindColor(e.key),
                    label: assetKindLabel(e.key),
                    fraction: totalMinor == 0 ? 0 : e.value.minorUnits / totalMinor,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    required this.fraction,
  });

  final Color color;
  final String label;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 6),
        Text('$label ${(fraction * 100).toStringAsFixed(0)}%'),
      ],
    );
  }
}
