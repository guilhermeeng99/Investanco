import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/app/widgets/investanco_dialog.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/core/utils/web_file_download.dart'
    if (dart.library.js_interop) 'package:investanco/core/utils/web_file_download_web.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// What the user chose on a CSV-import intro dialog (`null` = cancel / dismiss).
enum CsvImportChoice {
  /// Download the ready-to-edit example file.
  downloadExample,

  /// Pick a file to import.
  selectFile,
}

/// Shared intro dialog for the CSV imports (assets, transactions). Only the
/// [title] and [body] differ per entity; the icon, button order and labels live
/// here so both stay identical. Built on [InvestancoDialog].
Future<CsvImportChoice?> showCsvImportIntroDialog(
  BuildContext context, {
  required String title,
  required String body,
}) {
  return showDialog<CsvImportChoice>(
    context: context,
    builder: (ctx) => InvestancoDialog(
      icon: FontAwesomeIcons.fileCsv,
      title: title,
      message: body,
      actions: [
        InvestancoDialogAction(
          label: t.importCsv.selectFile,
          kind: InvestancoDialogActionKind.primary,
          onPressed: () => Navigator.pop(ctx, CsvImportChoice.selectFile),
        ),
        InvestancoDialogAction(
          label: t.importCsv.downloadExample,
          onPressed: () => Navigator.pop(ctx, CsvImportChoice.downloadExample),
        ),
        InvestancoDialogAction(
          label: t.common.cancel,
          onPressed: () => Navigator.pop(ctx),
        ),
      ],
    ),
  );
}

/// Shared error dialog for a failed CSV parse / import.
Future<void> showCsvImportErrorDialog(BuildContext context, String message) {
  return showInvestancoMessageDialog(
    context,
    icon: FontAwesomeIcons.circleExclamation,
    iconColor: context.appColors.error,
    title: t.importCsv.errorTitle,
    message: message,
  );
}

/// Writes [content] as [fileName] (web: browser download; mobile/desktop: save
/// dialog) and shows a confirmation/error snackbar. Shared by both imports.
Future<void> downloadCsvSample(
  BuildContext context, {
  required String content,
  required String fileName,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  bool saved;
  try {
    saved = await _writeSample(content, fileName);
  } on Exception {
    messenger.showSnackBar(SnackBar(content: Text(t.importCsv.exampleFailed)));
    return;
  }
  if (!saved) return;
  messenger.showSnackBar(
    SnackBar(content: Text(t.importCsv.exampleDownloaded)),
  );
}

Future<bool> _writeSample(String content, String fileName) async {
  if (kIsWeb) {
    // Encode as UTF-8 (default is ASCII, which throws on accented names like
    // "Logística"); the file then opens with accents intact.
    final url = Uri.dataFromString(
      content,
      mimeType: 'text/csv',
      encoding: utf8,
    ).toString();
    triggerBrowserUrlDownload(url, fileName);
    return true;
  }
  final path = await FilePicker.saveFile(
    dialogTitle: fileName,
    fileName: fileName,
    bytes: Uint8List.fromList(utf8.encode(content)),
    type: FileType.custom,
    allowedExtensions: const ['csv'],
  );
  return path != null;
}
