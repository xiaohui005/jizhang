import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../data/account_data.dart';
import '../models/asset_item.dart';
import '../models/bill_item.dart';
import '../models/budget_item.dart';
import '../models/category_entry.dart';
import '../models/wallet_item.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;
  static String? _databasePathOverride;

  static const _currentWalletSettingKey = 'current_wallet_id';
  static const _defaultWalletId = BillItem.defaultWalletId;
  static const _defaultWalletName = '钱包1';

  String _walletClause(String base, String? walletId) {
    if (walletId == null) return base;
    return '$base AND wallet_id = ?';
  }

  String _paymentMethodClause(String base, String? paymentMethod) {
    if (paymentMethod == null || paymentMethod.isEmpty) return base;
    return '$base AND payment_method = ?';
  }

  List<Object?> _walletAndPaymentArgs(
    List<Object?> args, {
    String? walletId,
    String? paymentMethod,
  }) {
    final result = [...args];
    if (walletId != null) {
      result.add(walletId);
    }
    if (paymentMethod != null && paymentMethod.isNotEmpty) {
      result.add(paymentMethod);
    }
    return result;
  }

  static Future<void> resetForTest() async {
    final db = _database;
    _database = null;
    if (db != null) {
      await db.close();
    }
  }

  static void overrideDatabasePathForTest(String? path) {
    _databasePathOverride = path;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final path = _databasePathOverride ??
        join(await getDatabasesPath(), 'ledger.db');

    return openDatabase(
      path,
      version: 8,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE bills (
            id TEXT PRIMARY KEY,
            wallet_id TEXT NOT NULL DEFAULT 'wallet_default',
            type TEXT NOT NULL,
            payment_method TEXT NOT NULL DEFAULT 'wechat',
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
        await _createBudgetsTable(db);
        await _createSettingsTable(db);
        await _createWalletsTable(db);
        await _createAssetsTable(db);
        await _createCategoriesTable(db);
        await _seedDefaultWallet(db);
        await _seedDefaultCategories(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE bills ADD COLUMN icon_id INTEGER NOT NULL DEFAULT 0');
        }
        if (oldVersion < 3) {
          await db.execute("ALTER TABLE bills ADD COLUMN sort_at TEXT NOT NULL DEFAULT ''");
          await db.execute("UPDATE bills SET sort_at = date WHERE sort_at = ''");
        }
        if (oldVersion < 4) {
          await _createBudgetsTable(db);
        }
        if (oldVersion < 5) {
          await _createSettingsTable(db);
        }
        if (oldVersion < 6) {
          await _createCategoriesTable(db);
          await _seedDefaultCategories(db);
        }
        if (oldVersion < 7) {
          await _createWalletsTable(db);
          await _createAssetsTable(db);
          await db.execute(
            "ALTER TABLE bills ADD COLUMN wallet_id TEXT NOT NULL DEFAULT 'wallet_default'",
          );
          if (oldVersion >= 4) {
            await db.execute(
              "ALTER TABLE budgets ADD COLUMN wallet_id TEXT NOT NULL DEFAULT 'wallet_default'",
            );
          }
          await db.execute(
            "UPDATE bills SET wallet_id = 'wallet_default' WHERE wallet_id IS NULL OR wallet_id = ''",
          );
          if (oldVersion >= 4) {
            await db.execute(
              "UPDATE budgets SET wallet_id = 'wallet_default' WHERE wallet_id IS NULL OR wallet_id = ''",
            );
          }
          await db.execute('DROP INDEX IF EXISTS idx_budgets_unique');
          await db.execute('''
            CREATE UNIQUE INDEX IF NOT EXISTS idx_budgets_unique
            ON budgets(wallet_id, period_type, period, is_total, icon_id)
          ''');
          await _ensureDefaultWallet(db);
        }
        if (oldVersion < 8) {
          await db.execute(
            "ALTER TABLE bills ADD COLUMN payment_method TEXT NOT NULL DEFAULT 'wechat'",
          );
          await db.execute(
            "UPDATE bills SET payment_method = 'wechat' WHERE payment_method IS NULL OR payment_method = '' OR payment_method NOT IN ('wechat', 'alipay', 'bank')",
          );
        }
      },
    );
  }

  Future<void> _createWalletsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS wallets (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createAssetsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS asset_records (
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
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_asset_records_wallet
      ON asset_records(wallet_id, type)
    ''');
  }

  Future<void> _createBudgetsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS budgets (
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
      CREATE UNIQUE INDEX IF NOT EXISTS idx_budgets_unique
      ON budgets(wallet_id, period_type, period, is_total, icon_id)
    ''');
  }

  Future<void> _createSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> _seedDefaultWallet(Database db) async {
    final now = DateTime.now().toIso8601String();
    await db.insert(
      'wallets',
      {
        'id': _defaultWalletId,
        'name': _defaultWalletName,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    await setSetting(_currentWalletSettingKey, _defaultWalletId, db: db);
  }

  Future<void> _createCategoriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
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
      CREATE INDEX IF NOT EXISTS idx_categories_inex_order
      ON categories(in_ex, sort_order)
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_categories_inex_name
      ON categories(in_ex, name)
    ''');
  }

  Future<void> _ensureDefaultWallet(Database db) async {
    final wallets = await db.query(
      'wallets',
      where: 'id = ?',
      whereArgs: [_defaultWalletId],
      limit: 1,
    );
    if (wallets.isEmpty) {
      await _seedDefaultWallet(db);
    }
  }

  /// 把 [categoryJson] 中的默认类别写入 categories 表，作为初始数据。
  /// 同一 in_ex 内按 [categoryJson] 出现顺序作为 sort_order。
  Future<void> _seedDefaultCategories(Database db) async {
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    final orderByInEx = <int, int>{};
    for (final cat in categoryJson) {
      final order = orderByInEx[cat.inEx] ?? 0;
      orderByInEx[cat.inEx] = order + 1;
      batch.insert(
        'categories',
        {
          'in_ex': cat.inEx,
          'name': cat.name,
          'icon_id': cat.icon,
          'is_custom': 0,
          'sort_order': order,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  /// 插入一条账单
  Future<void> insertBill(BillItem bill) async {
    final db = await database;
    await db.insert('bills', bill.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// 查询所有账单，按日期倒序
  Future<List<BillItem>> getAllBills({String? walletId, String? paymentMethod}) async {
    final db = await database;
    final where = walletId == null
        ? _paymentMethodClause('1 = 1', paymentMethod)
        : _paymentMethodClause('wallet_id = ?', paymentMethod);
    final rows = await db.query(
      'bills',
      where: where,
      whereArgs: _walletAndPaymentArgs(
        const <Object?>[],
        walletId: walletId,
        paymentMethod: paymentMethod,
      ),
      orderBy: "substr(date, 1, 10) DESC, sort_at DESC, date DESC",
    );
    return rows.map((r) => BillItem.fromMap(r)).toList();
  }

  /// 按日期范围查询账单 (start/end 格式: "2026-03-01")
  Future<List<BillItem>> getBillsByDateRange(
    String start,
    String end, {
    String? walletId,
    String? paymentMethod,
  }) async {
    final db = await database;
    final rows = await db.query(
      'bills',
      where: _paymentMethodClause(
        _walletClause(
          "substr(date, 1, 10) >= ? AND substr(date, 1, 10) <= ?",
          walletId,
        ),
        paymentMethod,
      ),
      whereArgs: _walletAndPaymentArgs(
        [start, end],
        walletId: walletId,
        paymentMethod: paymentMethod,
      ),
      orderBy: "substr(date, 1, 10) DESC, sort_at DESC, date DESC",
    );
    return rows.map((r) => BillItem.fromMap(r)).toList();
  }

  /// 按月查询账单 (yearMonth 格式: "2026-03")
  Future<List<BillItem>> getBillsByMonth(
    String yearMonth, {
    String? walletId,
    String? paymentMethod,
  }) async {
    final db = await database;
    final rows = await db.query(
      'bills',
      where: _paymentMethodClause(
        _walletClause("date LIKE ?", walletId),
        paymentMethod,
      ),
      whereArgs: _walletAndPaymentArgs(
        ['$yearMonth%'],
        walletId: walletId,
        paymentMethod: paymentMethod,
      ),
      orderBy: "substr(date, 1, 10) DESC, sort_at DESC, date DESC",
    );
    return rows.map((r) => BillItem.fromMap(r)).toList();
  }

  /// 根据 id 查询单条账单
  Future<BillItem?> getBillById(
    String id, {
    String? walletId,
    String? paymentMethod,
  }) async {
    final db = await database;
    final rows = await db.query(
      'bills',
      where: _paymentMethodClause(_walletClause('id = ?', walletId), paymentMethod),
      whereArgs: _walletAndPaymentArgs(
        [id],
        walletId: walletId,
        paymentMethod: paymentMethod,
      ),
    );
    if (rows.isEmpty) return null;
    return BillItem.fromMap(rows.first);
  }

  /// 更新账单
  Future<int> updateBill(BillItem bill) async {
    final db = await database;
    return db.update('bills', bill.toMap(),
        where: 'id = ?', whereArgs: [bill.id]);
  }

  /// 删除账单
  Future<int> deleteBill(String id) async {
    final db = await database;
    return db.delete('bills', where: 'id = ?', whereArgs: [id]);
  }

  /// 查询某月收入总额
  Future<double> getMonthlyIncome(
    String yearMonth, {
    String? walletId,
    String? paymentMethod,
  }) async {
    final db = await database;
    final result = await db.rawQuery(
      paymentMethod == null || paymentMethod.isEmpty
          ? (walletId == null
              ? "SELECT COALESCE(SUM(amount), 0) as total FROM bills WHERE type = 'income' AND date LIKE ?"
              : "SELECT COALESCE(SUM(amount), 0) as total FROM bills WHERE type = 'income' AND date LIKE ? AND wallet_id = ?")
          : (walletId == null
              ? "SELECT COALESCE(SUM(amount), 0) as total FROM bills WHERE type = 'income' AND date LIKE ? AND payment_method = ?"
              : "SELECT COALESCE(SUM(amount), 0) as total FROM bills WHERE type = 'income' AND date LIKE ? AND wallet_id = ? AND payment_method = ?"),
      paymentMethod == null || paymentMethod.isEmpty
          ? (walletId == null ? ['$yearMonth%'] : ['$yearMonth%', walletId])
          : (walletId == null
              ? ['$yearMonth%', paymentMethod]
              : ['$yearMonth%', walletId, paymentMethod]),
    );
    return (result.first['total'] as num).toDouble();
  }

  /// 查询某月支出总额
  Future<double> getMonthlyExpense(
    String yearMonth, {
    String? walletId,
    String? paymentMethod,
  }) async {
    final db = await database;
    final result = await db.rawQuery(
      paymentMethod == null || paymentMethod.isEmpty
          ? (walletId == null
              ? "SELECT COALESCE(SUM(amount), 0) as total FROM bills WHERE type = 'expense' AND date LIKE ?"
              : "SELECT COALESCE(SUM(amount), 0) as total FROM bills WHERE type = 'expense' AND date LIKE ? AND wallet_id = ?")
          : (walletId == null
              ? "SELECT COALESCE(SUM(amount), 0) as total FROM bills WHERE type = 'expense' AND date LIKE ? AND payment_method = ?"
              : "SELECT COALESCE(SUM(amount), 0) as total FROM bills WHERE type = 'expense' AND date LIKE ? AND wallet_id = ? AND payment_method = ?"),
      paymentMethod == null || paymentMethod.isEmpty
          ? (walletId == null ? ['$yearMonth%'] : ['$yearMonth%', walletId])
          : (walletId == null
              ? ['$yearMonth%', paymentMethod]
              : ['$yearMonth%', walletId, paymentMethod]),
    );
    return (result.first['total'] as num).toDouble();
  }

  /// 按年查询账单 (year 格式: "2026")
  Future<List<BillItem>> getBillsByYear(
    String year, {
    String? walletId,
    String? paymentMethod,
  }) async {
    final db = await database;
    final rows = await db.query(
      'bills',
      where: _paymentMethodClause(_walletClause("date LIKE ?", walletId), paymentMethod),
      whereArgs: _walletAndPaymentArgs(
        ['$year%'],
        walletId: walletId,
        paymentMethod: paymentMethod,
      ),
      orderBy: "substr(date, 1, 10) DESC, sort_at DESC, date DESC",
    );
    return rows.map((r) => BillItem.fromMap(r)).toList();
  }

  /// 查询某年收入总额
  Future<double> getYearlyIncome(
    String year, {
    String? walletId,
    String? paymentMethod,
  }) async {
    final db = await database;
    final result = await db.rawQuery(
      paymentMethod == null || paymentMethod.isEmpty
          ? (walletId == null
              ? "SELECT COALESCE(SUM(amount), 0) as total FROM bills WHERE type = 'income' AND date LIKE ?"
              : "SELECT COALESCE(SUM(amount), 0) as total FROM bills WHERE type = 'income' AND date LIKE ? AND wallet_id = ?")
          : (walletId == null
              ? "SELECT COALESCE(SUM(amount), 0) as total FROM bills WHERE type = 'income' AND date LIKE ? AND payment_method = ?"
              : "SELECT COALESCE(SUM(amount), 0) as total FROM bills WHERE type = 'income' AND date LIKE ? AND wallet_id = ? AND payment_method = ?"),
      paymentMethod == null || paymentMethod.isEmpty
          ? (walletId == null ? ['$year%'] : ['$year%', walletId])
          : (walletId == null
              ? ['$year%', paymentMethod]
              : ['$year%', walletId, paymentMethod]),
    );
    return (result.first['total'] as num).toDouble();
  }

  /// 查询某年支出总额
  Future<double> getYearlyExpense(
    String year, {
    String? walletId,
    String? paymentMethod,
  }) async {
    final db = await database;
    final result = await db.rawQuery(
      paymentMethod == null || paymentMethod.isEmpty
          ? (walletId == null
              ? "SELECT COALESCE(SUM(amount), 0) as total FROM bills WHERE type = 'expense' AND date LIKE ?"
              : "SELECT COALESCE(SUM(amount), 0) as total FROM bills WHERE type = 'expense' AND date LIKE ? AND wallet_id = ?")
          : (walletId == null
              ? "SELECT COALESCE(SUM(amount), 0) as total FROM bills WHERE type = 'expense' AND date LIKE ? AND payment_method = ?"
              : "SELECT COALESCE(SUM(amount), 0) as total FROM bills WHERE type = 'expense' AND date LIKE ? AND wallet_id = ? AND payment_method = ?"),
      paymentMethod == null || paymentMethod.isEmpty
          ? (walletId == null ? ['$year%'] : ['$year%', walletId])
          : (walletId == null
              ? ['$year%', paymentMethod]
              : ['$year%', walletId, paymentMethod]),
    );
    return (result.first['total'] as num).toDouble();
  }

  /// 按分类（icon_id）分组的支出汇总
  ///
  /// [datePrefix] 为日期前缀，月份传 'YYYY-MM'，年度传 'YYYY'
  /// 返回 `Map<icon_id, 支出总额>`
  Future<Map<int, double>> getExpenseGroupByIconId(
    String datePrefix, {
    String? walletId,
    String? paymentMethod,
  }) async {
    final db = await database;
    final rows = await db.rawQuery(
      paymentMethod == null || paymentMethod.isEmpty
          ? (walletId == null
              ? "SELECT icon_id, COALESCE(SUM(amount), 0) as total FROM bills "
                  "WHERE type = 'expense' AND date LIKE ? GROUP BY icon_id"
              : "SELECT icon_id, COALESCE(SUM(amount), 0) as total FROM bills "
                  "WHERE type = 'expense' AND date LIKE ? AND wallet_id = ? GROUP BY icon_id")
          : (walletId == null
              ? "SELECT icon_id, COALESCE(SUM(amount), 0) as total FROM bills "
                  "WHERE type = 'expense' AND date LIKE ? AND payment_method = ? GROUP BY icon_id"
              : "SELECT icon_id, COALESCE(SUM(amount), 0) as total FROM bills "
                  "WHERE type = 'expense' AND date LIKE ? AND wallet_id = ? AND payment_method = ? GROUP BY icon_id"),
      paymentMethod == null || paymentMethod.isEmpty
          ? (walletId == null ? ['$datePrefix%'] : ['$datePrefix%', walletId])
          : (walletId == null
              ? ['$datePrefix%', paymentMethod]
              : ['$datePrefix%', walletId, paymentMethod]),
    );
    final result = <int, double>{};
    for (final row in rows) {
      result[row['icon_id'] as int] = (row['total'] as num).toDouble();
    }
    return result;
  }

  /// 写入或替换一条预算记录
  Future<void> insertOrReplaceBudget(BudgetItem budget) async {
    final db = await database;
    await db.insert(
      'budgets',
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 查询某 period 下的所有预算（包括总预算与分类预算）
  Future<List<BudgetItem>> getBudgets({
    required String periodType,
    required String period,
    String? walletId,
  }) async {
    final db = await database;
    final rows = await db.query(
      'budgets',
      where: _walletClause('period_type = ? AND period = ?', walletId),
      whereArgs: walletId == null ? [periodType, period] : [periodType, period, walletId],
    );
    return rows.map((r) => BudgetItem.fromMap(r)).toList();
  }

  /// 删除一条预算记录
  Future<int> deleteBudget(String id) async {
    final db = await database;
    return db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  /// 读取一条本地设置；不存在返回 null
  Future<String?> getSetting(String key, {Database? db}) async {
    final databaseRef = db ?? await database;
    final rows = await databaseRef.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  /// 写入一条本地设置（已存在则覆盖）
  Future<void> setSetting(String key, String value, {Database? db}) async {
    final databaseRef = db ?? await database;
    await databaseRef.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<WalletItem>> getWallets() async {
    final db = await database;
    final rows = await db.query('wallets', orderBy: 'created_at ASC');
    return rows.map(WalletItem.fromMap).toList();
  }

  Future<void> insertWallet(WalletItem wallet) async {
    final db = await database;
    await db.insert(
      'wallets',
      wallet.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<BudgetItem>> getAllBudgets() async {
    final db = await database;
    final rows = await db.query(
      'budgets',
      orderBy: 'period_type ASC, period ASC, is_total DESC, icon_id ASC',
    );
    return rows.map(BudgetItem.fromMap).toList();
  }

  Future<String> getCurrentWalletId() async {
    final db = await database;
    final id = await getSetting(_currentWalletSettingKey, db: db);
    if (id != null && id.isNotEmpty) {
      final wallets = await db.query(
        'wallets',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (wallets.isNotEmpty) return id;
    }
    await _ensureDefaultWallet(db);
    return _defaultWalletId;
  }

  Future<void> setCurrentWalletId(String walletId) async {
    final db = await database;
    await setSetting(_currentWalletSettingKey, walletId, db: db);
  }

  Future<WalletItem> createWallet(String name) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final id = 'wallet_${DateTime.now().millisecondsSinceEpoch}';
    final wallet = WalletItem(
      id: id,
      name: name,
      createdAt: now,
      updatedAt: now,
    );
    await db.insert('wallets', wallet.toMap());
    return wallet;
  }

  Future<List<AssetItem>> getAssets({String? walletId}) async {
    final db = await database;
    final args = <Object?>[];
    var where = '1 = 1';
    if (walletId != null) {
      where += ' AND wallet_id = ?';
      args.add(walletId);
    }
    final rows = await db.query(
      'asset_records',
      where: where,
      whereArgs: args,
      orderBy: 'created_at DESC',
    );
    return rows.map(AssetItem.fromMap).toList();
  }

  Future<List<AssetItem>> getAllAssets() async {
    return getAssets();
  }

  Future<void> insertAsset(AssetItem asset) async {
    final db = await database;
    await db.insert('asset_records', asset.toMap());
  }

  Future<int> deleteAsset(String id) async {
    final db = await database;
    return db.delete('asset_records', where: 'id = ?', whereArgs: [id]);
  }

  /// 账单总条数
  Future<int> getTotalBillCount({String? walletId, String? paymentMethod}) async {
    final db = await database;
    final result = await db.rawQuery(
      paymentMethod == null || paymentMethod.isEmpty
          ? (walletId == null
              ? 'SELECT COUNT(*) as cnt FROM bills'
              : 'SELECT COUNT(*) as cnt FROM bills WHERE wallet_id = ?')
          : (walletId == null
              ? 'SELECT COUNT(*) as cnt FROM bills WHERE payment_method = ?'
              : 'SELECT COUNT(*) as cnt FROM bills WHERE wallet_id = ? AND payment_method = ?'),
      paymentMethod == null || paymentMethod.isEmpty
          ? (walletId == null ? [] : [walletId])
          : (walletId == null ? [paymentMethod] : [walletId, paymentMethod]),
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  /// 所有账单 distinct 的 yyyy-MM-dd 日期，按升序
  Future<List<String>> getDistinctBillDates({String? walletId, String? paymentMethod}) async {
    final db = await database;
    final rows = await db.rawQuery(
      paymentMethod == null || paymentMethod.isEmpty
          ? (walletId == null
              ? "SELECT DISTINCT substr(date, 1, 10) AS d FROM bills ORDER BY d ASC"
              : "SELECT DISTINCT substr(date, 1, 10) AS d FROM bills WHERE wallet_id = ? ORDER BY d ASC")
          : (walletId == null
              ? "SELECT DISTINCT substr(date, 1, 10) AS d FROM bills WHERE payment_method = ? ORDER BY d ASC"
              : "SELECT DISTINCT substr(date, 1, 10) AS d FROM bills WHERE wallet_id = ? AND payment_method = ? ORDER BY d ASC"),
      paymentMethod == null || paymentMethod.isEmpty
          ? (walletId == null ? [] : [walletId])
          : (walletId == null ? [paymentMethod] : [walletId, paymentMethod]),
    );
    return [
      for (final row in rows)
        if (row['d'] != null) row['d'] as String,
    ];
  }

  /// 各 icon_id 对应的账单笔数（不区分收支），用于徽章成就判定。
  /// 返回 `Map<icon_id, 笔数>`
  Future<Map<int, int>> getBillCountGroupByIconId({String? walletId, String? paymentMethod}) async {
    final db = await database;
    final rows = await db.rawQuery(
      paymentMethod == null || paymentMethod.isEmpty
          ? (walletId == null
              ? 'SELECT icon_id, COUNT(*) AS cnt FROM bills GROUP BY icon_id'
              : 'SELECT icon_id, COUNT(*) AS cnt FROM bills WHERE wallet_id = ? GROUP BY icon_id')
          : (walletId == null
              ? 'SELECT icon_id, COUNT(*) AS cnt FROM bills WHERE payment_method = ? GROUP BY icon_id'
              : 'SELECT icon_id, COUNT(*) AS cnt FROM bills WHERE wallet_id = ? AND payment_method = ? GROUP BY icon_id'),
      paymentMethod == null || paymentMethod.isEmpty
          ? (walletId == null ? [] : [walletId])
          : (walletId == null ? [paymentMethod] : [walletId, paymentMethod]),
    );
    final result = <int, int>{};
    for (final row in rows) {
      result[row['icon_id'] as int] = (row['cnt'] as int?) ?? 0;
    }
    return result;
  }

  // ============================ categories ============================

  /// 全量类别，按 (in_ex, sort_order) 升序。
  Future<List<CategoryEntry>> getAllCategories() async {
    final db = await database;
    final rows = await db.query(
      'categories',
      orderBy: 'in_ex ASC, sort_order ASC, id ASC',
    );
    return rows.map(CategoryEntry.fromMap).toList();
  }

  /// 根据 (in_ex, name) 唯一索引检查是否已经存在；
  /// [excludeId] 用于编辑场景下排除自己。
  Future<bool> hasCategoryWithName({
    required int inEx,
    required String name,
    int? excludeId,
  }) async {
    final db = await database;
    final args = <Object?>[inEx, name];
    var where = 'in_ex = ? AND name = ?';
    if (excludeId != null) {
      where += ' AND id != ?';
      args.add(excludeId);
    }
    final rows = await db.query(
      'categories',
      where: where,
      whereArgs: args,
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// 插入新类别（一般是自定义类别），自动放在该 in_ex 列表末尾。
  /// 返回新类别的 id。
  Future<int> insertCategory({
    required int inEx,
    required String name,
    required int iconId,
    required bool isCustom,
  }) async {
    final db = await database;
    final maxRow = await db.rawQuery(
      'SELECT COALESCE(MAX(sort_order), -1) AS max_order '
      'FROM categories WHERE in_ex = ?',
      [inEx],
    );
    final nextOrder =
        ((maxRow.first['max_order'] as num?)?.toInt() ?? -1) + 1;
    final now = DateTime.now().toIso8601String();
    return db.insert('categories', {
      'in_ex': inEx,
      'name': name,
      'icon_id': iconId,
      'is_custom': isCustom ? 1 : 0,
      'sort_order': nextOrder,
      'created_at': now,
      'updated_at': now,
    });
  }

  /// 更新类别基础字段（name / icon_id）。
  Future<int> updateCategoryBasic({
    required int id,
    required String name,
    required int iconId,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return db.update(
      'categories',
      {'name': name, 'icon_id': iconId, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 删除类别（仅删 categories 行，不动 bills）。
  Future<int> deleteCategory(int id) async {
    final db = await database;
    return db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  /// 按当前列表顺序写入 sort_order，仅更新该 inEx 下的类别。
  ///
  /// [orderedIds] 必须是该 inEx 下完整且不重复的 id 序列。
  Future<void> reorderCategories({
    required int inEx,
    required List<int> orderedIds,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    for (var i = 0; i < orderedIds.length; i++) {
      batch.update(
        'categories',
        {'sort_order': i, 'updated_at': now},
        where: 'id = ? AND in_ex = ?',
        whereArgs: [orderedIds[i], inEx],
      );
    }
    await batch.commit(noResult: true);
  }

  /// 更新该 (type, oldName) 下所有账单的分类名 / 图标，用于"编辑分类"
  /// 时同步带过去。
  Future<int> updateBillsCategoryRename({
    required String type,
    required String oldName,
    required String newName,
    required int newIconId,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return db.update(
      'bills',
      {'category': newName, 'icon_id': newIconId, 'updated_at': now},
      where: 'type = ? AND category = ?',
      whereArgs: [type, oldName],
    );
  }

  /// 删除某分类下的全部账单（用于"仍然删除"分支）。
  Future<int> deleteBillsByTypeAndCategory({
    required String type,
    required String category,
  }) async {
    final db = await database;
    return db.delete(
      'bills',
      where: 'type = ? AND category = ?',
      whereArgs: [type, category],
    );
  }

  /// 把 (type, fromCategory) 的账单批量转移到 (toCategory, toIconId)。
  /// 用于"转移数据"分支。
  Future<int> transferBillsCategory({
    required String type,
    required String fromCategory,
    required String toCategory,
    required int toIconId,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return db.update(
      'bills',
      {'category': toCategory, 'icon_id': toIconId, 'updated_at': now},
      where: 'type = ? AND category = ?',
      whereArgs: [type, fromCategory],
    );
  }
}
