import 'package:investanco/core/error/failures.dart';

/// A CSV parse rejection that remembers the offending row [line] (when the
/// parser tagged one), so the presentation layer can show a localized,
/// row-pointing message instead of the raw English parser text.
class CsvValidationFailure extends ValidationFailure {
  /// Wraps a parser [message]; pass the [line] it referred to, if any.
  const CsvValidationFailure(super.message, {this.line});

  /// Builds one from a raw parser message, lifting a leading `Row N:` tag into
  /// [line] (the parser messages are internal/dev-English; only the line number
  /// is surfaced to the user, localized).
  factory CsvValidationFailure.fromMessage(String message) {
    final match = RegExp(r'Row (\d+)').firstMatch(message);
    final line = match == null ? null : int.tryParse(match.group(1)!);
    return CsvValidationFailure(message, line: line);
  }

  /// 1-based row the error referred to, or null for a file-level error.
  final int? line;

  @override
  List<Object?> get props => [message, code, line];
}
