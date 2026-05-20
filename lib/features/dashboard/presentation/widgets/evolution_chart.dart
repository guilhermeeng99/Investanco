import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:investanco/features/snapshots/domain/entities/snapshot.dart';
import 'package:investanco/gen/strings.g.dart';

/// Line chart of total portfolio value over time (from daily snapshots).
/// Hidden until there are at least two data points.
class EvolutionChart extends StatelessWidget {
  /// Creates the chart.
  const EvolutionChart({required this.snapshots, super.key});

  /// Daily snapshots, oldest first.
  final List<Snapshot> snapshots;

  @override
  Widget build(BuildContext context) {
    if (snapshots.length < 2) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final spots = [
      for (var i = 0; i < snapshots.length; i++)
        FlSpot(i.toDouble(), snapshots[i].totalValue.major),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.dashboard.evolution, style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: theme.colorScheme.primary,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
