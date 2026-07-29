import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../db/database_helper.dart';

class ExportService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<Map<String, dynamic>> buildExportData() async {
    final wallets = await _db.getWallets();
    final bills = await _db.getAllBills();
    final budgets = await _db.getAllBudgets();
    final assets = await _db.getAllAssets();
    final categories = await _db.getAllCategories();

    return {
      'formatVersion': 2,
      'source': 'ledger_flutter',
      'exportedAt': DateTime.now().toIso8601String(),
      'wallets': [for (final item in wallets) item.toMap()],
      'bills': [for (final item in bills) item.toMap()],
      'records': [for (final item in bills) item.toMap()],
      'budgets': [for (final item in budgets) item.toMap()],
      'assets': [for (final item in assets) item.toMap()],
      'categories': {
        'expense': [
          for (final c in categories.where((c) => c.inEx == 0))
            {
              'id': c.id,
              'name': c.name,
              'iconId': c.iconId,
              'isCustom': c.isCustom,
              'sortOrder': c.sortOrder,
            },
        ],
        'income': [
          for (final c in categories.where((c) => c.inEx == 1))
            {
              'id': c.id,
              'name': c.name,
              'iconId': c.iconId,
              'isCustom': c.isCustom,
              'sortOrder': c.sortOrder,
            },
        ],
      },
    };
  }

  Future<String> buildExportJson() async {
    final data = await buildExportData();
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<File> exportToTempFile() async {
    final jsonString = await buildExportJson();
    final tempDir = await Directory.systemTemp.createTemp('ledger_export_');
    final fileName = 'ledger_backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File(p.join(tempDir.path, fileName));
    await file.writeAsString(jsonString, encoding: utf8);
    return file;
  }

  Future<void> shareExport() async {
    final file = await exportToTempFile();
    await Share.shareXFiles([XFile(file.path)], text: '我想省 数据备份');
  }
}
