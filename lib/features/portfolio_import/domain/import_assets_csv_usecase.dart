import 'package:dartz/dartz.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/utils/id_generator.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/assets/domain/repositories/asset_repository.dart';
import 'package:investanco/features/institutions/domain/entities/institution.dart';
import 'package:investanco/features/institutions/domain/repositories/institution_repository.dart';
import 'package:investanco/features/portfolio_import/domain/asset_csv_parser.dart';
import 'package:investanco/features/portfolio_import/domain/asset_import_models.dart';
import 'package:investanco/features/portfolio_import/domain/csv_validation_failure.dart';

export 'package:investanco/features/portfolio_import/domain/asset_import_models.dart';

/// Bulk-imports assets (instruments only) from a CSV: one row → reuse-or-create
/// an asset, matched by ticker. No transactions, no institutions. See
/// `docs/specs/csv_import.md`.
class ImportAssetsCsvUseCase {
  /// Creates the use case.
  const ImportAssetsCsvUseCase(
    this._assetRepository,
    this._institutionRepository,
    this._idGenerator,
  );

  final AssetRepository _assetRepository;
  final InstitutionRepository _institutionRepository;
  final IdGenerator _idGenerator;

  /// Parses [csv] into rows. A malformed file → [ValidationFailure].
  Either<Failure, List<AssetImportRow>> parseRows(String csv) {
    try {
      return Right(parseAssetsCsv(csv));
    } on FormatException catch (e) {
      return Left(CsvValidationFailure.fromMessage(e.message));
    }
  }

  /// Tags each row as new vs. reused (by ticker) without writing anything.
  Future<AssetImportPreview> previewRows(List<AssetImportRow> rows) async {
    final assets = await _assetRepository.watchAll().first;
    final existing = {for (final a in assets) a.ticker.toLowerCase()};
    return AssetImportPreview(
      rows: [
        for (final row in rows)
          AssetImportPreviewRow(
            row: row,
            isNew: !existing.contains(row.ticker.toLowerCase()),
          ),
      ],
    );
  }

  /// Persists [rows], creating assets whose ticker isn't already registered and
  /// skipping the rest. Stops at the first repository failure.
  Future<Either<Failure, AssetImportResult>> importRows(
    List<AssetImportRow> rows,
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
    final byTicker = {for (final a in assets) a.ticker.toLowerCase(): a};
    final institutionByName = {
      for (final i in institutions) i.name.toLowerCase(): i,
    };

    final now = DateTime.now();
    var created = 0;
    for (final row in rows) {
      if (byTicker.containsKey(row.ticker.toLowerCase())) continue; // reuse
      final institution = institutionByName[row.institutionName.toLowerCase()];
      final resolvedInstitution =
          institution ??
          Institution(
            id: _idGenerator.newId(),
            name: row.institutionName,
            kind: InstitutionKind.broker,
            currency: row.currency,
            createdAt: now,
          );
      if (institution == null) {
        final failure = (await _institutionRepository.save(
          resolvedInstitution,
        )).failureOrNull;
        if (failure != null) return Left(failure);
        institutionByName[row.institutionName.toLowerCase()] =
            resolvedInstitution;
      }
      final asset = Asset(
        id: _idGenerator.newId(),
        ticker: row.ticker,
        name: row.name,
        kind: row.kind,
        market: row.market,
        currency: row.currency,
        institutionId: resolvedInstitution.id,
        createdAt: now,
      );
      final failure = (await _assetRepository.save(asset)).failureOrNull;
      if (failure != null) return Left(failure);
      byTicker[row.ticker.toLowerCase()] = asset;
      created++;
    }
    return Right(AssetImportResult(assetsCreated: created));
  }
}
