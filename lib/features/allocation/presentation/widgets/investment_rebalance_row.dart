import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/core/format/currency_formatter.dart';
import 'package:investanco/features/allocation/domain/entities/investment_overview.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// One rebalancing step: buy (green, up) when under target, sell (amber, down)
/// when over. See `docs/specs/allocation.md`.
class InvestmentRebalanceRow extends StatelessWidget {
  /// Creates the row.
  const InvestmentRebalanceRow({required this.action, super.key});

  /// The action to render.
  final RebalanceAction action;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isBuy = action.direction == RebalanceDirection.buy;
    final tint = isBuy ? colors.positive : colors.warning;
    final icon = isBuy ? FontAwesomeIcons.arrowUp : FontAwesomeIcons.arrowDown;
    final label = isBuy
        ? t.allocation.rebalanceBuy(
            amount: formatCurrency(action.amount),
            className: action.className,
          )
        : t.allocation.rebalanceSell(
            amount: formatCurrency(action.amount),
            className: action.className,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Center(child: FaIcon(icon, size: 12, color: tint)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: context.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
