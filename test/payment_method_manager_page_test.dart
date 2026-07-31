import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ledger_flutter/db/database_helper.dart';
import 'package:ledger_flutter/pages/payment_method_manager_page.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  Directory? tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ledger_payment_method_page_test_');
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

  testWidgets('payment method manager renders default methods', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: PaymentMethodManagerPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('微信'), findsWidgets);
    expect(find.text('支付宝'), findsWidgets);
    expect(find.text('银行卡'), findsWidgets);
    expect(find.text('新增'), findsOneWidget);
  });
}
