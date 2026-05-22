import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/app/widgets/investanco_soft_icon_button.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Center(child: child))),
      );

  testWidgets('fires onPressed on tap', (tester) async {
    var taps = 0;
    await pump(
      tester,
      InvestancoSoftIconButton(
        icon: FontAwesomeIcons.arrowsRotate,
        onPressed: () => taps++,
      ),
    );

    await tester.tap(find.byType(InvestancoSoftIconButton));
    expect(taps, 1);
  });

  testWidgets('busy shows a spinner and swallows taps', (tester) async {
    var taps = 0;
    await pump(
      tester,
      InvestancoSoftIconButton(
        icon: FontAwesomeIcons.arrowsRotate,
        busy: true,
        onPressed: () => taps++,
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(FaIcon), findsNothing);

    await tester.tap(find.byType(InvestancoSoftIconButton));
    expect(taps, 0);
  });

  testWidgets('a null handler renders disabled', (tester) async {
    await pump(
      tester,
      const InvestancoSoftIconButton(
        icon: FontAwesomeIcons.trashCan,
        onPressed: null,
      ),
    );

    final inkWell = tester.widget<InkWell>(find.byType(InkWell));
    expect(inkWell.onTap, isNull);
  });
}
