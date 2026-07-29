import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_flutter/main.dart';

void main() {
  testWidgets('my page has no sms auto bookkeeping switch', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('短信自动记账'), findsNothing);

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();

    expect(find.text('短信自动记账'), findsNothing);
    expect(find.text('我的'), findsWidgets);
  });
}
