import 'package:investanco/core/money/currency.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// Localized label for a [Currency] (e.g. "Real (BRL)").
String currencyLabel(Currency currency) => switch (currency) {
      Currency.brl => t.currencies.brl,
      Currency.usd => t.currencies.usd,
    };
