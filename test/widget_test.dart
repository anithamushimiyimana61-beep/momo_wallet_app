import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momo_wallet_app/main.dart';

void main() {
  Future<void> openApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MomoWalletApp());
    await tester.pumpAndSettle();
  }

  testWidgets('wallet opens with the sample balance and features', (
    tester,
  ) async {
    await openApp(tester);

    expect(find.text('MOMO WALLET'), findsOneWidget);
    expect(find.text('10,000 RWF'), findsOneWidget);
    expect(find.text('Money snapshot'), findsOneWidget);
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Receive'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);
    expect(find.text('Cash out'), findsOneWidget);
  });

  testWidgets('send refuses a wrong prefix and then updates the balance', (
    tester,
  ) async {
    await openApp(tester);

    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), '0721234567');
    await tester.enterText(find.byType(TextField).at(1), '1000');
    await tester.tap(find.widgetWithText(FilledButton, 'Send money'));
    await tester.pump();

    expect(
      find.text('Phone number must start with 078 or 079.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField).at(0), '0788123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Send money'));
    await tester.pumpAndSettle();

    expect(find.text('9,000 RWF'), findsOneWidget);
    expect(find.text('1,000 RWF sent.'), findsOneWidget);
  });

  testWidgets('cash out refuses 250 and confirms a valid note breakdown', (
    tester,
  ) async {
    await openApp(tester);

    await tester.tap(find.text('Cash out'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), '250');
    await tester.tap(find.widgetWithText(FilledButton, 'Show notes'));
    await tester.pump();

    expect(
      find.text('Cash out must be a multiple of 100 RWF.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField).at(0), '3000');
    await tester.tap(find.widgetWithText(FilledButton, 'Show notes'));
    await tester.pump();

    expect(find.text('2,000 RWF'), findsOneWidget);
    expect(find.text('1,000 RWF'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Confirm cash out'));
    await tester.pumpAndSettle();

    expect(find.text('7,000 RWF'), findsOneWidget);
    expect(find.text('Cash out complete.'), findsOneWidget);
  });
}
