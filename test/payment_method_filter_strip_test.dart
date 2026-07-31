import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ledger_flutter/widgets/payment_method_widgets.dart';

void main() {
  testWidgets('payment method filter strip uses buttons and selects values', (tester) async {
    String? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaymentMethodFilterStrip(
            selectedMethod: '',
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    );

    expect(find.byType(DropdownButton<String>), findsNothing);
    expect(find.text('全部'), findsOneWidget);
    expect(find.text('微信'), findsOneWidget);

    await tester.tap(find.text('支付宝'));
    await tester.pump();

    expect(selected, isNotNull);
    expect(selected, isNotEmpty);
  });
}
