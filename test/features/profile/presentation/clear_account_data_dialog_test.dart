import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/features/profile/presentation/widgets/clear_account_data_dialog.dart';

void main() {
  // The destructive Delete is the dialog's only FilledButton (Cancel is an
  // OutlinedButton). Reading its onPressed tells us whether it's enabled.
  FilledButton deleteButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton));

  Future<bool?> openDialog(WidgetTester tester, {required String email}) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showClearAccountDataDialog(context, email: email);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('Delete is disabled until the typed email matches', (
    tester,
  ) async {
    await openDialog(tester, email: 'user@b.com');

    expect(deleteButton(tester).onPressed, isNull); // gated initially

    await tester.enterText(find.byType(TextField), 'wrong@b.com');
    await tester.pump();
    expect(deleteButton(tester).onPressed, isNull); // still gated

    await tester.enterText(find.byType(TextField), 'USER@B.COM'); // case-insens.
    await tester.pump();
    expect(deleteButton(tester).onPressed, isNotNull); // enabled
  });

  testWidgets('returns true only after confirming with the matching email', (
    tester,
  ) async {
    var captured = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                captured = await showClearAccountDataDialog(
                  context,
                  email: 'user@b.com',
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'user@b.com');
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(captured, isTrue);
  });
}
