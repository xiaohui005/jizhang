import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:ledger_flutter/db/database_helper.dart';
import 'package:ledger_flutter/models/asset_item.dart';
import 'package:ledger_flutter/models/bill_item.dart';
import 'package:ledger_flutter/models/budget_item.dart';
import 'package:ledger_flutter/models/wallet_item.dart';
import 'package:ledger_flutter/services/export_service.dart';
import 'package:ledger_flutter/services/import_service.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  Directory? tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ledger_backup_test_');
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

  test('export json contains wallets bills budgets assets', () async {
    final db = DatabaseHelper.instance;
    await db.database;
    await db.insertWallet(
      const WalletItem(
        id: 'wallet_2',
        name: '钱包2',
        createdAt: '2026-07-29 10:00:00',
        updatedAt: '2026-07-29 10:00:00',
      ),
    );
    await db.insertBill(
      const BillItem(
        id: 'bill_1',
        walletId: 'wallet_default',
        type: 'expense',
        amount: 12.5,
        category: '餐饮',
        note: '午饭',
        date: '2026-07-29 12:00:00',
        sortAt: '2026-07-29 12:00:00',
        iconId: 0,
        createdAt: '2026-07-29 12:00:00',
        updatedAt: '2026-07-29 12:00:00',
      ),
    );
    await db.insertOrReplaceBudget(
      const BudgetItem(
        id: 'budget_1',
        walletId: 'wallet_2',
        periodType: 'month',
        period: '2026-07',
        isTotal: true,
        category: '',
        iconId: -1,
        amount: 500,
        createdAt: '2026-07-29 12:00:00',
        updatedAt: '2026-07-29 12:00:00',
      ),
    );
    await db.insertAsset(
      const AssetItem(
        id: 'asset_1',
        walletId: 'wallet_2',
        type: AssetItem.credit,
        name: '朋友借出',
        note: '测试',
        amount: 200,
        createdAt: '2026-07-29 12:00:00',
        updatedAt: '2026-07-29 12:00:00',
      ),
    );

    final jsonString = await ExportService().buildExportJson();
    final data = jsonDecode(jsonString) as Map<String, dynamic>;

    expect(data['formatVersion'], 2);
    expect((data['wallets'] as List).length, greaterThanOrEqualTo(2));
    expect((data['bills'] as List).length, 1);
    expect((data['records'] as List).length, 1);
    expect((data['budgets'] as List).length, 1);
    expect((data['assets'] as List).length, 1);
  });

  test('import merges without clearing existing data', () async {
    final db = DatabaseHelper.instance;
    await db.database;
    await db.insertBill(
      const BillItem(
        id: 'local_bill',
        walletId: BillItem.defaultWalletId,
        type: 'expense',
        amount: 30,
        category: '餐饮',
        note: '本地',
        date: '2026-07-29 10:00:00',
        sortAt: '2026-07-29 10:00:00',
        iconId: 0,
        createdAt: '2026-07-29 10:00:00',
        updatedAt: '2026-07-29 10:00:00',
      ),
    );

    final importJson = jsonEncode({
      'formatVersion': 2,
      'source': 'ledger_flutter',
      'exportedAt': '2026-07-29T10:43:00.000Z',
      'wallets': [
        {
          'id': 'wallet_2',
          'name': '钱包2',
          'created_at': '2026-07-29 10:00:00',
          'updated_at': '2026-07-29 10:00:00',
        },
      ],
      'bills': [
        {
          'id': 'import_bill',
          'wallet_id': 'wallet_2',
          'type': 'expense',
          'amount': 88,
          'category': '购物',
          'note': '导入',
          'date': '2026-07-29 11:00:00',
          'sort_at': '2026-07-29 11:00:00',
          'icon_id': 1,
          'created_at': '2026-07-29 11:00:00',
          'updated_at': '2026-07-29 11:00:00',
        },
      ],
      'budgets': [
        {
          'id': 'import_budget',
          'wallet_id': 'wallet_2',
          'period_type': 'month',
          'period': '2026-07',
          'is_total': 1,
          'category': '',
          'icon_id': -1,
          'amount': 800,
          'created_at': '2026-07-29 11:00:00',
          'updated_at': '2026-07-29 11:00:00',
        },
      ],
      'assets': [
        {
          'id': 'import_asset',
          'wallet_id': 'wallet_2',
          'type': 'credit',
          'name': '朋友欠款',
          'note': '',
          'amount': 300,
          'created_at': '2026-07-29 11:00:00',
          'updated_at': '2026-07-29 11:00:00',
        },
      ],
      'categories': {
        'expense': [
          {'name': '购物', 'iconId': 1, 'icon': 'assets/images/2.png'},
        ],
        'income': [],
      },
    });

    final result = await ImportService().importFromJson(importJson);

    final bills = await db.getAllBills();
    final wallets = await db.getWallets();
    final budgets = await db.getAllBudgets();
    final assets = await db.getAllAssets();

    expect(result.insertedBills, 1);
    expect(result.importedWallets, 1);
    expect(result.importedBudgets, 1);
    expect(result.importedAssets, 1);
    expect(bills.any((b) => b.id == 'local_bill'), isTrue);
    expect(bills.any((b) => b.id == 'import_bill'), isTrue);
    expect(wallets.any((w) => w.id == 'wallet_2'), isTrue);
    expect(budgets.any((b) => b.id == 'import_budget'), isTrue);
    expect(assets.any((a) => a.id == 'import_asset'), isTrue);
  });

  test('import generates ids for budget and asset records when missing', () async {
    final db = DatabaseHelper.instance;
    await db.database;

    final importJson = jsonEncode({
      'formatVersion': 2,
      'source': 'ledger_flutter',
      'exportedAt': '2026-07-29T10:43:00.000Z',
      'wallets': [],
      'bills': [],
      'budgets': [
        {
          'wallet_id': 'wallet_default',
          'period_type': 'month',
          'period': '2026-07',
          'is_total': 1,
          'category': '',
          'icon_id': -1,
          'amount': 1200,
          'created_at': '2026-07-29 11:00:00',
          'updated_at': '2026-07-29 11:00:00',
        },
      ],
      'assets': [
        {
          'wallet_id': 'wallet_default',
          'type': 'debt',
          'name': '借出款',
          'note': '',
          'amount': 150,
          'created_at': '2026-07-29 11:00:00',
          'updated_at': '2026-07-29 11:00:00',
        },
      ],
      'categories': {'expense': [], 'income': []},
    });

    final result = await ImportService().importFromJson(importJson);

    final budgets = await db.getAllBudgets();
    final assets = await db.getAllAssets();

    expect(result.importedBudgets, 1);
    expect(result.importedAssets, 1);
    expect(budgets.single.id, isNotEmpty);
    expect(assets.single.id, isNotEmpty);
  });
}
