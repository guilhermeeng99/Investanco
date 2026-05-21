import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/app/widgets/widgets.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/core/format/initials.dart';
import 'package:investanco/features/assets/presentation/asset_visuals.dart';
import 'package:investanco/features/dashboard/presentation/cubit/dashboard_state.dart';
import 'package:investanco/features/valuation/domain/entities/holding_valuation.dart';

/// Per-holding rows (open positions only), sorted by value descending,
/// grouped in a single card.
class HoldingsList extends StatelessWidget {
  /// Creates the list.
  const HoldingsList({required this.state, super.key});

  /// The loaded dashboard state.
  final DashboardLoaded state;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final holdings = state.portfolio.holdings
        .where((h) => h.quantity > 0)
        .toList()
      ..sort(
        (a, b) => b.marketValueBase.minorUnits
            .compareTo(a.marketValueBase.minorUnits),
      );
    if (holdings.isEmpty) return const SizedBox.shrink();

    return InvestancoCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < holdings.length; i++) ...[
            if (i > 0) Divider(height: 1, color: colors.surfaceVariant),
            _HoldingTile(holding: holdings[i], state: state),
          ],
        ],
      ),
    );
  }
}

class _HoldingTile extends StatelessWidget {
  const _HoldingTile({required this.holding, required this.state});

  final HoldingValuation holding;
  final DashboardLoaded state;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final asset = state.assetsById[holding.assetId];
    final institution = state.institutionsById[holding.institutionId];
    final ticker = asset?.ticker ?? holding.assetId;
    final subtitle = [
      if (institution != null) institution.name,
      _quantity(holding.quantity),
    ].join('  ·  ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          BrandAvatar(
            background: assetKindColor(holding.assetKind),
            initials: tickerInitials(ticker),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        ticker,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.titleSmall,
                      ),
                    ),
                    if (holding.priceStale) ...[
                      const SizedBox(width: 6),
                      FaIcon(
                        FontAwesomeIcons.clock,
                        size: 11,
                        color: colors.onBackgroundLight,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.onBackgroundLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MoneyText(money: holding.marketValueBase, fontSize: 15),
              const SizedBox(height: 2),
              PercentText(ratio: holding.returnPct, fontSize: 12),
            ],
          ),
        ],
      ),
    );
  }

  String _quantity(double quantity) => quantity == quantity.roundToDouble()
      ? quantity.toStringAsFixed(0)
      : quantity.toString();
}
