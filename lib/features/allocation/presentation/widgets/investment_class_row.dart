import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/app/widgets/widgets.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/core/format/currency_formatter.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/allocation/domain/entities/investment_overview.dart';
import 'package:investanco/features/allocation/presentation/allocation_visuals.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// A root-class row: icon, name, "X% de Y%", value, progress bar (current vs
/// target), and the "abaixo/acima" delta. See `docs/specs/allocation.md`.
class InvestmentClassRow extends StatelessWidget {
  /// Creates the row.
  const InvestmentClassRow({required this.slice, required this.onTap, super.key});

  /// The class slice to render.
  final InvestmentClassSlice slice;

  /// Tap handler (opens the class detail).
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tint = Color(slice.colorValue);
    final actual = (slice.currentPercent * 100).toStringAsFixed(0);
    final target = slice.targetPercent.toStringAsFixed(0);

    return InvestancoCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(iconKey: slice.iconKey, tint: tint),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slice.name,
                      style: context.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.allocation
                          .classRowSubtitle(actual: '$actual%', target: '$target%'),
                      style: context.textTheme.bodySmall
                          ?.copyWith(color: colors.onBackgroundLight),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency(slice.currentValue),
                    style: context.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _deltaLabel(),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: _deltaColor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              FaIcon(
                FontAwesomeIcons.chevronRight,
                size: 11,
                color: colors.onBackgroundLight,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _progress(),
              minHeight: 8,
              backgroundColor: colors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(tint),
            ),
          ),
        ],
      ),
    );
  }

  /// Bar fills current/target, capped at full when over target.
  double _progress() {
    final targetFraction = slice.targetPercent / 100;
    if (targetFraction <= 0) return slice.currentPercent.clamp(0.0, 1.0);
    return (slice.currentPercent / targetFraction).clamp(0.0, 1.0);
  }

  String _deltaLabel() {
    final minor = slice.deltaValue.minorUnits;
    if (minor.abs() < 100) return t.allocation.classRowOnTarget;
    final amount = formatCurrency(Money(minor.abs(), slice.deltaValue.currency));
    return slice.isUnderTarget
        ? t.allocation.classRowUnderTarget(amount: amount)
        : t.allocation.classRowOverTarget(amount: amount);
  }

  Color _deltaColor(BuildContext context) {
    final colors = context.appColors;
    if (slice.deltaValue.minorUnits.abs() < 100) return colors.positive;
    return slice.isUnderTarget ? colors.warning : colors.negative;
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.iconKey, required this.tint});

  final String iconKey;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      child: Center(child: FaIcon(allocationIcon(iconKey), size: 16, color: tint)),
    );
  }
}
