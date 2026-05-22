import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/format/csv_decoder.dart';
import 'package:investanco/features/portfolio_import/presentation/widgets/csv_import_dialog.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// Runs the shared CSV-import flow for one entity: intro dialog → download the
/// example or pick a file → parse → preview screen → success snackbar. The two
/// imports (assets, transactions) differ only in their use case, model types,
/// labels and preview route, all passed in. See `docs/specs/csv_import.md`.
///
/// - [parseRows] turns the file text into rows (or a [Failure] to surface).
/// - [previewRows] tags the rows for the review screen (may throw → generic
///   error).
/// - [previewRoutePath] receives the preview as `extra` and pops a [Result]
///   tally (null = the user backed out), summarized by [successMessage].
Future<void> runCsvImport<RowT, Preview, Result>(
  BuildContext context, {
  required String title,
  required String body,
  required String sampleContent,
  required String sampleFileName,
  required Either<Failure, List<RowT>> Function(String csv) parseRows,
  required Future<Preview> Function(List<RowT> rows) previewRows,
  required String previewRoutePath,
  required String Function(Result tally) successMessage,
}) async {
  final choice = await showCsvImportIntroDialog(
    context,
    title: title,
    body: body,
  );
  if (choice == null || !context.mounted) return;
  switch (choice) {
    case CsvImportChoice.downloadExample:
      await downloadCsvSample(
        context,
        content: sampleContent,
        fileName: sampleFileName,
      );
    case CsvImportChoice.selectFile:
      await _pickAndPreview<RowT, Preview, Result>(
        context,
        parseRows: parseRows,
        previewRows: previewRows,
        previewRoutePath: previewRoutePath,
        successMessage: successMessage,
      );
  }
}

Future<void> _pickAndPreview<RowT, Preview, Result>(
  BuildContext context, {
  required Either<Failure, List<RowT>> Function(String csv) parseRows,
  required Future<Preview> Function(List<RowT> rows) previewRows,
  required String previewRoutePath,
  required String Function(Result tally) successMessage,
}) async {
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

  final parsed = parseRows(decodeCsvBytes(bytes));
  final failureMessage = parsed.fold((f) => f.message, (_) => null);
  if (failureMessage != null) {
    await showCsvImportErrorDialog(context, failureMessage);
    return;
  }
  final rows = parsed.getOrElse(() => <RowT>[]);

  final Preview preview;
  try {
    preview = await previewRows(rows);
  } on Exception {
    if (context.mounted) {
      await showCsvImportErrorDialog(context, t.importCsv.genericError);
    }
    return;
  }
  if (!context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  final tally = await context.push<Result>(previewRoutePath, extra: preview);
  if (tally == null) return;
  messenger.showSnackBar(SnackBar(content: Text(successMessage(tally))));
}

/// Commits a parsed import on the preview page: awaits [importRows], pops the
/// [Result] tally on success (returns true), or shows the CSV error dialog and
/// returns false so the page can re-enable its submit button. Shared by the
/// asset and transaction preview pages, which differ only in their use case.
Future<bool> commitImport<Result>(
  BuildContext context,
  Future<Either<Failure, Result>> Function() importRows,
) async {
  try {
    final result = await importRows();
    if (!context.mounted) return false;
    return result.fold(
      (failure) {
        unawaited(showCsvImportErrorDialog(context, failure.message));
        return false;
      },
      (tally) {
        context.pop(tally);
        return true;
      },
    );
  } on Exception {
    if (context.mounted) {
      await showCsvImportErrorDialog(context, t.importCsv.genericError);
    }
    return false;
  }
}
