/// Minimal RFC-4180-style CSV reader, owned by the project so no external CSV
/// dependency leaks into the codebase (CLAUDE.md → wrap/avoid external libs).
///
/// Splits [content] into rows of string cells. Handles:
/// - comma delimiters,
/// - double-quoted fields containing commas, newlines or quotes,
/// - escaped quotes inside a quoted field (`""` → `"`),
/// - both `\n` and `\r\n` line endings.
///
/// Whitespace around unquoted cells is preserved (callers trim). Trailing blank
/// lines produce no row. Returns an empty list for empty input.
///
/// Example:
/// ```dart
/// parseCsv('a,b\n1,"x,y"'); // [['a','b'], ['1','x,y']]
/// ```
List<List<String>> parseCsv(String content) {
  final rows = <List<String>>[];
  var row = <String>[];
  final cell = StringBuffer();
  var inQuotes = false;
  var sawAnyChar = false;

  void endCell() {
    row.add(cell.toString());
    cell.clear();
  }

  void endRow() {
    endCell();
    // Drop a row that is a single empty cell (a blank line), but keep rows that
    // legitimately have one empty field only when other content preceded them.
    final isBlank = row.length == 1 && row.first.isEmpty;
    if (!isBlank) rows.add(row);
    row = <String>[];
    sawAnyChar = false;
  }

  final chars = content.split('');
  for (var i = 0; i < chars.length; i++) {
    final c = chars[i];
    if (inQuotes) {
      if (c == '"') {
        final next = i + 1 < chars.length ? chars[i + 1] : '';
        if (next == '"') {
          cell.write('"');
          i++; // consume the escaped quote
        } else {
          inQuotes = false;
        }
      } else {
        cell.write(c);
      }
      continue;
    }

    if (c == '"') {
      inQuotes = true;
      sawAnyChar = true;
    } else if (c == ',') {
      endCell();
      sawAnyChar = true;
    } else if (c == '\r') {
      // swallow; the paired \n ends the row
    } else if (c == '\n') {
      endRow();
    } else {
      cell.write(c);
      sawAnyChar = true;
    }
  }

  // Flush the final row when the file does not end in a newline.
  if (sawAnyChar || cell.isNotEmpty || row.isNotEmpty) endRow();
  return rows;
}
