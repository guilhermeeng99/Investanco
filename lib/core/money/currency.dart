/// Currencies the app can hold and consolidate. BRL is the default base.
enum Currency {
  brl('BRL', r'R$', 'pt_BR'),
  usd('USD', r'$', 'en_US');

  const Currency(this.code, this.symbol, this.locale);

  /// ISO 4217 code (e.g. `BRL`).
  final String code;

  /// Display symbol (e.g. `R$`).
  final String symbol;

  /// Locale used for number formatting (e.g. `pt_BR`).
  final String locale;
}
