# 数据导入导出实施计划

> **对于代理工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 来逐任务实施此计划。步骤使用复选框（`- [ ]`）语法进行跟踪。

**目标：** 给应用补上可恢复的数据备份，支持导出全部钱包的 JSON，并在导入时把数据合并回现有本地账本。

**架构：** 继续用本地 `sqflite` 作为唯一数据源，导出时一次性打包所有钱包、账单、预算、资产管家和分类数据，导入时按记录类型做幂等合并。导入不清空现有数据，重复项跳过，新增项写入当前数据库。这样用户重装、清数据或换机后，可以靠 JSON 恢复，而正常升级安装仍然沿用原本的本地库。

**技术栈：** Flutter, Riverpod, file_picker, json encode/decode, sqflite, 本地文件读写, widget test

---

### 任务 1：定义备份 JSON 结构并补测试

**文件：**
- 修改：`lib/services/import_service.dart`
- 创建：`lib/services/export_service.dart`
- 修改：`lib/models/bill_item.dart`
- 修改：`lib/models/budget_item.dart`
- 修改：`lib/models/asset_item.dart`
- 修改：`lib/models/wallet_item.dart`
- 修改：`test/database_helper_wallet_test.dart`
- 创建：`test/backup_json_roundtrip_test.dart`

- [ ] **步骤 1：写失败的测试**

```dart
test('export json contains all wallets and records', () async {
  // 准备两个钱包、账单、预算、资产
  // 导出后断言 JSON 包含 wallets / bills / budgets / assets 四个数组
});
```

- [ ] **步骤 2：运行测试以验证它失败**

运行：`flutter test test/backup_json_roundtrip_test.dart -r expanded`

预期：失败，因为目前还没有完整导出器。

- [ ] **步骤 3：写最少的实现**

```dart
// 新增 ExportService，输出结构大致如下：
// {
//   "formatVersion": 2,
//   "source": "ledger_flutter",
//   "exportedAt": "2026-07-29T10:43:00.000Z",
//   "wallets": [...],
//   "bills": [...],
//   "budgets": [...],
//   "assets": [...],
//   "categories": {...}
// }
// 导出范围是全部钱包。
```

- [ ] **步骤 4：运行测试以验证它通过**

运行：`flutter test test/backup_json_roundtrip_test.dart -r expanded`

预期：通过，JSON 可完整还原数据结构。

- [ ] **步骤 5：运行验证并确认结果**

运行：`flutter test`

预期：现有测试不回退，新的备份结构不会破坏导入导出基础。

### 任务 2：实现导出全部钱包的文件生成

**文件：**
- 创建：`lib/services/export_service.dart`
- 修改：`lib/services/import_service.dart`
- 修改：`lib/db/database_helper.dart`
- 创建：`test/export_service_test.dart`

- [ ] **步骤 1：写失败的测试**

```dart
test('export service writes a json file path', () async {
  // 给一个临时目录，导出后断言生成 .json 文件且内容能被 decode
});
```

- [ ] **步骤 2：运行测试以验证它失败**

运行：`flutter test test/export_service_test.dart -r expanded`

预期：失败，因为导出服务还不存在。

- [ ] **步骤 3：写最少的实现**

```dart
// ExportService 提供：
// - buildExportJson(): 返回字符串
// - exportToFile(path): 写入 JSON 文件
// 内容从 database_helper 读取所有 wallets / bills / budgets / asset_records / categories。
```

- [ ] **步骤 4：运行测试以验证它通过**

运行：`flutter test test/export_service_test.dart -r expanded`

预期：通过，文件生成且 JSON 可解析。

- [ ] **步骤 5：运行验证并确认结果**

运行：`flutter test`

预期：导出不会影响现有数据查询和钱包隔离逻辑。

### 任务 3：实现合并式 JSON 导入

**文件：**
- 修改：`lib/services/import_service.dart`
- 修改：`lib/db/database_helper.dart`
- 创建：`test/import_merge_test.dart`

- [ ] **步骤 1：写失败的测试**

```dart
test('import merges into existing data instead of clearing it', () async {
  // 先放一条本地账单，再导入含新旧混合数据的 JSON
  // 断言原账单保留，新数据补进来，重复项跳过
});
```

- [ ] **步骤 2：运行测试以验证它失败**

运行：`flutter test test/import_merge_test.dart -r expanded`

预期：失败，因为当前导入只覆盖了部分场景，还没完整覆盖钱包、资产和预算合并。

- [ ] **步骤 3：写最少的实现**

```dart
// 导入规则：
// 1. 钱包按 id 去重，已有钱包保留，缺失钱包补入
// 2. bills / budgets / assets 以 id 去重，重复项跳过
// 3. 不清空现有数据
// 4. 导入记录归到对应 wallet_id
// 5. 保持当前选中钱包不变
```

- [ ] **步骤 4：运行测试以验证它通过**

运行：`flutter test test/import_merge_test.dart -r expanded`

预期：通过，导入后旧数据还在，新数据合并进去。

- [ ] **步骤 5：运行验证并确认结果**

运行：`flutter test`

预期：导入、钱包隔离和统计逻辑继续正常。

### 任务 4：补 UI 入口，支持导出 / 导入

**文件：**
- 修改：`lib/pages/mine_page.dart`
- 修改：`lib/services/import_service.dart`
- 创建：`lib/services/export_service.dart`
- 创建：`test/mine_backup_actions_test.dart`

- [ ] **步骤 1：写失败的测试**

```dart
testWidgets('mine page shows import export actions', (tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.pumpAndSettle();
  expect(find.text('数据导入'), findsOneWidget);
  expect(find.text('数据导出'), findsOneWidget);
});
```

- [ ] **步骤 2：运行测试以验证它失败**

运行：`flutter test test/mine_backup_actions_test.dart -r expanded`

预期：失败，因为页面还没有导出入口。

- [ ] **步骤 3：写最少的实现**

```dart
// 在「我的」页数据区增加两个动作：
// - 数据导出：调用 ExportService，生成 JSON 文件
// - 数据导入：调用现有 ImportService，但导入逻辑改为合并模式
// 文件选择继续沿用 file_picker
```

- [ ] **步骤 4：运行测试以验证它通过**

运行：`flutter test test/mine_backup_actions_test.dart -r expanded`

预期：通过，用户能看到导出 / 导入入口。

- [ ] **步骤 5：运行验证并确认结果**

运行：`flutter test`

预期：入口、导出和导入都在当前 UI 中可用。

### 任务 5：文档、收尾和推送

**文件：**
- 修改：`README.md`
- 修改：`docs/superpowers/specs/2026-07-29-backup-json-design.md`（如实现过程中需要补充细节）

- [ ] **步骤 1：做一次全量静态检查**

运行：`git diff --check`

预期：没有格式错误。

- [ ] **步骤 2：跑完整测试**

运行：`flutter test`

预期：全部通过。

- [ ] **步骤 3：检查工作区与提交内容**

运行：`git status --short`、`git diff --stat`

预期：只包含备份、导入导出和必要的 UI 改动。

- [ ] **步骤 4：提交并推送**

运行：`git add -A && git commit -m "feat: add json backup import export" && git push origin main`

预期：GitHub 上可见新提交；如需要出包，再补一个 `v*` tag。
