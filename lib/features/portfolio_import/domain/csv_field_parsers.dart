import 'package:investanco/core/format/csv_parser.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/transactions/domain/entities/asset_transaction.dart';

// Pure field parsers shared by the asset and transaction CSV parsers. Each
// throws a FormatException (which the use case maps to a ValidationFailure) on
// malformed input. See `docs/specs/csv_import.md`.

/// Reads [csv] into a table, requiring a header plus at least one data row.
List<List<String>> readCsvTable(String csv) {
  final table = parseCsv(csv.trim());
  if (table.length < 2) {
    throw const FormatException('CSV is empty or has no data rows.');
  }
  return table;
}

/// Resolves header cells to logical keys via accent/case-insensitive synonyms,
/// tolerating reordered, extra or English/Portuguese columns. The map is the
/// superset for both imports; each parser reads the columns it needs.
Map<String, int> mapCsvHeader(List<String> header) {
  final out = <String, int>{};
  for (var i = 0; i < header.length; i++) {
    final norm = normalizeCsvToken(header[i]);
    if (norm.isEmpty) continue;
    for (final entry in _synonyms.entries) {
      if (out.containsKey(entry.key)) continue;
      if (entry.value.contains(norm)) {
        out[entry.key] = i;
        break;
      }
    }
  }
  return out;
}

const _synonyms = <String, List<String>>{
  'ticker': ['ticker', 'simbolo', 'symbol', 'codigo', 'code'],
  'name': ['name', 'nome', 'descricao', 'description'],
  'kind': ['kind', 'tipo', 'classe', 'class', 'type'],
  'market': ['market', 'mercado'],
  'currency': ['currency', 'moeda'],
  'institution': [
    'institution',
    'instituicao',
    'corretora',
    'broker',
    'conta',
    'account',
  ],
  'operation': [
    'operation',
    'operacao',
    'transacao',
    'transaction',
    'side',
    'movimento',
  ],
  'quantity': ['quantity', 'quantidade', 'qtd', 'qtde', 'qty', 'shares', 'cotas'],
  'price': [
    'price',
    'preco',
    'precomedio',
    'average',
    'averageprice',
    'avg',
    'unitprice',
    'valorunitario',
    'custounitario',
  ],
  'fees': ['fees', 'taxas', 'taxa', 'custos', 'custo', 'cost'],
  'date': ['date', 'data'],
  'amount': ['amount', 'valor', 'total', 'montante'],
  'notes': ['notes', 'notas', 'observacao', 'observacoes', 'obs'],
};

/// Lowercases and strips accents + every non-alphanumeric char, so
/// `"ETF (EUA)"` → `etfeua` and `"Preço médio"` → `precomedio`.
String normalizeCsvToken(String raw) {
  const accents = {
    'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
    'é': 'e', 'è': 'e', 'ê': 'e', 'í': 'i', 'ì': 'i',
    'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ú': 'u',
    'ù': 'u', 'ü': 'u', 'ç': 'c',
  };
  final buf = StringBuffer();
  for (final ch in raw.trim().toLowerCase().split('')) {
    final mapped = accents[ch] ?? ch;
    if (RegExp('[a-z0-9]').hasMatch(mapped)) buf.write(mapped);
  }
  return buf.toString();
}

/// A required number; throws when missing or unparsable.
double requiredCsvNumber(String raw, int lineNo, String field) {
  if (raw.trim().isEmpty) {
    throw FormatException('Row $lineNo: missing $field.');
  }
  final value = parseCsvNumber(raw);
  if (value == null) {
    throw FormatException('Row $lineNo: invalid $field "$raw".');
  }
  return value;
}

/// An optional number; null when blank, throws when present-but-invalid.
double? optionalCsvNumber(String raw, int lineNo, String field) {
  if (raw.trim().isEmpty) return null;
  final value = parseCsvNumber(raw);
  if (value == null) {
    throw FormatException('Row $lineNo: invalid $field "$raw".');
  }
  return value;
}

/// Accepts BR (`1.234,56`) and EN (`1,234.56`) grouping; a lone separator is
/// the decimal point. Returns the absolute value (sign carried by operation).
double? parseCsvNumber(String raw) {
  var s = raw.replaceAll('"', '').trim();
  if (s.isEmpty) return null;
  if (s.startsWith('-')) s = s.substring(1);
  final hasComma = s.contains(',');
  final hasDot = s.contains('.');
  if (hasComma && hasDot) {
    s = s.lastIndexOf(',') > s.lastIndexOf('.')
        ? s.replaceAll('.', '').replaceAll(',', '.') // BR: 1.234,56
        : s.replaceAll(',', ''); // EN: 1,234.56
  } else if (hasComma) {
    s = s.replaceAll(',', '.');
  }
  return double.tryParse(s);
}

/// Accepts `DD/MM/YYYY` and `YYYY-MM-DD`.
DateTime parseCsvDate(String raw, int lineNo) {
  final slash = raw.split('/');
  if (slash.length == 3) {
    final date = _buildDate(
      int.tryParse(slash[2]),
      int.tryParse(slash[1]),
      int.tryParse(slash[0]),
    );
    if (date != null) return date;
  }
  final dash = raw.split('-');
  if (dash.length == 3) {
    final date = _buildDate(
      int.tryParse(dash[0]),
      int.tryParse(dash[1]),
      int.tryParse(dash[2]),
    );
    if (date != null) return date;
  }
  throw FormatException('Row $lineNo: invalid date "$raw". Use DD/MM/YYYY.');
}

DateTime? _buildDate(int? y, int? m, int? d) {
  if (y == null || m == null || d == null) return null;
  if (m < 1 || m > 12 || d < 1 || d > 31) return null;
  return DateTime(y, m, d);
}

/// Today at midnight, the default transaction date.
DateTime csvToday() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// Parses an [AssetKind] from the enum name or a friendly PT/EN label.
AssetKind parseAssetKind(String raw, int lineNo) {
  final norm = normalizeCsvToken(raw);
  if (norm.isEmpty) throw FormatException('Row $lineNo: empty kind.');
  final kind = _kindByToken[norm];
  if (kind == null) {
    throw FormatException('Row $lineNo: unknown kind "$raw".');
  }
  return kind;
}

/// Parses a [Market]; throws on an unknown token.
Market parseMarket(String raw, int lineNo) {
  return switch (normalizeCsvToken(raw)) {
    'br' || 'brasil' || 'brazil' => Market.br,
    'us' || 'usa' || 'eua' || 'estadosunidos' => Market.us,
    'global' || 'mundial' || 'world' => Market.global,
    _ => throw FormatException('Row $lineNo: unknown market "$raw".'),
  };
}

/// Parses a [Currency]; throws on an unknown token.
Currency parseCurrency(String raw, int lineNo) {
  return switch (normalizeCsvToken(raw)) {
    'brl' || 'real' || 'reais' => Currency.brl,
    'usd' || 'dolar' || 'dollar' => Currency.usd,
    _ => throw FormatException('Row $lineNo: unknown currency "$raw".'),
  };
}

/// Parses a [TransactionKind]; defaults to buy when blank.
TransactionKind parseOperation(String raw, int lineNo) {
  final norm = normalizeCsvToken(raw);
  if (norm.isEmpty) return TransactionKind.buy;
  return switch (norm) {
    'buy' || 'compra' || 'c' => TransactionKind.buy,
    'sell' || 'venda' || 'v' => TransactionKind.sell,
    'dividend' ||
    'dividendo' ||
    'dividendos' ||
    'provento' ||
    'proventos' ||
    'div' =>
      TransactionKind.dividend,
    _ => throw FormatException('Row $lineNo: unknown operation "$raw".'),
  };
}

/// Normalized token → [AssetKind]. Enum names plus PT/EN friendly labels.
final Map<String, AssetKind> _kindByToken = {
  for (final k in AssetKind.values) k.name.toLowerCase(): k,
  'acaobr': AssetKind.stockBr,
  'acaobrasil': AssetKind.stockBr,
  'acaous': AssetKind.stockUs,
  'acaoeua': AssetKind.stockUs,
  'fii': AssetKind.fiiBr,
  'reit': AssetKind.fiiBr,
  'etfeua': AssetKind.etfUs,
  'bdr': AssetKind.bdrBr,
  'cripto': AssetKind.crypto,
  'criptomoeda': AssetKind.crypto,
  'tesouro': AssetKind.treasury,
  'tesourodireto': AssetKind.treasury,
  'rendafixa': AssetKind.fixedIncome,
  'fundo': AssetKind.fund,
  'caixa': AssetKind.cash,
  'dinheiro': AssetKind.cash,
};
