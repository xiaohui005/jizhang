# 资产管家与多钱包实施计划

> **对于代理工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 来逐任务实施此计划。步骤使用复选框（`- [ ]`）语法进行跟踪。

**目标：** 给应用补上本地资产管家，并支持 `钱包1`、`钱包2` 这类完全隔离的钱包账本，默认把现有数据放入 `钱包1`。

**架构：** 继续用 `sqflite` 做唯一存储层，在数据库里加入钱包维度。账单、预算、资产记录、统计都按当前钱包过滤，钱包切换通过本地设置驱动整条数据流刷新。资产管家先做最小可用版，只管负债、债权和净资产，不接网络，不做同步。

**技术栈：** Flutter, Riverpod, sqflite, SQLite migration, 本地设置表, widget test

---

### 任务 1：补齐钱包与资产的数据模型

**文件：**
- 修改：`lib/db/database_helper.dart`
- 修改：`lib/models/bill_item.dart`
- 修改：`lib/models/budget_item.dart`
- 创建：`lib/models/wallet_item.dart`
- 创建：`lib/models/asset_item.dart`
- 修改：`pubspec.yaml`
- 创建：`test/database_helper_wallet_test.dart`

- [ ] **步骤 1：写失败的测试**

```dart
test('default wallet exists after migration', () async {
  final db = await DatabaseHelper.instance.database;
  final wallets = await db.query('wallets');
  expect(wallets, isNotEmpty);
  expect(wallets.first['id'], 'wallet_default');
});

test('bills and budgets are stored with wallet id', () async {
  // 先切到 wallet_2，再插入一条账单和一条预算
  // 断言查询当前钱包时能看见，切回 wallet_1 时看不见
});
```

- [ ] **步骤 2：运行测试以验证它失败**

运行：`flutter test test/database_helper_wallet_test.dart -r expanded`

预期：失败，因为当前数据库还没有 `wallets` 表，也没有 `wallet_id` 归属。

- [ ] **步骤 3：写最少的实现**

```dart
// database_helper.dart
// 1. database version 升到 7
// 2. 新增 wallets 表和 asset_records 表
// 3. bills、budgets 增加 wallet_id 列，默认值为 wallet_default
// 4. budgets 唯一索引改成 (wallet_id, period_type, period, is_total, icon_id)
// 5. 旧数据在迁移时全部补成 wallet_default
// 6. 新增 getWallets / createWallet / getCurrentWalletId / setCurrentWalletId / getAssets / insertAsset / deleteAsset
// bill_item.dart 与 budget_item.dart 增加 walletId 字段并写入 toMap/fromMap
// 新建 WalletItem 和 AssetItem
```

- [ ] **步骤 4：运行测试以验证它通过**

运行：`flutter test test/database_helper_wallet_test.dart -r expanded`

预期：通过，默认钱包存在，旧数据能落到 `wallet_default`。

- [ ] **步骤 5：运行验证并确认结果**

运行：`flutter test`

预期：现有测试不回退，数据库迁移不破坏账单、预算和徽章相关读取。

### 任务 2：让账单、预算和统计按钱包隔离

**文件：**
- 创建：`lib/providers/wallet_provider.dart`
- 修改：`lib/providers/bill_provider.dart`
- 修改：`lib/providers/budget_provider.dart`
- 修改：`lib/providers/user_stats_provider.dart`
- 修改：`lib/db/database_helper.dart`
- 创建：`test/wallet_scope_provider_test.dart`

- [ ] **步骤 1：写失败的测试**

```dart
test('switching wallet changes visible bills and budgets', () async {
  // current wallet = wallet_1 时只看到 wallet_1 的账单
  // 切到 wallet_2 后，billListProvider 和 monthlySummaryProvider 重新计算
});
```

- [ ] **步骤 2：运行测试以验证它失败**

运行：`flutter test test/wallet_scope_provider_test.dart -r expanded`

预期：失败，因为当前 provider 还没接钱包维度。

- [ ] **步骤 3：写最少的实现**

```dart
// wallet_provider.dart
// 1. 读取 settings 里的当前钱包 id
// 2. 没有时创建并选中 wallet_default / 显示名钱包1
// 3. 提供钱包列表、当前钱包、切换钱包、创建钱包

// bill_provider.dart / budget_provider.dart / user_stats_provider.dart
// 4. watch currentWalletProvider
// 5. 所有数据库查询都传入 walletId
// 6. 账单增删改和预算更新保持当前钱包不变
```

- [ ] **步骤 4：运行测试以验证它通过**

运行：`flutter test test/wallet_scope_provider_test.dart -r expanded`

预期：通过，切钱包后只看当前钱包的数据。

- [ ] **步骤 5：运行验证并确认结果**

运行：`flutter test`

预期：`monthlySummaryProvider`、`budgetProvider`、`userStatsProvider` 都只统计当前钱包。

### 任务 3：实现资产管家页面和资产数据流

**文件：**
- 创建：`lib/models/asset_item.dart`
- 创建：`lib/providers/asset_provider.dart`
- 创建：`lib/pages/asset_manager_page.dart`
- 创建：`lib/widgets/asset_edit_sheet.dart`
- 修改：`lib/pages/home_page.dart`
- 修改：`lib/pages/main_shell.dart`
- 创建：`test/asset_manager_page_test.dart`

- [ ] **步骤 1：写失败的测试**

```dart
testWidgets('asset manager shows net assets and add button', (tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.pumpAndSettle();
  await tester.tap(find.text('资产管家'));
  await tester.pumpAndSettle();
  expect(find.text('净资产'), findsOneWidget);
  expect(find.text('负债'), findsOneWidget);
  expect(find.text('债权'), findsOneWidget);
  expect(find.text('添加资产'), findsOneWidget);
});
```

- [ ] **步骤 2：运行测试以验证它失败**

运行：`flutter test test/asset_manager_page_test.dart -r expanded`

预期：失败，因为当前还没有资产管家页面和入口。

- [ ] **步骤 3：写最少的实现**

```dart
// asset_provider.dart
// 1. 按 currentWalletProvider 读取当前钱包资产列表
// 2. 计算 debt_total、credit_total、net_assets
// 3. 提供新增、删除接口

// asset_manager_page.dart
// 4. 顶部显示净资产卡片
// 5. 中间分成负债和债权两个列表
// 6. 底部提供“添加资产”按钮
// 7. 新增/删除后自动刷新当前钱包数据

// asset_edit_sheet.dart
// 8. 共用表单，按 debt / credit 切换类型与文案
```

- [ ] **步骤 4：运行测试以验证它通过**

运行：`flutter test test/asset_manager_page_test.dart -r expanded`

预期：通过，首页能进入资产管家，页面能展示净资产和两个列表区块。

- [ ] **步骤 5：运行验证并确认结果**

运行：`flutter test`

预期：资产新增、删除和净资产计算都在当前钱包范围内生效。

### 任务 4：首页入口和钱包切换入口

**文件：**
- 修改：`lib/pages/home_page.dart`
- 修改：`lib/pages/discover_page.dart`
- 创建：`lib/widgets/wallet_switcher_sheet.dart`
- 修改：`lib/pages/mine_page.dart`
- 创建：`test/home_quick_actions_test.dart`

- [ ] **步骤 1：写失败的测试**

```dart
testWidgets('home page shows asset manager quick action', (tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.pumpAndSettle();
  expect(find.text('资产管家'), findsOneWidget);
  expect(find.text('账单'), findsOneWidget);
  expect(find.text('预算'), findsOneWidget);
});
```

- [ ] **步骤 2：运行测试以验证它失败**

运行：`flutter test test/home_quick_actions_test.dart -r expanded`

预期：失败，因为首页目前只有两个快捷入口。

- [ ] **步骤 3：写最少的实现**

```dart
// home_page.dart
// 1. 在快捷入口区增加“资产管家”
// 2. 入口跳转到 AssetManagerPage

// wallet_switcher_sheet.dart
// 3. 提供当前钱包名、钱包列表、切换钱包、创建钱包
// 4. 触发后刷新所有 wallet-scoped provider

// discover_page.dart / mine_page.dart
// 5. 显示当前钱包名称或入口，方便用户知道自己在看哪个账本
```

- [ ] **步骤 4：运行测试以验证它通过**

运行：`flutter test test/home_quick_actions_test.dart -r expanded`

预期：通过，首页第三个入口可见。

- [ ] **步骤 5：运行验证并确认结果**

运行：`flutter test`

预期：首页、钱包切换、资产管家三者联动正常。

### 任务 5：收尾、验证和推送

**文件：**
- 修改：`README.md`
- 修改：`docs/superpowers/specs/2026-07-29-asset-wallet-design.md`（如实现过程中需要补充细节）

- [ ] **步骤 1：做一次全量静态检查**

运行：`git diff --check`

预期：没有空白和补丁格式问题。

- [ ] **步骤 2：跑完整测试**

运行：`flutter test`

预期：全部通过。

- [ ] **步骤 3：检查工作区与提交内容**

运行：`git status --short`、`git diff --stat`

预期：只包含这次资产管家与多钱包相关改动。

- [ ] **步骤 4：提交并推送**

运行：`git add -A && git commit -m "feat: add asset manager and wallets" && git push origin main`

预期：GitHub 上可见新提交；如需要出包，再补一个 `v*` tag。
