import 'package:dartz/dartz.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/core/utils/id_generator.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/assets/domain/repositories/asset_repository.dart';
import 'package:investanco/features/institutions/domain/entities/institution.dart';
import 'package:investanco/features/institutions/domain/repositories/institution_repository.dart';
import 'package:investanco/features/portfolio_import/domain/csv_validation_failure.dart';
import 'package:investanco/features/portfolio_import/domain/transaction_csv_parser.dart';
import 'package:investanco/features/portfolio_import/domain/transaction_import_models.dart';
import 'package:investanco/features/transactions/domain/entities/asset_transaction.dart';
import 'package:investanco/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:investanco/features/transactions/domain/transaction_amounts.dart';

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
      return Left(CsvValidationFailure.fromMessage(e.message));
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
    final assetByTicker = {for (final a in assets) a.ticker.toLowerCase(): a};
    final institutionById = {for (final i in institutions) i.id: i};
    return TransactionImportPreview(
      rows: [
        for (final row in rows)
          _previewRow(row, assetByTicker, institutionById),
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
    final institutionById = {for (final i in institutions) i.id: i};

    // Persist oldest-first (buys before sells on a date tie) so the repository's
    // per-save oversell guard sees each sell's covering buys already stored.
    final ordered = [...rows]..sort(_byDateThenBuyFirst);

    final now = DateTime.now();
    var transactionsCreated = 0;

    for (final row in ordered) {
      final asset = assetByTicker[row.ticker.toLowerCase()];
      if (asset == null) {
        return Left(ValidationFailure('Asset not found: ${row.ticker}'));
      }

      final institutionId = asset.institutionId?.trim();
      final resolvedInstitution = institutionId == null
          ? null
          : institutionById[institutionId];
      if (institutionId == null ||
          institutionId.isEmpty ||
          resolvedInstitution == null) {
        return const Left(
          ValidationFailure(
            'The asset must be linked to an institution first.',
            ValidationCode.assetInstitutionRequired,
          ),
        );
      }
      if (resolvedInstitution.name.toLowerCase() !=
          row.institutionName.toLowerCase()) {
        return const Left(
          ValidationFailure(
            'The transaction institution must match the asset institution.',
            ValidationCode.transactionInstitutionMismatch,
          ),
        );
      }

      final failure = await _save(
        _transactionRepository.save(
          _buildTransaction(row, asset, institutionId, now),
        ),
      );
      if (failure != null) return Left(failure);
      transactionsCreated++;
    }

    return Right(
      TransactionImportResult(
        transactionsCreated: transactionsCreated,
        institutionsCreated: 0,
      ),
    );
  }

  TransactionImportPreviewRow _previewRow(
    TransactionImportRow row,
    Map<String, Asset> assetByTicker,
    Map<String, Institution> institutionById,
  ) {
    final asset = assetByTicker[row.ticker.toLowerCase()];
    final institutionId = asset?.institutionId;
    final institution = institutionId == null
        ? null
        : institutionById[institutionId];
    final assetExists = asset != null;
    final assetHasInstitution = assetExists && institution != null;
    final institutionMatchesAsset =
        institution != null &&
        institution.name.toLowerCase() == row.institutionName.toLowerCase();
    return TransactionImportPreviewRow(
      row: row,
      assetExists: assetExists,
      institutionIsNew: false,
      assetHasInstitution: assetHasInstitution,
      institutionMatchesAsset: institutionMatchesAsset,
    );
  }

  AssetTransaction _buildTransaction(
    TransactionImportRow row,
    Asset asset,
    String institutionId,
    DateTime now,
  ) {
    final currency = asset.currency;
    final amounts = resolveTransactionAmounts(
      kind: row.operation,
      quantity: row.quantity,
      unitPrice: Money.fromMajor(row.unitPriceMajor, currency),
      amount: Money.fromMajor(row.amountMajor ?? 0, currency),
      currency: currency,
    );
    return AssetTransaction(
      id: _idGenerator.newId(),
      institutionId: institutionId,
      assetId: asset.id,
      kind: row.operation,
      quantity: amounts.quantity,
      unitPrice: amounts.unitPrice,
      fees: Money.fromMajor(row.feesMajor, currency),
      amount: amounts.amount,
      date: row.date,
      notes: row.notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<Failure?> _save(Future<Either<Failure, Unit>> op) async =>
      (await op).failureOrNull;
}

int _byDateThenBuyFirst(TransactionImportRow a, TransactionImportRow b) {
  final byDate = a.date.compareTo(b.date);
  if (byDate != 0) return byDate;
  return transactionKindRank(a.operation).compareTo(
    transactionKindRank(b.operation),
  );
}
