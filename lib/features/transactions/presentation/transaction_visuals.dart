import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/app/theme/app_colors.dart';
import 'package:investanco/features/transactions/domain/entities/asset_transaction.dart';

/// Glyph per transaction kind, used in list avatars and the kind toggle.
FaIconData transactionKindIcon(TransactionKind kind) => switch (kind) {
      TransactionKind.buy => FontAwesomeIcons.arrowDown,
      TransactionKind.sell => FontAwesomeIcons.arrowUp,
      TransactionKind.dividend => FontAwesomeIcons.sackDollar,
    };

/// Semantic accent per kind: buys spend (negative), sells and dividends bring
/// money in (positive / accent). Resolved against the active [colors].
Color transactionKindColor(TransactionKind kind, AppColorsData colors) =>
    switch (kind) {
      TransactionKind.buy => colors.negative,
      TransactionKind.sell => colors.positive,
      TransactionKind.dividend => colors.secondary,
    };

/// The sign money of [kind] moves in the portfolio: buys leave (-1), sells and
/// dividends arrive (+1).
int transactionKindSign(TransactionKind kind) =>
    kind == TransactionKind.buy ? -1 : 1;
