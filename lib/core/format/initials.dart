/// First letters of a [ticker] for avatar display: up to 4 upper-cased chars.
///
/// Example: `tickerInitials('petr4') // 'PETR'`
String tickerInitials(String ticker) {
  final clean = ticker.trim().toUpperCase();
  return clean.length <= 4 ? clean : clean.substring(0, 4);
}
