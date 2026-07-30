import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:ledger_flutter/db/database_helper.dart';
import 'package:ledger_flutter/models/payment_method.dart';
import 'package:ledger_flutter/widgets/calculator_keyboard.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  Directory? tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ledger_keyboard_test_');
    DatabaseHelper.overrideDatabasePathForTest(p.join(tempDir!.path, 'ledger.db'));
    await DatabaseHelper.resetForTest();
  });

  tearDown(() async {
    await DatabaseHelper.resetForTest();
    DatabaseHelper.overrideDatabasePathForTest(null);
    if (tempDir != null && await tempDir!.exists()) {
      await tempDir!.delete(recursive: true);
    }
  });

  testWidgets('calculator keyboard submits the selected payment method', (tester) async {
    String? paymentMethod;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalculatorKeyboard(
            categoryName: '餐饮',
            categoryIconPath: 'assets/images/1_s.png',
            initialPaymentMethod: PaymentMethod.alipay,
            onComplete: (amount, note, date, method) {
              paymentMethod = method;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('银行卡'));
    await tester.pump();
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('完成'));
    await tester.pump();

    expect(paymentMethod, PaymentMethod.bank);
  });
}
