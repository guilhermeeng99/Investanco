import 'package:flutter/material.dart';
import 'package:investanco/app/theme/app_colors.dart';
import 'package:investanco/core/format/currency_formatter.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/valuation/domain/entities/portfolio_valuation.dart';
import 'package:investanco/gen/strings.g.dart';

/// Headline card: total equity, unrealized P/L and the day's change.
class PortfolioSummaryCard extends StatelessWidget {
  /// Creates the card.
  const PortfolioSummaryCard({required this.portfolio, super.key});

  /// The valued portfolio.
  final PortfolioValuation portfolio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.dashboard.total, style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              formatCurrency(portfolio.totalValueBase),
              style: theme.textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: t.dashboard.profit,
                    value: formatCurrency(portfolio.totalUnrealizedPL),
                    secondary: formatPercent(portfolio.totalReturnPct),
                    color: _signColor(portfolio.totalUnrealizedPL),
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: t.dashboard.dayChange,
                    value: formatCurrency(portfolio.totalDayChangeBase),
                    color: _signColor(portfolio.totalDayChangeBase),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _signColor(Money value) {
    if (value.isZero) return AppColors.neutral;
    return value.isNegative ? AppColors.negative : AppColors.positive;
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
    this.secondary,
  });

  final String label;
  final String value;
  final String? secondary;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleMedium
              ?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
        if (secondary != null)
          Text(secondary!, style: theme.textTheme.bodySmall?.copyWith(color: color)),
      ],
    );
  }
}
