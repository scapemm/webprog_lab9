import 'package:cart_four_ways/setstate/cart_page_setstate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SAVE10 discount updates the total to 88.20', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SetStateCartPage()));

    final keyboardButton = find.widgetWithText(ActionChip, 'Keyboard · 49');
    await tester.tap(keyboardButton);
    await tester.pump();

    await tester.tap(keyboardButton);
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'SAVE10');
    await tester.tap(find.text('Apply'));
    await tester.pump();

    expect(find.text('88.20'), findsOneWidget);
  });
}
