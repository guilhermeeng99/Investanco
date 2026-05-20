/// Parses a user-typed major-unit amount, accepting both `,` and `.` as the
/// decimal separator (e.g. "10,50" or "10.50" → 10.5). Returns null if invalid.
double? parseMajor(String input) =>
    double.tryParse(input.trim().replaceAll(',', '.'));
