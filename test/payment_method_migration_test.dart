import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:ledger_flutter/db/database_helper.dart';
import 'package:ledger_flutter/models/payment_method.dart';

Future<void> _createLegacyV7Database(String dbPath) async {
  final db = await openDatabase(
    dbPath,
    version: 7,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE bills (
          id TEXT PRIMARY KEY,
          wallet_id TEXT NOT NULL DEFAULT 'wallet_default',
          type TEXT NOT NULL,
          amount REAL NOT NULL,
          category TEXT NOT NULL,
          note TEXT NOT NULL,
          date TEXT NOT NULL,
          sort_at TEXT NOT NULL,
          icon_id INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE wallets (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE budgets (
          id TEXT PRIMARY KEY,
          wallet_id TEXT NOT NULL DEFAULT 'wallet_default',
          period_type TEXT NOT NULL,
          period TEXT NOT NULL,
          is_total INTEGER NOT NULL,
          category TEXT NOT NULL DEFAULT '',
          icon_id INTEGER NOT NULL DEFAULT -1,
          amount REAL NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE UNIQUE INDEX idx_budgets_unique
        ON budgets(wallet_id, period_type, period, is_total, icon_id)
      ''');
      await db.execute('''
        CREATE TABLE settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          in_ex INTEGER NOT NULL,
          name TEXT NOT NULL,
          icon_id INTEGER NOT NULL,
          is_custom INTEGER NOT NULL DEFAULT 0,
          sort_order INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE asset_records (
          id TEXT PRIMARY KEY,
          wallet_id TEXT NOT NULL DEFAULT 'wallet_default',
          type TEXT NOT NULL,
          name TEXT NOT NULL,
          note TEXT NOT NULL DEFAULT '',
          amount REAL NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      await db.insert('bills', {
        'id': 'bill_1',
        'wallet_id': 'wallet_default',
        'type': 'expense',
        'amount': 12.5,
        'category': '餐饮',
        'note': '',
        'date': '2026-07-29 10:00:00',
        'sort_at': '2026-07-29 10:00:00',
        'icon_id': 0,
        'created_at': '2026-07-29 10:00:00',
        'updated_at': '2026-07-29 10:00:00',
      });
    },
  );
  await db.close();
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  Directory? tempDir;
  late String dbPath;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ledger_payment_method_test_');
    dbPath = p.join(tempDir!.path, 'ledger.db');
    DatabaseHelper.overrideDatabasePathForTest(dbPath);
    await DatabaseHelper.resetForTest();
  });

  tearDown(() async {
    await DatabaseHelper.resetForTest();
    DatabaseHelper.overrideDatabasePathForTest(null);
    if (tempDir != null && await tempDir!.exists()) {
      await tempDir!.delete(recursive: true);
    }
  });

  test('old bills are migrated to wechat payment method', () async {
    await _createLegacyV7Database(dbPath);

    final db = await DatabaseHelper.instance.database;
    final tableInfo = await db.rawQuery('PRAGMA table_info(bills)');
    expect(
      tableInfo.any((row) => row['name'] == 'payment_method'),
      isTrue,
    );

    final methods = await db.query('payment_methods');
    expect(methods, hasLength(3));
    expect(
      methods.map((row) => row['name']).toSet(),
      containsAll(['微信', '支付宝', '银行卡']),
    );

    final rows = await db.rawQuery('SELECT payment_method FROM bills WHERE id = ?', ['bill_1']);
    expect(rows, hasLength(1));
    expect(rows.single['payment_method'], PaymentMethod.wechat);

    final bills = await DatabaseHelper.instance.getAllBills();
    expect(bills, hasLength(1));
    expect(bills.single.paymentMethod, PaymentMethod.wechat);
  });
}
