import 'dart:convert';

/// Decodes raw CSV [bytes] to text, tolerating the two encodings spreadsheet
/// exports use in practice: UTF-8 (the modern default) and Windows-1252 /
/// Latin-1 (what Brazilian Excel still emits). Strips a leading UTF-8 BOM, then
/// tries strict UTF-8; on invalid byte sequences it falls back to Latin-1 so
/// accented names (e.g. "Instituição") survive instead of throwing a
/// `FormatException` or turning into `�` replacement characters.
///
/// Never throws — a file picked through the import flow always yields *some*
/// text, which the parser then validates.
///
/// Example:
/// ```dart
/// final csv = decodeCsvBytes(file.bytes!); // safe for UTF-8 or Latin-1
/// ```
String decodeCsvBytes(List<int> bytes) {
  final data = _stripBom(bytes);
  try {
    return const Utf8Decoder().convert(data);
  } on FormatException {
    return const Latin1Decoder(allowInvalid: true).convert(data);
  }
}

/// Drops a leading UTF-8 byte-order mark (`EF BB BF`) that Excel prepends, so
/// the first header cell isn't polluted with an invisible character.
List<int> _stripBom(List<int> bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xEF &&
      bytes[1] == 0xBB &&
      bytes[2] == 0xBF) {
    return bytes.sublist(3);
  }
  return bytes;
}
