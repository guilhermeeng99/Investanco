import 'package:flutter/material.dart';
import 'package:investanco/app/di/injection_container.dart';
import 'package:investanco/features/portfolio_import/domain/import_assets_csv_usecase.dart';
import 'package:investanco/features/portfolio_import/presentation/assets_csv_sample.dart';
import 'package:investanco/features/portfolio_import/presentation/pages/assets_import_preview_page.dart';
import 'package:investanco/features/portfolio_import/presentation/widgets/csv_import_flow.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// Entry point for the assets CSV import: the shared flow bound to the assets
/// use case and preview. See `docs/specs/csv_import.md`.
Future<void> showAssetsCsvImportDialog(BuildContext context) {
  final useCase = sl<ImportAssetsCsvUseCase>();
  return runCsvImport<AssetImportRow, AssetImportPreview, AssetImportResult>(
    context,
    title: t.importAssets.title,
    body: t.importAssets.intro,
    sampleContent: assetsCsvSample,
    sampleFileName: 'investanco_assets_example.csv',
    parseRows: useCase.parseRows,
    previewRows: useCase.previewRows,
    previewRoutePath: AssetsImportPreviewPage.routePath,
    successMessage: (tally) =>
        t.importAssets.success(count: tally.assetsCreated),
  );
}
