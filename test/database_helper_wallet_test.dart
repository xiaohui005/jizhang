import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:ledger_flutter/db/database_helper.dart';
import 'package:ledger_flutter/models/asset_item.dart';

Future<void> _createLegacyV6Database(String dbPath) async {
  final db = await openDatabase(
    dbPath,
    version: 6,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE bills (
          id TEXT PRIMARY KEY,
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
        CREATE TABLE budgets (
          id TEXT PRIMARY KEY,
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
        ON budgets(period_type, period, is_total, icon_id)
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
      await db.insert('bills', {
        'id': 'bill_1',
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
      await db.insert('budgets', {
        'id': 'budget_1',
        'period_type': 'month',
        'period': '2026-07',
        'is_total': 1,
        'category': '',
        'icon_id': -1,
        'amount': 1000,
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
    tempDir = await Directory.systemTemp.createTemp('ledger_wallet_test_');
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

  test('legacy database migrates to default wallet', () async {
    await _createLegacyV6Database(dbPath);

    final db = await DatabaseHelper.instance.database;

    final wallets = await db.query('wallets');
    expect(wallets, isNotEmpty);
    expect(wallets.first['id'], 'wallet_default');
    expect(wallets.first['name'], '钱包1');

    final bills = await db.query('bills');
    expect(bills.single['wallet_id'], 'wallet_default');

    final budgets = await db.query('budgets');
    expect(budgets.single['wallet_id'], 'wallet_default');
  });

  test('asset records persist wallet id', () async {
    final db = await DatabaseHelper.instance.database;
    await DatabaseHelper.instance.insertAsset(
      const AssetItem(
        id: 'asset_1',
        walletId: 'wallet_2',
        type: AssetItem.debt,
        name: '朋友借款',
        note: '测试',
        amount: 2000,
        createdAt: '2026-07-29 10:00:00',
        updatedAt: '2026-07-29 10:00:00',
      ),
    );

    final assets = await DatabaseHelper.instance.getAssets(walletId: 'wallet_2');
    expect(assets, hasLength(1));
    expect(assets.single.walletId, 'wallet_2');
    expect(assets.single.type, AssetItem.debt);
    expect(assets.single.name, '朋友借款');

    final walletRows = await db.query('wallets');
    expect(walletRows.first['id'], 'wallet_default');
  });
}
