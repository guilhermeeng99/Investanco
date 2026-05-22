import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/app/widgets/widgets.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/core/format/currency_formatter.dart';
import 'package:investanco/core/format/initials.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/assets/presentation/asset_visuals.dart';
import 'package:investanco/features/institutions/domain/entities/institution.dart';
import 'package:investanco/features/valuation/domain/entities/holding_valuation.dart';

/// Per-holding rows (open positions only), sorted by return % descending
/// (best performers first), grouped in a single card.
class HoldingsList extends StatelessWidget {
  /// Creates the list for the given valued [holdings] (the visible/filtered set).
  const HoldingsList({
    required this.holdings,
    required this.assetsById,
    required this.institutionsById,
    super.key,
  });

  /// Valued holdings to render (any quantity; closed positions are skipped here).
  final List<HoldingValuation> holdings;

  /// Assets keyed by id (for ticker/labels).
  final Map<String, Asset> assetsById;

  /// Institutions keyed by id (for the row subtitle).
  final Map<String, Institution> institutionsById;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final open = holdings.where((h) => h.quantity > 0).toList()
      ..sort((a, b) => b.returnPct.compareTo(a.returnPct));
    if (open.isEmpty) return const SizedBox.shrink();

    return InvestancoCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < open.length; i++) ...[
            if (i > 0) Divider(height: 1, color: colors.surfaceVariant),
            _HoldingTile(
              holding: open[i],
              asset: assetsById[open[i].assetId],
              institution: institutionsById[open[i].institutionId],
            ),
          ],
        ],
      ),
    );
  }
}

class _HoldingTile extends StatelessWidget {
  const _HoldingTile({
    required this.holding,
    required this.asset,
    required this.institution,
  });

  final HoldingValuation holding;
  final Asset? asset;
  final Institution? institution;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final ticker = asset?.ticker ?? holding.assetId;
    final subtitle = [
      ?institution?.name,
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
          if (holding.fxMissing)
            // No FX rate to consolidate this foreign holding → show a dash
            // instead of a bogus value. The stale clock above already warns.
            Text(
              '—',
              style: context.textTheme.titleSmall?.copyWith(
                color: colors.onBackgroundLight,
              ),
            )
          else
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MoneyText(money: holding.marketValueBase, fontSize: 15),
                // For a dollar-denominated holding, also show the native USD
                // value beneath the consolidated BRL one.
                if (holding.marketValueNative.currency !=
                    holding.marketValueBase.currency) ...[
                  const SizedBox(height: 1),
                  Text(
                    formatCurrency(holding.marketValueNative),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.onBackgroundLight,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                // Absolute unrealized P/L plus its percentage, colour-coded.
                SignedAmount(
                  money: holding.unrealizedPL,
                  percent: holding.returnPct,
                  fontSize: 12,
                  percentFontSize: 11,
                ),
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
