import 'dart:convert';

import '../data/account_data.dart';
import '../db/database_helper.dart';
import '../models/asset_item.dart';
import '../models/bill_item.dart';
import '../models/budget_item.dart';
import '../models/payment_method.dart';
import '../models/payment_method_item.dart';
import '../models/wallet_item.dart';

/// myapp 导出的 JSON 中单条账单记录的结构
class _ImportedRecord {
  final String id;
  final String walletId;
  final String type;
  final double amount;
  final String category;
  final String note;
  final String date;
  final String paymentMethod;
  final int iconId;
  final String sortAt;
  final String createdAt;
  final String updatedAt;

  const _ImportedRecord({
    required this.id,
    required this.walletId,
    required this.type,
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
    required this.paymentMethod,
    required this.iconId,
    required this.sortAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory _ImportedRecord.fromJson(Map<String, dynamic> json) {
    final fallbackDate = (json['date'] as String?) ?? '';
    return _ImportedRecord(
      id: (json['id'] as String?) ?? '',
      walletId: (json['wallet_id'] as String?) ?? '',
      type: (json['type'] as String?) ?? 'expense',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      category: (json['category'] as String?) ?? '其他',
      note: (json['note'] as String?) ?? '',
      date: fallbackDate,
      paymentMethod: PaymentMethod.normalize(json['payment_method'] as String?),
      iconId: (json['iconId'] as int?) ?? (json['icon_id'] as int?) ?? -1,
      sortAt: (json['sort_at'] as String?) ?? fallbackDate,
      createdAt: (json['created_at'] as String?) ?? '',
      updatedAt: (json['updated_at'] as String?) ?? '',
    );
  }

  BillItem toModel(
    String fallbackWalletId, {
    String? idOverride,
    required Set<String> allowedPaymentMethods,
  }) {
    final resolvedPaymentMethod = allowedPaymentMethods.contains(paymentMethod)
        ? paymentMethod
        : PaymentMethod.wechat;
    return BillItem(
      id: (idOverride ?? id).isEmpty
          ? 'import_${date}_${amount}_${category}_${resolvedPaymentMethod}'
          : (idOverride ?? id),
      walletId: walletId.isEmpty ? fallbackWalletId : walletId,
      type: type,
      amount: amount,
      category: category,
      note: note,
      date: date,
      paymentMethod: resolvedPaymentMethod,
      sortAt: sortAt.isEmpty ? date : sortAt,
      iconId: iconId,
      createdAt: createdAt.isEmpty ? DateTime.now().toIso8601String() : createdAt,
      updatedAt: updatedAt.isEmpty ? DateTime.now().toIso8601String() : updatedAt,
    );
  }
}

class _ImportedWallet {
  final String id;
  final String name;
  final String createdAt;
  final String updatedAt;

  const _ImportedWallet({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory _ImportedWallet.fromJson(Map<String, dynamic> json) {
    return _ImportedWallet(
      id: (json['id'] as String?) ?? BillItem.defaultWalletId,
      name: (json['name'] as String?) ?? '钱包',
      createdAt: (json['created_at'] as String?) ?? '',
      updatedAt: (json['updated_at'] as String?) ?? '',
    );
  }

  WalletItem toModel() {
    return WalletItem(
      id: id,
      name: name,
      createdAt: createdAt.isEmpty ? DateTime.now().toIso8601String() : createdAt,
      updatedAt: updatedAt.isEmpty ? DateTime.now().toIso8601String() : updatedAt,
    );
  }
}

class _ImportedPaymentMethod {
  final String id;
  final String name;
  final int sortOrder;
  final bool isDefault;
  final String createdAt;
  final String updatedAt;

  const _ImportedPaymentMethod({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  factory _ImportedPaymentMethod.fromJson(Map<String, dynamic> json) {
    return _ImportedPaymentMethod(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      sortOrder: (json['sort_order'] as int?) ?? 0,
      isDefault: (json['is_default'] as int?) == 1,
      createdAt: (json['created_at'] as String?) ?? '',
      updatedAt: (json['updated_at'] as String?) ?? '',
    );
  }

  PaymentMethodItem toModel() {
    return PaymentMethodItem(
      id: id,
      name: name,
      sortOrder: sortOrder,
      isDefault: isDefault,
      createdAt: createdAt.isEmpty ? DateTime.now().toIso8601String() : createdAt,
      updatedAt: updatedAt.isEmpty ? DateTime.now().toIso8601String() : updatedAt,
    );
  }
}

class _ImportedBudget {
  final String id;
  final String walletId;
  final String periodType;
  final String period;
  final bool isTotal;
  final String category;
  final int iconId;
  final double amount;
  final String createdAt;
  final String updatedAt;

  const _ImportedBudget({
    required this.id,
    required this.walletId,
    required this.periodType,
    required this.period,
    required this.isTotal,
    required this.category,
    required this.iconId,
    required this.amount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory _ImportedBudget.fromJson(Map<String, dynamic> json) {
    return _ImportedBudget(
      id: (json['id'] as String?) ?? '',
      walletId: (json['wallet_id'] as String?) ?? '',
      periodType: (json['period_type'] as String?) ?? 'month',
      period: (json['period'] as String?) ?? '',
      isTotal: (json['is_total'] as int?) == 1,
      category: (json['category'] as String?) ?? '',
      iconId: (json['icon_id'] as int?) ?? -1,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      createdAt: (json['created_at'] as String?) ?? '',
      updatedAt: (json['updated_at'] as String?) ?? '',
    );
  }

  BudgetItem toModel(String fallbackWalletId, {String? idOverride}) {
    final resolvedWalletId = walletId.isEmpty ? fallbackWalletId : walletId;
    return BudgetItem(
      id: (idOverride ?? id).isEmpty
          ? 'import_budget_${resolvedWalletId}_${periodType}_${period}_${category}_${amount}'
          : (idOverride ?? id),
      walletId: resolvedWalletId,
      periodType: periodType,
      period: period,
      isTotal: isTotal,
      category: category,
      iconId: iconId,
      amount: amount,
      createdAt: createdAt.isEmpty ? DateTime.now().toIso8601String() : createdAt,
      updatedAt: updatedAt.isEmpty ? DateTime.now().toIso8601String() : updatedAt,
    );
  }
}

class _ImportedAsset {
  final String id;
  final String walletId;
  final String type;
  final String name;
  final String note;
  final double amount;
  final String createdAt;
  final String updatedAt;

  const _ImportedAsset({
    required this.id,
    required this.walletId,
    required this.type,
    required this.name,
    required this.note,
    required this.amount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory _ImportedAsset.fromJson(Map<String, dynamic> json) {
    return _ImportedAsset(
      id: (json['id'] as String?) ?? '',
      walletId: (json['wallet_id'] as String?) ?? '',
      type: (json['type'] as String?) ?? AssetItem.debt,
      name: (json['name'] as String?) ?? '',
      note: (json['note'] as String?) ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      createdAt: (json['created_at'] as String?) ?? '',
      updatedAt: (json['updated_at'] as String?) ?? '',
    );
  }

  AssetItem toModel(String fallbackWalletId, {String? idOverride}) {
    final resolvedWalletId = walletId.isEmpty ? fallbackWalletId : walletId;
    return AssetItem(
      id: (idOverride ?? id).isEmpty
          ? 'import_asset_${resolvedWalletId}_${type}_${name}_${amount}'
          : (idOverride ?? id),
      walletId: resolvedWalletId,
      type: type,
      name: name,
      note: note,
      amount: amount,
      createdAt: createdAt.isEmpty ? DateTime.now().toIso8601String() : createdAt,
      updatedAt: updatedAt.isEmpty ? DateTime.now().toIso8601String() : updatedAt,
    );
  }
}

class _ImportedCategory {
  final String name;
  final String icon;
  final int? iconId;

  const _ImportedCategory({required this.name, required this.icon, this.iconId});

  factory _ImportedCategory.fromJson(Map<String, dynamic> json) {
    return _ImportedCategory(
      name: (json['name'] as String?) ?? '',
      icon: (json['icon'] as String?) ?? '',
      iconId: (json['iconId'] as int?) ?? (json['icon_id'] as int?),
    );
  }
}

class _ImportData {
  final int formatVersion;
  final String source;
  final String exportedAt;
  final List<_ImportedWallet> wallets;
  final List<_ImportedPaymentMethod> paymentMethods;
  final List<_ImportedRecord> records;
  final List<_ImportedBudget> budgets;
  final List<_ImportedAsset> assets;
  final Map<String, List<_ImportedCategory>> categories;

  const _ImportData({
    required this.formatVersion,
    required this.source,
    required this.exportedAt,
    required this.wallets,
    required this.paymentMethods,
    required this.records,
    required this.budgets,
    required this.assets,
    required this.categories,
  });

  factory _ImportData.fromJson(Map<String, dynamic> json) {
    final recordsRaw = (json['records'] as List<dynamic>?) ?? [];
    final billsRaw = (json['bills'] as List<dynamic>?) ?? recordsRaw;
    final walletsRaw = (json['wallets'] as List<dynamic>?) ?? [];
    final paymentMethodsRaw = (json['payment_methods'] as List<dynamic>?) ?? [];
    final budgetsRaw = (json['budgets'] as List<dynamic>?) ?? [];
    final assetsRaw = (json['assets'] as List<dynamic>?) ?? [];
    final catsRaw = (json['categories'] as Map<String, dynamic>?) ?? {};

    final expenseCats =
        (catsRaw['expense'] as List<dynamic>?)
            ?.map((c) => _ImportedCategory.fromJson(c as Map<String, dynamic>))
            .toList() ??
        [];
    final incomeCats =
        (catsRaw['income'] as List<dynamic>?)
            ?.map((c) => _ImportedCategory.fromJson(c as Map<String, dynamic>))
            .toList() ??
        [];

    return _ImportData(
      formatVersion: (json['formatVersion'] as int?) ?? 1,
      source: (json['source'] as String?) ?? 'unknown',
      exportedAt: (json['exportedAt'] as String?) ?? '',
      wallets: walletsRaw
          .map((w) => _ImportedWallet.fromJson(w as Map<String, dynamic>))
          .toList(),
      paymentMethods: paymentMethodsRaw
          .map((m) => _ImportedPaymentMethod.fromJson(m as Map<String, dynamic>))
          .toList(),
      records: billsRaw
          .map((r) => _ImportedRecord.fromJson(r as Map<String, dynamic>))
          .toList(),
      budgets: budgetsRaw
          .map((b) => _ImportedBudget.fromJson(b as Map<String, dynamic>))
          .toList(),
      assets: assetsRaw
          .map((a) => _ImportedAsset.fromJson(a as Map<String, dynamic>))
          .toList(),
      categories: {'expense': expenseCats, 'income': incomeCats},
    );
  }
}

/// 导入结果
class ImportResult {
  final int totalRecords;
  final int insertedBills;
  final int skippedBills;
  final int importedPaymentMethods;
  final int importedCategories;
  final int importedWallets;
  final int importedBudgets;
  final int importedAssets;

  const ImportResult({
    required this.totalRecords,
    required this.insertedBills,
    required this.skippedBills,
    required this.importedPaymentMethods,
    required this.importedCategories,
    required this.importedWallets,
    required this.importedBudgets,
    required this.importedAssets,
  });

  int get merged => insertedBills;
  int get skipped => skippedBills;
}

/// 数据导入服务，解析 JSON 备份并合并进本地数据库。
class ImportService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  _ImportData _parseJson(String jsonString) {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    return _ImportData.fromJson(map);
  }

  Future<ImportResult> importFromJson(String jsonString) async {
    final data = _parseJson(jsonString);
    final fallbackWalletId = await _db.getCurrentWalletId();

    int importedWallets = 0;
    int insertedBills = 0;
    int skippedBills = 0;
    int importedPaymentMethods = 0;
    int importedCategories = 0;
    int importedBudgets = 0;
    int importedAssets = 0;

    // 钱包按 id 合并，已存在则保留本地版本。
    final existingWalletIds = (await _db.getWallets()).map((w) => w.id).toSet();
    for (final wallet in data.wallets) {
      if (existingWalletIds.contains(wallet.id)) continue;
      await _db.insertWallet(wallet.toModel());
      existingWalletIds.add(wallet.id);
      importedWallets++;
    }

    // 支付方式按 id 合并，保留本地已有条目。
    final existingPaymentMethods = await _db.getPaymentMethods();
    final existingPaymentMethodIds = existingPaymentMethods.map((m) => m.id).toSet();
    for (final method in data.paymentMethods) {
      final model = method.toModel();
      await _db.upsertPaymentMethod(model);
      existingPaymentMethodIds.add(model.id);
      importedPaymentMethods++;
    }
    final allowedPaymentMethodIds = (await _db.getPaymentMethods()).map((m) => m.id).toSet();

    // 分类按 (in_ex, name) 合并。
    final existingCategories = await _db.getAllCategories();
    final existingNames = existingCategories.map((c) => '${c.inEx}_${c.name}').toSet();
    final usedIconsByInEx = <int, Set<int>>{
      0: {
        for (final category in existingCategories)
          if (category.inEx == 0) category.iconId,
      },
      1: {
        for (final category in existingCategories)
          if (category.inEx == 1) category.iconId,
      },
    };

    for (final cat in data.categories['expense'] ?? []) {
      final key = '0_${cat.name}';
      if (existingNames.contains(key)) continue;
      final iconId = _allocateIconId(
        inEx: 0,
        preferredIconId: cat.iconId ?? _iconIdFromImport(cat.icon),
        usedIconsByInEx: usedIconsByInEx,
      );
      await _db.insertCategory(
        inEx: 0,
        name: cat.name,
        iconId: iconId,
        isCustom: true,
      );
      existingNames.add(key);
      importedCategories++;
    }

    for (final cat in data.categories['income'] ?? []) {
      final key = '1_${cat.name}';
      if (existingNames.contains(key)) continue;
      final iconId = _allocateIconId(
        inEx: 1,
        preferredIconId: cat.iconId ?? _iconIdFromImport(cat.icon),
        usedIconsByInEx: usedIconsByInEx,
      );
      await _db.insertCategory(
        inEx: 1,
        name: cat.name,
        iconId: iconId,
        isCustom: true,
      );
      existingNames.add(key);
      importedCategories++;
    }

    // 账单、预算、资产按 id 合并。
    final existingBillIds = (await _db.getAllBills()).map((b) => b.id).toSet();
    final existingBudgetIds = (await _db.getAllBudgets()).map((b) => b.id).toSet();
    final existingAssetIds = (await _db.getAllAssets()).map((a) => a.id).toSet();

    for (final record in data.records) {
      final legacyGeneratedId = 'import_${record.date}_${record.amount}_${record.category}';
      final generatedId =
          'import_${insertedBills + skippedBills}_${record.date}_${record.amount}_${record.category}_${record.paymentMethod}';
      final id = record.id.isNotEmpty ? record.id : generatedId;
      if (existingBillIds.contains(id) ||
          (record.id.isEmpty && existingBillIds.contains(legacyGeneratedId))) {
        skippedBills++;
        continue;
      }
      final bill = record.toModel(
        fallbackWalletId,
        idOverride: id,
        allowedPaymentMethods: allowedPaymentMethodIds,
      );
      await _db.insertBill(bill);
      insertedBills++;
      existingBillIds.add(bill.id);
    }

    for (final budget in data.budgets) {
      final resolvedWalletId = budget.walletId.isEmpty ? fallbackWalletId : budget.walletId;
      final id = budget.id.isNotEmpty
          ? budget.id
          : 'import_budget_${resolvedWalletId}_${budget.periodType}_${budget.period}_${budget.category}_${budget.amount}_${importedBudgets + 1}';
      if (existingBudgetIds.contains(id)) continue;
      await _db.insertOrReplaceBudget(budget.toModel(fallbackWalletId, idOverride: id));
      importedBudgets++;
      existingBudgetIds.add(id);
    }

    for (final asset in data.assets) {
      final resolvedWalletId = asset.walletId.isEmpty ? fallbackWalletId : asset.walletId;
      final id = asset.id.isNotEmpty
          ? asset.id
          : 'import_asset_${resolvedWalletId}_${asset.type}_${asset.name}_${asset.amount}_${importedAssets + 1}';
      if (existingAssetIds.contains(id)) continue;
      await _db.insertAsset(asset.toModel(fallbackWalletId, idOverride: id));
      importedAssets++;
      existingAssetIds.add(id);
    }

    return ImportResult(
      totalRecords: data.records.length,
      insertedBills: insertedBills,
      skippedBills: skippedBills,
      importedPaymentMethods: importedPaymentMethods,
      importedCategories: importedCategories,
      importedWallets: importedWallets,
      importedBudgets: importedBudgets,
      importedAssets: importedAssets,
    );
  }

  ImportPreview previewFromJson(String jsonString) {
    final data = _parseJson(jsonString);
    return ImportPreview(
      formatVersion: data.formatVersion,
      source: data.source,
      exportedAt: data.exportedAt,
      walletCount: data.wallets.length,
      paymentMethodCount: data.paymentMethods.length,
      recordCount: data.records.length,
      budgetCount: data.budgets.length,
      assetCount: data.assets.length,
      expenseCategories: data.categories['expense']?.length ?? 0,
      incomeCategories: data.categories['income']?.length ?? 0,
    );
  }

  int? _iconIdFromImport(String rawIcon) {
    final raw = rawIcon.trim();
    if (raw.isEmpty) return null;
    final numericId = int.tryParse(raw);
    if (numericId != null) return _validIconId(numericId);

    final normalized = raw.replaceAll('\\', '/');
    final fileName = normalized.split('/').last;
    for (final icon in iconJson) {
      final candidates = [icon.icon, icon.iconL, icon.iconS];
      if (candidates.any((path) {
        final normalizedPath = path.replaceAll('\\', '/');
        return normalizedPath == normalized ||
            normalizedPath.split('/').last == fileName;
      })) {
        return icon.id;
      }
    }
    return null;
  }

  int? _validIconId(int iconId) {
    if (iconId < 0 || iconId >= iconJson.length) return null;
    return iconJson[iconId].id;
  }

  int _allocateIconId({
    required int inEx,
    required int? preferredIconId,
    required Map<int, Set<int>> usedIconsByInEx,
    bool reserve = true,
  }) {
    final usedIcons = usedIconsByInEx.putIfAbsent(inEx, () => <int>{});
    final preferred = _validIconId(preferredIconId ?? -1);
    if (preferred != null && !usedIcons.contains(preferred)) {
      if (reserve) usedIcons.add(preferred);
      return preferred;
    }

    for (final candidate in _iconCandidatesForImport()) {
      if (!usedIcons.contains(candidate)) {
        if (reserve) usedIcons.add(candidate);
        return candidate;
      }
    }

    return preferred ?? (inEx == 1 ? 37 : 32);
  }

  Iterable<int> _iconCandidatesForImport() sync* {
    for (final group in addCategoryJson) {
      for (final iconId in group.icon) {
        if (_validIconId(iconId) != null) yield iconId;
      }
    }
    for (final icon in iconJson) {
      yield icon.id;
    }
  }
}

/// 导入预览信息
class ImportPreview {
  final int formatVersion;
  final String source;
  final String exportedAt;
  final int walletCount;
  final int paymentMethodCount;
  final int recordCount;
  final int budgetCount;
  final int assetCount;
  final int expenseCategories;
  final int incomeCategories;

  const ImportPreview({
    required this.formatVersion,
    required this.source,
    required this.exportedAt,
    required this.walletCount,
    required this.paymentMethodCount,
    required this.recordCount,
    required this.budgetCount,
    required this.assetCount,
    required this.expenseCategories,
    required this.incomeCategories,
  });
}
