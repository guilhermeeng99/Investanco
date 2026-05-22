import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/app/theme/app_colors.dart';
import 'package:investanco/app/theme/app_typography.dart';
import 'package:investanco/app/widgets/widgets.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/core/format/currency_formatter.dart';
import 'package:investanco/features/valuation/domain/entities/portfolio_valuation.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// Headline of the dashboard: a gradient hero with total equity and overall
/// return, followed by a metrics card (invested, unrealized P/L, day change).
class PortfolioSummaryCard extends StatelessWidget {
  /// Creates the card.
  const PortfolioSummaryCard({required this.portfolio, super.key});

  /// The valued portfolio.
  final PortfolioValuation portfolio;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Hero(portfolio: portfolio),
        const SizedBox(height: 12),
        _Metrics(portfolio: portfolio),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.portfolio});

  final PortfolioValuation portfolio;

  @override
  Widget build(BuildContext context) {
    final ret = portfolio.totalReturnPct;
    final up = ret >= 0;
    // Native subtotals for the non-base (dollar) slice, so the user sees how much
    // of the total is in dollars, in dollars.
    final base = portfolio.totalValueBase.currency;
    final foreign = [
      for (final e in portfolio.byCurrency.entries)
        if (e.key != base && e.value.minorUnits > 0) e.value,
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.seed, Color(0xFF007A4D)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.dashboard.total,
            style: context.textTheme.labelLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formatCurrency(portfolio.totalValueBase),
            style: AppTypography.amount(color: Colors.white, fontSize: 34),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(
                  up
                      ? FontAwesomeIcons.arrowTrendUp
                      : FontAwesomeIcons.arrowTrendDown,
                  size: 12,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  formatPercent(ret),
                  style: context.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          for (final money in foreign) ...[
            const SizedBox(height: 12),
            Text(
              '${t.dashboard.inForeign}  ·  ${formatCurrency(money)}',
              style: context.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.portfolio});

  final PortfolioValuation portfolio;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InvestancoCard(
      child: Row(
        children: [
          Expanded(
            child: MetricTile(
              label: t.dashboard.invested,
              value: MoneyText(
                money: portfolio.totalInvestedBase,
                fontSize: 15,
              ),
            ),
          ),
          _divider(colors.surfaceVariant),
          Expanded(
            child: MetricTile(
              label: t.dashboard.profit,
              value: SignedAmount(
                money: portfolio.totalUnrealizedPL,
                fontSize: 15,
              ),
            ),
          ),
          _divider(colors.surfaceVariant),
          Expanded(
            child: MetricTile(
              label: t.dashboard.dayChange,
              value: SignedAmount(
                money: portfolio.totalDayChangeBase,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(Color color) => Container(
        width: 1,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: color,
      );
}
