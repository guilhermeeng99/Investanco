import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/app/widgets/widgets.dart';
import 'package:investanco/features/portfolio_import/domain/asset_csv_parser.dart';
import 'package:investanco/features/portfolio_import/domain/import_assets_csv_usecase.dart';
import 'package:investanco/features/portfolio_import/presentation/pages/assets_import_preview_page.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

void main() {
  AssetImportPreview previewFrom(String csv) {
    final rows = parseAssetsCsv(csv);
    return AssetImportPreview(
      rows: [for (final r in rows) AssetImportPreviewRow(row: r, isNew: true)],
    );
  }

  Future<void> pump(WidgetTester tester, AssetImportPreview p) async {
    await tester.pumpWidget(
      MaterialApp(home: AssetsImportPreviewPage(preview: p)),
    );
    await tester.pumpAndSettle();
  }

  final removeButton = find.byTooltip(t.importCsv.previewRemoveRow);

  const csv = 'ticker,kind,institution\nSOXX,etfUs,Avenue\nQQQ,etfUs,Avenue';

  testWidgets('lists one removable tile per asset', (tester) async {
    await pump(tester, previewFrom(csv));
    expect(removeButton, findsNWidgets(2));
  });

  testWidgets('removing every row shows the empty state', (tester) async {
    await pump(tester, previewFrom(csv));

    await tester.tap(removeButton.first);
    await tester.pumpAndSettle();
    expect(removeButton, findsOneWidget);

    await tester.tap(removeButton.first);
    await tester.pumpAndSettle();
    expect(find.byType(EmptyState), findsOneWidget);
  });
}
