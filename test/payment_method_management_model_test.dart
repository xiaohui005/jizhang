import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:ledger_flutter/db/database_helper.dart';
import 'package:ledger_flutter/models/bill_item.dart';
import 'package:ledger_flutter/models/payment_method.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  Directory? tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ledger_payment_method_model_test_');
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

  test('payment methods seed, reorder, rename and transfer bills', () async {
    final db = DatabaseHelper.instance;
    await db.database;

    final defaults = await db.getPaymentMethods();
    expect(defaults.take(3).map((e) => e.name).toList(), ['微信', '支付宝', '银行卡']);

    final cashId = await db.insertPaymentMethod('现金');
    await db.updatePaymentMethodName(id: cashId, name: '零钱');
    await db.reorderPaymentMethods([
      PaymentMethod.bank,
      PaymentMethod.wechat,
      cashId,
      PaymentMethod.alipay,
    ]);

    await db.insertBill(
      BillItem(
        id: 'bill_cash',
        type: 'expense',
        paymentMethod: cashId,
        amount: 18,
        category: '餐饮',
        note: '',
        date: '2026-07-30 10:00:00',
        sortAt: '2026-07-30 10:00:00',
        iconId: 0,
        createdAt: '2026-07-30 10:00:00',
        updatedAt: '2026-07-30 10:00:00',
      ),
    );

    final storedBill = await db.getBillById('bill_cash');
    expect(storedBill?.paymentMethod, cashId);

    await db.replacePaymentMethodOnBills(fromId: cashId, toId: PaymentMethod.wechat);
    await db.deletePaymentMethod(cashId);

    final methods = await db.getPaymentMethods();
    expect(methods.first.id, PaymentMethod.bank);
    expect(methods.any((m) => m.id == cashId), isFalse);

    final bills = await db.getAllBills();
    expect(bills.single.paymentMethod, PaymentMethod.wechat);
  });
}
