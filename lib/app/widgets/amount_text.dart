import 'package:flutter/material.dart';
import 'package:investanco/app/theme/app_typography.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/core/format/currency_formatter.dart';
import 'package:investanco/core/money/money.dart';

/// Renders a [Money] value with the Poppins numeric style. Neutral by default
/// (use it for totals like net worth or invested capital). For signed,
/// colour-coded values (P/L, day change) use [SignedAmount].
class MoneyText extends StatelessWidget {
  /// Creates a money label.
  const MoneyText({
    required this.money,
    this.fontSize = 18,
    this.color,
    super.key,
  });

  /// The amount to render.
  final Money money;

  /// Font size.
  final double fontSize;

  /// Optional override colour; defaults to the primary text colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      formatCurrency(money),
      style: AppTypography.amount(
        color: color ?? context.appColors.onBackground,
        fontSize: fontSize,
      ),
    );
  }
}

/// A signed, colour-coded monetary delta: green for gains, red for losses,
/// neutral for zero, with a leading `+` on positives. Optionally appends the
/// matching percentage (e.g. `+R$1.234,50 (+12,30%)`).
class SignedAmount extends StatelessWidget {
  /// Creates a signed amount.
  const SignedAmount({
    required this.money,
    this.percent,
    this.fontSize = 16,
    this.percentFontSize,
    super.key,
  });

  /// The signed amount; sign drives the colour.
  final Money money;

  /// Optional return ratio shown in parentheses (0.12 renders `+12,00%`).
  final double? percent;

  /// Font size of the amount.
  final double fontSize;

  /// Font size of the trailing percentage; defaults to [fontSize] minus 2.
  final double? percentFontSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = money.isZero
        ? colors.neutral
        : money.isNegative
            ? colors.negative
            : colors.positive;

    // NumberFormat already prefixes negatives with a minus; only positives
    // need an explicit '+' to read as a signed delta.
    final formatted = formatCurrency(money);
    final amountText = money.minorUnits > 0 ? '+$formatted' : formatted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          amountText,
          style: AppTypography.amount(color: color, fontSize: fontSize),
        ),
        if (percent != null) ...[
          const SizedBox(width: 6),
          Text(
            '(${formatPercent(percent!)})',
            style: AppTypography.amount(
              color: color,
              fontSize: percentFontSize ?? (fontSize - 2),
            ),
          ),
        ],
      ],
    );
  }
}
