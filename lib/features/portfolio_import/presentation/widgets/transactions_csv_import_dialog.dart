import 'package:flutter/material.dart';
import 'package:investanco/app/di/injection_container.dart';
import 'package:investanco/features/portfolio_import/domain/import_transactions_csv_usecase.dart';
import 'package:investanco/features/portfolio_import/presentation/pages/transactions_import_preview_page.dart';
import 'package:investanco/features/portfolio_import/presentation/transactions_csv_sample.dart';
import 'package:investanco/features/portfolio_import/presentation/widgets/csv_import_flow.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// Entry point for the transactions CSV import: the shared flow bound to the
/// transactions use case and preview. See `docs/specs/csv_import.md`.
Future<void> showTransactionsCsvImportDialog(BuildContext context) {
  final useCase = sl<ImportTransactionsCsvUseCase>();
  return runCsvImport<TransactionImportRow, TransactionImportPreview,
      TransactionImportResult>(
    context,
    title: t.importTransactions.title,
    body: t.importTransactions.intro,
    sampleContent: transactionsCsvSample,
    sampleFileName: 'investanco_transactions_example.csv',
    parseRows: useCase.parseRows,
    previewRows: useCase.previewRows,
    previewRoutePath: TransactionsImportPreviewPage.routePath,
    successMessage: (tally) =>
        t.importTransactions.success(count: tally.transactionsCreated),
  );
}
