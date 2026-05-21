import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/format/csv_parser.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/core/utils/id_generator.dart';
import 'package:investanco/features/assets/domain/asset_kind_defaults.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/assets/domain/repositories/asset_repository.dart';
import 'package:investanco/features/institutions/domain/entities/institution.dart';
import 'package:investanco/features/institutions/domain/repositories/institution_repository.dart';
import 'package:investanco/features/transactions/domain/entities/asset_transaction.dart';
import 'package:investanco/features/transactions/domain/repositories/transaction_repository.dart';

/// One parsed, not-yet-persisted CSV row: an asset plus the transaction that
/// created the position. See `docs/specs/csv_import.md`.
class PortfolioImportRow extends Equatable {
  /// Creates a row.
  const PortfolioImportRow({
    required this.ticker,
    required this.name,
    required this.kind,
    required this.market,
    required this.currency,
    required this.institutionName,
    required this.operation,
    required this.quantity,
    required this.unitPriceMajor,
    required this.feesMajor,
    required this.date,
    this.amountMajor,
    this.notes,
  });

  /// Asset symbol (uppercased), e.g. `SOXX`.
  final String ticker;

  /// Asset display name; defaults to the ticker when the column is absent.
  final String name;

  /// Asset classification.
  final AssetKind kind;

  /// Trading venue.
  final Market market;

  /// Native currency of price/fees/amount.
  final Currency currency;

  /// Custodian name; matched case-insensitively, created if missing.
  final String institutionName;

  /// buy / sell / dividend.
  final TransactionKind operation;

  /// Units (fractional allowed). 0 for dividends.
  final double quantity;

  /// Unit price in major units (e.g. dollars). 0 for dividends.
  final double unitPriceMajor;

  /// Fees in major units.
  final double feesMajor;

  /// Transaction date.
  final DateTime date;

  /// Dividend total in major units; null for buy/sell.
  final double? amountMajor;

  /// Optional note.
  final String? notes;

  @override
  List<Object?> get props => [
        ticker,
        name,
        kind,
        market,
        currency,
        institutionName,
        operation,
        quantity,
        unitPriceMajor,
        feesMajor,
        date,
        amountMajor,
        notes,
      ];
}

/// Tally of what an import created.
class PortfolioImportResult extends Equatable {
  /// Creates a result.
  const PortfolioImportResult({
    required this.institutionsCreated,
    required this.assetsCreated,
    required this.transactionsCreated,
  });

  /// New institutions created (name not seen before).
  final int institutionsCreated;

  /// New assets created (ticker not seen before).
  final int assetsCreated;

  /// Transactions created (one per row).
  final int transactionsCreated;

  @override
  List<Object?> get props =>
      [institutionsCreated, assetsCreated, transactionsCreated];
}

/// Bulk-imports a portfolio from CSV: one row → reuse-or-create the institution
/// and asset, then create one transaction. See `docs/specs/csv_import.md`.
class ImportPortfolioCsvUseCase {
  /// Creates the use case.
  const ImportPortfolioCsvUseCase(
    this._assetRepository,
    this._institutionRepository,
    this._transactionRepository,
    this._idGenerator,
  );

  final AssetRepository _assetRepository;
  final InstitutionRepository _institutionRepository;
  final TransactionRepository _transactionRepository;
  final IdGenerator _idGenerator;

  /// Parses [csv] into rows without touching persistence. A malformed file
  /// yields a [ValidationFailure] tagged with the offending row.
  Either<Failure, List<PortfolioImportRow>> parseRows(String csv) {
    try {
      return Right(_parse(csv));
    } on FormatException catch (e) {
      return Left(ValidationFailure(e.message));
    }
  }

  /// Parses then imports [csv] in one step.
  Future<Either<Failure, PortfolioImportResult>> call(String csv) async {
    return parseRows(csv).fold(
      (failure) => Future.value(Left(failure)),
      importRows,
    );
  }

  /// Persists [rows], reusing institutions (by name) and assets (by ticker)
  /// that already exist and creating the rest. Stops at the first repository
  /// failure. See `docs/specs/csv_import.md` §rules.
  Future<Either<Failure, PortfolioImportResult>> importRows(
    List<PortfolioImportRow> rows,
  ) async {
    final assets = await _assetRepository.watchAll().first;
    final institutions = await _institutionRepository.watchAll().first;

    final assetByTicker = {
      for (final a in assets) a.ticker.toLowerCase(): a,
    };
    final institutionByName = {
      for (final i in institutions) i.name.toLowerCase(): i,
    };

    final now = DateTime.now();
    var institutionsCreated = 0;
    var assetsCreated = 0;
    var transactionsCreated = 0;

    for (final row in rows) {
      final institution = institutionByName[row.institutionName.toLowerCase()];
      final resolvedInstitution = institution ??
          Institution(
            id: _idGenerator.newId(),
            name: row.institutionName,
            kind: InstitutionKind.broker,
            currency: row.currency,
            createdAt: now,
          );
      if (institution == null) {
        final failure = await _save(
          _institutionRepository.save(resolvedInstitution),
        );
        if (failure != null) return Left(failure);
        institutionByName[row.institutionName.toLowerCase()] =
            resolvedInstitution;
        institutionsCreated++;
      }

      final asset = assetByTicker[row.ticker.toLowerCase()];
      final resolvedAsset = asset ??
          Asset(
            id: _idGenerator.newId(),
            ticker: row.ticker,
            name: row.name,
            kind: row.kind,
            market: row.market,
            currency: row.currency,
            createdAt: now,
          );
      if (asset == null) {
        final failure = await _save(_assetRepository.save(resolvedAsset));
        if (failure != null) return Left(failure);
        assetByTicker[row.ticker.toLowerCase()] = resolvedAsset;
        assetsCreated++;
      }

      final failure = await _save(
        _transactionRepository.save(
          _buildTransaction(row, resolvedAsset.id, resolvedInstitution.id, now),
        ),
      );
      if (failure != null) return Left(failure);
      transactionsCreated++;
    }

    return Right(
      PortfolioImportResult(
        institutionsCreated: institutionsCreated,
        assetsCreated: assetsCreated,
        transactionsCreated: transactionsCreated,
      ),
    );
  }

  AssetTransaction _buildTransaction(
    PortfolioImportRow row,
    String assetId,
    String institutionId,
    DateTime now,
  ) {
    final currency = row.currency;
    final isDividend = row.operation == TransactionKind.dividend;
    final unitPrice = Money.fromMajor(row.unitPriceMajor, currency);
    final amount = isDividend
        ? Money.fromMajor(row.amountMajor ?? 0, currency)
        : unitPrice * row.quantity;
    return AssetTransaction(
      id: _idGenerator.newId(),
      institutionId: institutionId,
      assetId: assetId,
      kind: row.operation,
      quantity: isDividend ? 0 : row.quantity,
      unitPrice: isDividend ? Money.zero(currency) : unitPrice,
      fees: Money.fromMajor(row.feesMajor, currency),
      amount: amount,
      date: row.date,
      notes: row.notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<Failure?> _save(Future<Either<Failure, Unit>> op) async {
    final result = await op;
    return result.fold((failure) => failure, (_) => null);
  }

  // ── Parsing ────────────────────────────────────────────────────────────────

  List<PortfolioImportRow> _parse(String csv) {
    final table = parseCsv(csv.trim());
    if (table.length < 2) {
      throw const FormatException('CSV is empty or has no data rows.');
    }
    final cols = _mapHeader(table.first);
    for (final required in const ['ticker', 'kind', 'institution']) {
      if (!cols.containsKey(required)) {
        throw FormatException('CSV is missing the required "$required" column.');
      }
    }

    final rows = <PortfolioImportRow>[];
    var lineNo = 1; // header
    for (final raw in table.skip(1)) {
      lineNo++;
      if (raw.every((c) => c.trim().isEmpty)) continue; // tolerate blank lines
      rows.add(_parseRow(raw, cols, lineNo));
    }
    if (rows.isEmpty) throw const FormatException('CSV has no valid rows.');
    return rows;
  }

  PortfolioImportRow _parseRow(
    List<String> raw,
    Map<String, int> cols,
    int lineNo,
  ) {
    String cell(String key) {
      final idx = cols[key];
      if (idx == null || idx >= raw.length) return '';
      return raw[idx].trim();
    }

    final ticker = cell('ticker');
    if (ticker.isEmpty) {
      throw FormatException('Row $lineNo: empty ticker.');
    }
    final kind = _parseKind(cell('kind'), lineNo);
    final institution = cell('institution');
    if (institution.isEmpty) {
      throw FormatException('Row $lineNo: empty institution.');
    }

    final (defMarket, defCurrency) = assetKindDefaults(kind);
    final marketStr = cell('market');
    final currencyStr = cell('currency');
    final market = marketStr.isEmpty ? defMarket : _parseMarket(marketStr, lineNo);
    final currency =
        currencyStr.isEmpty ? defCurrency : _parseCurrency(currencyStr, lineNo);

    final operation = _parseOperation(cell('operation'), lineNo);
    final nameCell = cell('name');
    final dateStr = cell('date');
    final date = dateStr.isEmpty ? _today() : _parseDate(dateStr, lineNo);
    final fees = _optionalNumber(cell('fees'), lineNo, 'fees') ?? 0;
    final notes = cell('notes').isEmpty ? null : cell('notes');

    if (operation == TransactionKind.dividend) {
      final amount = _requiredNumber(cell('amount'), lineNo, 'amount');
      return PortfolioImportRow(
        ticker: ticker.toUpperCase(),
        name: nameCell.isEmpty ? ticker.toUpperCase() : nameCell,
        kind: kind,
        market: market,
        currency: currency,
        institutionName: institution,
        operation: operation,
        quantity: 0,
        unitPriceMajor: 0,
        feesMajor: fees,
        amountMajor: amount,
        date: date,
        notes: notes,
      );
    }

    final quantity = _requiredNumber(cell('quantity'), lineNo, 'quantity');
    if (quantity <= 0) {
      throw FormatException('Row $lineNo: quantity must be greater than zero.');
    }
    final price = _requiredNumber(cell('price'), lineNo, 'price');
    return PortfolioImportRow(
      ticker: ticker.toUpperCase(),
      name: nameCell.isEmpty ? ticker.toUpperCase() : nameCell,
      kind: kind,
      market: market,
      currency: currency,
      institutionName: institution,
      operation: operation,
      quantity: quantity,
      unitPriceMajor: price,
      feesMajor: fees,
      date: date,
      notes: notes,
    );
  }

  /// Resolves header cells to logical keys via accent/case-insensitive
  /// synonyms, tolerating reordered, extra or English/Portuguese columns.
  Map<String, int> _mapHeader(List<String> header) {
    const synonyms = <String, List<String>>{
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

    final out = <String, int>{};
    for (var i = 0; i < header.length; i++) {
      final norm = _normalize(header[i]);
      if (norm.isEmpty) continue;
      for (final entry in synonyms.entries) {
        if (out.containsKey(entry.key)) continue;
        if (entry.value.contains(norm)) {
          out[entry.key] = i;
          break;
        }
      }
    }
    return out;
  }

  AssetKind _parseKind(String raw, int lineNo) {
    final norm = _normalize(raw);
    if (norm.isEmpty) throw FormatException('Row $lineNo: empty kind.');
    final kind = _kindByToken[norm];
    if (kind == null) {
      throw FormatException('Row $lineNo: unknown kind "$raw".');
    }
    return kind;
  }

  Market _parseMarket(String raw, int lineNo) {
    final norm = _normalize(raw);
    return switch (norm) {
      'br' || 'brasil' || 'brazil' => Market.br,
      'us' || 'usa' || 'eua' || 'estadosunidos' => Market.us,
      'global' || 'mundial' || 'world' => Market.global,
      _ => throw FormatException('Row $lineNo: unknown market "$raw".'),
    };
  }

  Currency _parseCurrency(String raw, int lineNo) {
    final norm = _normalize(raw);
    return switch (norm) {
      'brl' || 'real' || 'reais' => Currency.brl,
      'usd' || 'dolar' || 'dollar' => Currency.usd,
      _ => throw FormatException('Row $lineNo: unknown currency "$raw".'),
    };
  }

  TransactionKind _parseOperation(String raw, int lineNo) {
    final norm = _normalize(raw);
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

  double _requiredNumber(String raw, int lineNo, String field) {
    if (raw.trim().isEmpty) {
      throw FormatException('Row $lineNo: missing $field.');
    }
    final value = _parseNumber(raw);
    if (value == null) {
      throw FormatException('Row $lineNo: invalid $field "$raw".');
    }
    return value;
  }

  double? _optionalNumber(String raw, int lineNo, String field) {
    if (raw.trim().isEmpty) return null;
    final value = _parseNumber(raw);
    if (value == null) {
      throw FormatException('Row $lineNo: invalid $field "$raw".');
    }
    return value;
  }

  /// Accepts BR (`1.234,56`) and EN (`1,234.56`) grouping; a lone separator is
  /// the decimal point. Returns the absolute value (sign carried by operation).
  double? _parseNumber(String raw) {
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
  DateTime _parseDate(String raw, int lineNo) {
    final slash = raw.split('/');
    if (slash.length == 3) {
      final d = int.tryParse(slash[0]);
      final m = int.tryParse(slash[1]);
      final y = int.tryParse(slash[2]);
      final date = _buildDate(y, m, d);
      if (date != null) return date;
    }
    final dash = raw.split('-');
    if (dash.length == 3) {
      final y = int.tryParse(dash[0]);
      final m = int.tryParse(dash[1]);
      final d = int.tryParse(dash[2]);
      final date = _buildDate(y, m, d);
      if (date != null) return date;
    }
    throw FormatException(
      'Row $lineNo: invalid date "$raw". Use DD/MM/YYYY.',
    );
  }

  DateTime? _buildDate(int? y, int? m, int? d) {
    if (y == null || m == null || d == null) return null;
    if (m < 1 || m > 12 || d < 1 || d > 31) return null;
    return DateTime(y, m, d);
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Lowercases and strips accents + every non-alphanumeric char, so
  /// `"ETF (EUA)"` → `etfeua` and `"Preço médio"` → `precomedio`.
  String _normalize(String raw) {
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

  /// Normalized token → [AssetKind]. Seeded from the enum names, then enriched
  /// with PT/EN friendly labels.
  static final Map<String, AssetKind> _kindByToken = {
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
}
