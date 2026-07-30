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
    tempDir = await Directory.systemTemp.createTemp('ledger_payment_method_filter_test_');
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

  test('monthly queries can filter and summarize by payment method', () async {
    final db = DatabaseHelper.instance;
    await db.database;

    await db.insertBill(
      const BillItem(
        id: 'bill_wechat',
        type: 'expense',
        paymentMethod: PaymentMethod.wechat,
        amount: 10,
        category: '餐饮',
        note: '',
        date: '2026-07-01 10:00:00',
        sortAt: '2026-07-01 10:00:00',
        iconId: 0,
        createdAt: '2026-07-01 10:00:00',
        updatedAt: '2026-07-01 10:00:00',
      ),
    );
    await db.insertBill(
      const BillItem(
        id: 'bill_alipay',
        type: 'income',
        paymentMethod: PaymentMethod.alipay,
        amount: 20,
        category: '工资',
        note: '',
        date: '2026-07-01 11:00:00',
        sortAt: '2026-07-01 11:00:00',
        iconId: 0,
        createdAt: '2026-07-01 11:00:00',
        updatedAt: '2026-07-01 11:00:00',
      ),
    );
    await db.insertBill(
      const BillItem(
        id: 'bill_bank',
        type: 'expense',
        paymentMethod: PaymentMethod.bank,
        amount: 30,
        category: '出行',
        note: '',
        date: '2026-07-02 09:00:00',
        sortAt: '2026-07-02 09:00:00',
        iconId: 1,
        createdAt: '2026-07-02 09:00:00',
        updatedAt: '2026-07-02 09:00:00',
      ),
    );

    final wechatBills = await db.getBillsByMonth(
      '2026-07',
      paymentMethod: PaymentMethod.wechat,
    );
    expect(wechatBills, hasLength(1));
    expect(wechatBills.single.paymentMethod, PaymentMethod.wechat);

    final alipayBills = await db.getAllBills(paymentMethod: PaymentMethod.alipay);
    expect(alipayBills, hasLength(1));
    expect(alipayBills.single.id, 'bill_alipay');

    final bankExpense = await db.getMonthlyExpense(
      '2026-07',
      paymentMethod: PaymentMethod.bank,
    );
    expect(bankExpense, 30);

    final alipayIncome = await db.getMonthlyIncome(
      '2026-07',
      paymentMethod: PaymentMethod.alipay,
    );
    expect(alipayIncome, 20);

    final grouped = await db.getExpenseGroupByIconId(
      '2026-07',
      paymentMethod: PaymentMethod.wechat,
    );
    expect(grouped[0], 10);
  });
}
