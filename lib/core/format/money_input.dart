/// Parses a major-unit decimal amount, accepting both `,` and `.` as the decimal
/// separator (e.g. "10,50" or "10.50" → 10.5) and surrounding whitespace.
/// Returns null if invalid. Used for user-typed amounts and comma/dot-tolerant
/// API values alike.
double? parseMajor(String input) =>
    double.tryParse(input.trim().replaceAll(',', '.'));
