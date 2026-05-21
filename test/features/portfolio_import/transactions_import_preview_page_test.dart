import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/features/portfolio_import/domain/import_transactions_csv_usecase.dart';
import 'package:investanco/features/portfolio_import/domain/transaction_csv_parser.dart';
import 'package:investanco/features/portfolio_import/presentation/pages/transactions_import_preview_page.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

void main() {
  // Builds a preview, flagging each row's asset as existing or missing.
  TransactionImportPreview previewFrom(String csv, {required bool assetExists}) {
    final rows = parseTransactionsCsv(csv);
    return TransactionImportPreview(
      rows: [
        for (final r in rows)
          TransactionImportPreviewRow(
            row: r,
            assetExists: assetExists,
            institutionIsNew: true,
          ),
      ],
    );
  }

  Future<void> pump(WidgetTester tester, TransactionImportPreview p) async {
    await tester.pumpWidget(
      MaterialApp(home: TransactionsImportPreviewPage(preview: p)),
    );
    await tester.pumpAndSettle();
  }

  // The submit bar's button is the page's only FilledButton.
  FilledButton submit(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton));

  const csv = 'ticker,institution,operation,quantity,price\n'
      'SOXX,Avenue,buy,2,100';

  testWidgets('missing asset → banner shown and import disabled', (
    tester,
  ) async {
    await pump(tester, previewFrom(csv, assetExists: false));

    expect(find.text(t.importTransactions.missingTitle), findsOneWidget);
    expect(submit(tester).onPressed, isNull);
  });

  testWidgets('asset present → no banner and import enabled', (tester) async {
    await pump(tester, previewFrom(csv, assetExists: true));

    expect(find.text(t.importTransactions.missingTitle), findsNothing);
    expect(submit(tester).onPressed, isNotNull);
  });
}
