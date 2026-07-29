import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

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

  Future<String?> _suggestInitialDirectory() async {
    if (Platform.isAndroid) {
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (await downloadsDir.exists()) {
        return downloadsDir.path;
      }
    }
    return null;
  }

  Future<String?> saveExportFile() async {
    final jsonString = await buildExportJson();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '我想省备份_$timestamp.json';
    final path = await FilePicker.platform.saveFile(
      dialogTitle: '保存 JSON 备份',
      fileName: fileName,
      initialDirectory: await _suggestInitialDirectory(),
    );
    if (path == null || path.isEmpty) return null;

    final file = File(path);
    await file.create(recursive: true);
    await file.writeAsString(jsonString, encoding: utf8);
    return file.path;
  }
}
