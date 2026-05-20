import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:investanco/app/widgets/widgets.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/assets/presentation/asset_labels.dart';
import 'package:investanco/features/assets/presentation/asset_visuals.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// Donut chart of value allocation by asset class, with a percentage legend.
class AllocationChart extends StatelessWidget {
  /// Creates the chart.
  const AllocationChart({required this.byClass, super.key});

  /// Value per asset class.
  final Map<AssetKind, Money> byClass;

  @override
  Widget build(BuildContext context) {
    final entries = byClass.entries
        .where((e) => e.value.minorUnits > 0)
        .toList()
      ..sort((a, b) => b.value.minorUnits.compareTo(a.value.minorUnits));
    if (entries.isEmpty) return const SizedBox.shrink();

    final totalMinor = entries.fold<int>(0, (sum, e) => sum + e.value.minorUnits);

    return InvestancoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.dashboard.allocation, style: context.textTheme.titleLarge),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 42,
                    sections: [
                      for (final e in entries)
                        PieChartSectionData(
                          value: e.value.major,
                          color: assetKindColor(e.key),
                          radius: 22,
                          showTitle: false,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    for (final e in entries)
                      _LegendRow(
                        color: assetKindColor(e.key),
                        label: assetKindLabel(e.key),
                        fraction:
                            totalMinor == 0 ? 0 : e.value.minorUnits / totalMinor,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.fraction,
  });

  final Color color;
  final String label;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.onBackgroundLight,
              ),
            ),
          ),
          Text(
            '${(fraction * 100).toStringAsFixed(0)}%',
            style: context.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
