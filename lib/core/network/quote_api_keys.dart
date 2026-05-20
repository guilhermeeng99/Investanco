/// Mutable holder for optional market-data API tokens. Populated from settings
/// at startup and whenever they change, and read by the quote adapters at fetch
/// time (so a key entered in Settings takes effect without a restart).
class QuoteApiKeys {
  /// Creates the holder.
  QuoteApiKeys({this.finnhubToken});

  /// Finnhub API token (US equities/ETFs). Null/empty disables US pricing.
  String? finnhubToken;
}
