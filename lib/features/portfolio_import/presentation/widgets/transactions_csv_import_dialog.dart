import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investanco/app/di/injection_container.dart';
import 'package:investanco/core/format/csv_decoder.dart';
import 'package:investanco/features/portfolio_import/domain/import_transactions_csv_usecase.dart';
import 'package:investanco/features/portfolio_import/presentation/pages/transactions_import_preview_page.dart';
import 'package:investanco/features/portfolio_import/presentation/transactions_csv_sample.dart';
import 'package:investanco/features/portfolio_import/presentation/widgets/csv_import_dialog.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

const _sampleFileName = 'investanco_transactions_example.csv';

/// Entry point for the transactions CSV import. Intro dialog → download example
/// or pick a file → parse → review screen. See `docs/specs/csv_import.md`.
Future<void> showTransactionsCsvImportDialog(BuildContext context) async {
  final choice = await showCsvImportIntroDialog(
    context,
    title: t.importTransactions.title,
    body: t.importTransactions.intro,
  );
  if (choice == null || !context.mounted) return;
  switch (choice) {
    case CsvImportChoice.downloadExample:
      await downloadCsvSample(
        context,
        content: transactionsCsvSample,
        fileName: _sampleFileName,
      );
    case CsvImportChoice.selectFile:
      await _pickAndPreview(context);
  }
}

Future<void> _pickAndPreview(BuildContext context) async {
  final FilePickerResult? result;
  try {
    result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      withData: true,
    );
  } on Exception {
    if (context.mounted) {
      await showCsvImportErrorDialog(context, t.importCsv.fileError);
    }
    return;
  }
  final bytes = result?.files.single.bytes;
  if (bytes == null || !context.mounted) return;

  final useCase = sl<ImportTransactionsCsvUseCase>();
  final parsed = useCase.parseRows(decodeCsvBytes(bytes));
  final failureMessage = parsed.fold((f) => f.message, (_) => null);
  if (failureMessage != null) {
    await showCsvImportErrorDialog(context, failureMessage);
    return;
  }
  final rows = parsed.getOrElse(() => const []);

  final TransactionImportPreview preview;
  try {
    preview = await useCase.previewRows(rows);
  } on Exception {
    if (context.mounted) {
      await showCsvImportErrorDialog(context, t.importCsv.genericError);
    }
    return;
  }
  if (!context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  final tally = await context.push<TransactionImportResult>(
    TransactionsImportPreviewPage.routePath,
    extra: preview,
  );
  if (tally == null) return;
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        t.importTransactions.success(count: tally.transactionsCreated),
      ),
    ),
  );
}
