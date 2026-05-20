import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:investanco/app/widgets/widgets.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/features/snapshots/domain/entities/snapshot.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// Area chart of total portfolio value over time (from daily snapshots).
/// Hidden until there are at least two data points.
class EvolutionChart extends StatelessWidget {
  /// Creates the chart.
  const EvolutionChart({required this.snapshots, super.key});

  /// Daily snapshots, oldest first.
  final List<Snapshot> snapshots;

  @override
  Widget build(BuildContext context) {
    if (snapshots.length < 2) return const SizedBox.shrink();
    final colors = context.appColors;
    final spots = [
      for (var i = 0; i < snapshots.length; i++)
        FlSpot(i.toDouble(), snapshots[i].totalValue.major),
    ];

    return InvestancoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.dashboard.evolution, style: context.textTheme.titleLarge),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    barWidth: 3,
                    color: colors.primary,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colors.primary.withValues(alpha: 0.24),
                          colors.primary.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
