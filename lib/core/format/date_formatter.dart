import 'package:intl/intl.dart';

/// Formats [date] as `dd/MM/yyyy` for display (day-first, zero-padded).
///
/// Example: `formatShortDate(DateTime(2026, 5, 9)) // '09/05/2026'`
String formatShortDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);
