import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:investanco/app/theme/app_typography.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/core/format/currency_formatter.dart';
import 'package:investanco/features/allocation/domain/entities/investment_overview.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// Donut of current allocation by class, with the unallocated remainder as a
/// muted slice, and the total invested in the center.
class AllocationClassDonut extends StatelessWidget {
  /// Creates the donut.
  const AllocationClassDonut({required this.overview, super.key});

  /// The computed overview.
  final InvestmentOverview overview;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final sections = <PieChartSectionData>[
      for (final s in overview.classes)
        if (s.currentValue.minorUnits > 0)
          PieChartSectionData(
            value: s.currentValue.minorUnits.toDouble(),
            color: Color(s.colorValue),
            radius: 18,
            showTitle: false,
          ),
    ];
    if (overview.pending.minorUnits > 0) {
      sections.add(
        PieChartSectionData(
          value: overview.pending.minorUnits.toDouble(),
          color: colors.surfaceVariant,
          radius: 18,
          showTitle: false,
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (sections.isNotEmpty)
            PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 78,
                sectionsSpace: 2,
                startDegreeOffset: -90,
              ),
            ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t.allocation.heroTitle,
                style: context.textTheme.labelSmall
                    ?.copyWith(color: colors.onBackgroundLight),
              ),
              const SizedBox(height: 4),
              Text(
                formatCurrency(overview.total),
                style: AppTypography.amount(color: colors.onBackground),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
