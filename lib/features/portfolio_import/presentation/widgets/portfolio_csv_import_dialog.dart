import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:investanco/app/di/injection_container.dart';
import 'package:investanco/core/utils/web_file_download.dart'
    if (dart.library.js_interop) 'package:investanco/core/utils/web_file_download_web.dart';
import 'package:investanco/features/portfolio_import/domain/import_portfolio_csv_usecase.dart';
import 'package:investanco/features/portfolio_import/presentation/portfolio_csv_sample.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

const _sampleFileName = 'investanco_example.csv';

enum _CsvImportAction { downloadExample, selectFile }

/// Entry point for the bulk CSV import. Shows an intro dialog (download the
/// example or pick a file), parses the picked file, confirms the row count and
/// imports. See `docs/specs/csv_import.md`.
Future<void> showPortfolioCsvImportDialog(BuildContext context) async {
  final action = await showDialog<_CsvImportAction>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(t.importCsv.title),
      content: Text(t.importCsv.intro),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(t.common.cancel),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(ctx, _CsvImportAction.downloadExample),
          child: Text(t.importCsv.downloadExample),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, _CsvImportAction.selectFile),
          child: Text(t.importCsv.selectFile),
        ),
      ],
    ),
  );

  if (action == null || !context.mounted) return;
  switch (action) {
    case _CsvImportAction.downloadExample:
      await _downloadSample(context);
    case _CsvImportAction.selectFile:
      await _pickAndImport(context);
  }
}

Future<void> _downloadSample(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  bool saved;
  try {
    saved = await _writeSample();
  } on Exception {
    messenger.showSnackBar(SnackBar(content: Text(t.importCsv.exampleFailed)));
    return;
  }
  if (!saved) return;
  messenger.showSnackBar(
    SnackBar(content: Text(t.importCsv.exampleDownloaded)),
  );
}

Future<bool> _writeSample() async {
  if (kIsWeb) {
    final url =
        Uri.dataFromString(portfolioCsvSample, mimeType: 'text/csv').toString();
    triggerBrowserUrlDownload(url, _sampleFileName);
    return true;
  }
  final path = await FilePicker.saveFile(
    dialogTitle: t.importCsv.downloadExample,
    fileName: _sampleFileName,
    bytes: Uint8List.fromList(utf8.encode(portfolioCsvSample)),
    type: FileType.custom,
    allowedExtensions: const ['csv'],
  );
  return path != null;
}

Future<void> _pickAndImport(BuildContext context) async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['csv'],
    withData: true,
  );
  final bytes = result?.files.single.bytes;
  if (bytes == null || !context.mounted) return;

  final useCase = sl<ImportPortfolioCsvUseCase>();
  final parsed = useCase.parseRows(utf8.decode(bytes));
  final failureMessage = parsed.fold((f) => f.message, (_) => null);
  if (failureMessage != null) {
    await _showError(context, failureMessage);
    return;
  }
  final rows = parsed.getOrElse(() => const []);

  final confirmed = await _confirm(context, rows.length);
  if (confirmed != true || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  final importResult = await useCase.importRows(rows);
  if (!context.mounted) return;
  importResult.fold(
    (failure) => _showError(context, failure.message),
    (result) => messenger.showSnackBar(
      SnackBar(
        content: Text(
          t.importCsv.success(
            assets: result.assetsCreated,
            transactions: result.transactionsCreated,
          ),
        ),
      ),
    ),
  );
}

Future<bool?> _confirm(BuildContext context, int rowCount) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(t.importCsv.confirmTitle),
      content: Text(t.importCsv.confirmBody(count: rowCount)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(t.common.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(t.common.confirm),
        ),
      ],
    ),
  );
}

Future<void> _showError(BuildContext context, String message) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(t.importCsv.errorTitle),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(t.common.ok),
        ),
      ],
    ),
  );
}
