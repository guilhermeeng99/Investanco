import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/app/widgets/investanco_dialog.dart';

void main() {
  // Pumps a button that opens [open] and returns its result into [sink].
  Future<void> pumpOpener(
    WidgetTester tester,
    Future<void> Function(BuildContext) open,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => open(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('confirm dialog resolves true when confirmed', (tester) async {
    bool? result;
    await pumpOpener(tester, (context) async {
      result = await showInvestancoConfirmDialog(
        context,
        title: 'Delete',
        message: 'Sure?',
        confirmLabel: 'Yes',
        cancelLabel: 'No',
      );
    });

    expect(find.text('Delete'), findsOneWidget);
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('confirm dialog resolves false when cancelled', (tester) async {
    bool? result;
    await pumpOpener(tester, (context) async {
      result = await showInvestancoConfirmDialog(
        context,
        title: 'Delete',
        message: 'Sure?',
        confirmLabel: 'Yes',
        cancelLabel: 'No',
      );
    });

    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });

  testWidgets('a disabled action renders a disabled button', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: InvestancoDialog(
            title: 'Gated',
            actions: [
              InvestancoDialogAction(
                label: 'Blocked',
                onPressed: null,
                kind: InvestancoDialogActionKind.primary,
              ),
            ],
          ),
        ),
      ),
    );

    // A single action renders one full-width button, disabled (onPressed null).
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });
}
