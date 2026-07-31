import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ledger_flutter/db/database_helper.dart';
import 'package:ledger_flutter/models/payment_method.dart';
import 'package:ledger_flutter/widgets/calculator_keyboard.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  Directory? tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ledger_keyboard_wrap_test_');
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

  testWidgets('calculator keyboard wraps payment methods into multiple rows', (tester) async {
    final db = DatabaseHelper.instance;
    await db.database;
    await db.insertPaymentMethod('微信2');
    await db.insertPaymentMethod('微信3');
    await db.insertPaymentMethod('微信4');
    await db.insertPaymentMethod('微信5');

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: CalculatorKeyboard(
              categoryName: '餐饮',
              categoryIconPath: 'assets/images/1_s.png',
              initialPaymentMethod: PaymentMethod.alipay,
              onComplete: (_, __, ___, ____) {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('微信5'), findsOneWidget);

    final firstRowDy = tester.getTopLeft(find.text('微信')).dy;
    final secondRowDy = tester.getTopLeft(find.text('微信5')).dy;

    expect(secondRowDy, greaterThan(firstRowDy));
  });
}
