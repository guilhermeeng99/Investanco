import 'package:dartz/dartz.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/core/utils/id_generator.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/assets/domain/repositories/asset_repository.dart';
import 'package:investanco/features/institutions/domain/entities/institution.dart';
import 'package:investanco/features/institutions/domain/repositories/institution_repository.dart';
import 'package:investanco/features/portfolio_import/domain/transaction_csv_parser.dart';
import 'package:investanco/features/portfolio_import/domain/transaction_import_models.dart';
import 'package:investanco/features/transactions/domain/entities/asset_transaction.dart';
import 'package:investanco/features/transactions/domain/repositories/transaction_repository.dart';

export 'package:investanco/features/portfolio_import/domain/transaction_import_models.dart';

/// Bulk-imports transactions from a CSV. Each row links to an existing asset
/// (by ticker — required) and an institution (by name — created if missing,
/// taking the asset's currency). The transaction's money is denominated in the
/// asset's currency. See `docs/specs/csv_import.md`.
class ImportTransactionsCsvUseCase {
  /// Creates the use case.
  const ImportTransactionsCsvUseCase(
    this._assetRepository,
    this._institutionRepository,
    this._transactionRepository,
    this._idGenerator,
  );

  final AssetRepository _assetRepository;
  final InstitutionRepository _institutionRepository;
  final TransactionRepository _transactionRepository;
  final IdGenerator _idGenerator;

  /// Parses [csv] into rows. A malformed file → [ValidationFailure].
  Either<Failure, List<TransactionImportRow>> parseRows(String csv) {
    try {
      return Right(parseTransactionsCsv(csv));
    } on FormatException catch (e) {
      return Left(ValidationFailure(e.message));
    }
  }

  /// Resolves each row's asset (by ticker) and institution (by name) against
  /// what's stored, flagging missing assets and new institutions — without
  /// writing anything.
  Future<TransactionImportPreview> previewRows(
    List<TransactionImportRow> rows,
  ) async {
    final assets = await _assetRepository.watchAll().first;
    final institutions = await _institutionRepository.watchAll().first;
    final tickers = {for (final a in assets) a.ticker.toLowerCase()};
    final names = {for (final i in institutions) i.name.toLowerCase()};
    return TransactionImportPreview(
      rows: [
        for (final row in rows)
          TransactionImportPreviewRow(
            row: row,
            assetExists: tickers.contains(row.ticker.toLowerCase()),
            institutionIsNew: !names.contains(row.institutionName.toLowerCase()),
          ),
      ],
    );
  }

  /// Persists [rows]: reuse-or-create the institution, then create one
  /// transaction per row, linked to the existing asset. A row whose asset is
  /// missing returns a [ValidationFailure] (the preview blocks this upstream).
  /// Stops at the first repository failure.
  Future<Either<Failure, TransactionImportResult>> importRows(
    List<TransactionImportRow> rows,
  ) async {
    final List<Asset> assets;
    final List<Institution> institutions;
    try {
      assets = await _assetRepository.watchAll().first;
      institutions = await _institutionRepository.watchAll().first;
    } on Exception {
      return const Left(
        CacheFailure('Could not read existing portfolio data.'),
      );
    }
    final assetByTicker = {for (final a in assets) a.ticker.toLowerCase(): a};
    final institutionByName = {
      for (final i in institutions) i.name.toLowerCase(): i,
    };

    final now = DateTime.now();
    var transactionsCreated = 0;
    var institutionsCreated = 0;

    for (final row in rows) {
      final asset = assetByTicker[row.ticker.toLowerCase()];
      if (asset == null) {
        return Left(ValidationFailure('Asset not found: ${row.ticker}'));
      }

      final institution = institutionByName[row.institutionName.toLowerCase()];
      final resolvedInstitution = institution ??
          Institution(
            id: _idGenerator.newId(),
            name: row.institutionName,
            kind: InstitutionKind.broker,
            currency: asset.currency,
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

      final failure = await _save(
        _transactionRepository.save(
          _buildTransaction(row, asset, resolvedInstitution.id, now),
        ),
      );
      if (failure != null) return Left(failure);
      transactionsCreated++;
    }

    return Right(
      TransactionImportResult(
        transactionsCreated: transactionsCreated,
        institutionsCreated: institutionsCreated,
      ),
    );
  }

  AssetTransaction _buildTransaction(
    TransactionImportRow row,
    Asset asset,
    String institutionId,
    DateTime now,
  ) {
    final currency = asset.currency;
    final isDividend = row.operation == TransactionKind.dividend;
    final unitPrice = Money.fromMajor(row.unitPriceMajor, currency);
    final amount = isDividend
        ? Money.fromMajor(row.amountMajor ?? 0, currency)
        : unitPrice * row.quantity;
    return AssetTransaction(
      id: _idGenerator.newId(),
      institutionId: institutionId,
      assetId: asset.id,
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
}
