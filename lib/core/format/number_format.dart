/// Formats [value] without a trailing `.0`: a whole number drops the decimals
/// (`3.0` → "3"), otherwise keeps its natural decimal form (`3.5` → "3.5"). Used
/// for quantities and contracted rates, where a `.0` reads as noise.
String formatTrimmedDouble(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toString();
