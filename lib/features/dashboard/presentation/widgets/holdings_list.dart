import 'package:flutter/material.dart';
import 'package:investanco/app/theme/app_colors.dart';
import 'package:investanco/core/format/currency_formatter.dart';
import 'package:investanco/features/dashboard/presentation/cubit/dashboard_state.dart';
import 'package:investanco/features/valuation/domain/entities/holding_valuation.dart';

/// Per-holding rows (open positions only), sorted by value descending.
class HoldingsList extends StatelessWidget {
  /// Creates the list.
  const HoldingsList({required this.state, super.key});

  /// The loaded dashboard state.
  final DashboardLoaded state;

  @override
  Widget build(BuildContext context) {
    final holdings = state.portfolio.holdings
        .where((h) => h.quantity > 0)
        .toList()
      ..sort(
        (a, b) =>
            b.marketValueBase.minorUnits.compareTo(a.marketValueBase.minorUnits),
      );

    return Column(
      children: [for (final holding in holdings) _HoldingTile(holding, state)],
    );
  }
}

class _HoldingTile extends StatelessWidget {
  const _HoldingTile(this.holding, this.state);

  final HoldingValuation holding;
  final DashboardLoaded state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asset = state.assetsById[holding.assetId];
    final institution = state.institutionsById[holding.institutionId];
    final color = holding.unrealizedPL.isZero
        ? AppColors.neutral
        : holding.unrealizedPL.isNegative
            ? AppColors.negative
            : AppColors.positive;

    return ListTile(
      title: Row(
        children: [
          Expanded(child: Text(asset?.ticker ?? holding.assetId)),
          if (holding.priceStale)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.schedule, size: 14),
            ),
        ],
      ),
      subtitle: Text(
        '${institution?.name ?? '—'} · ${_quantity(holding.quantity)}',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatCurrency(holding.marketValueBase),
            style: theme.textTheme.titleSmall,
          ),
          Text(
            formatPercent(holding.returnPct),
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  String _quantity(double quantity) =>
      quantity == quantity.roundToDouble()
          ? quantity.toStringAsFixed(0)
          : quantity.toString();
}
