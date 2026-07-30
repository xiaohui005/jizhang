# 支付方式功能实施计划

> **对于代理工作者：** 必需子技能：使用 `superpowers:subagent-driven-development`（推荐）或 `superpowers:executing-plans` 来逐任务实施此计划。步骤使用复选框（`- [ ]`）语法进行跟踪。

**目标：** 给支出和收入增加 `微信 / 支付宝 / 银行卡` 支付方式，支持新增、编辑、筛选和统计，并兼容旧账默认回填为微信。

**架构：** 以 `BillItem` 为单一数据源，把支付方式作为账单字段写入数据库、导入导出和 UI。录入页继续使用现有记账键盘流程，只是在账单编辑状态旁边增加一个支付方式选择和“记住上次选择”的默认值。展示层只消费同一个字段，不单独拆出支付方式管理体系。

**技术栈：** Flutter、Riverpod、sqflite、现有底部弹层/记账键盘组件。

---

### 任务 1：补数据模型和数据库迁移

**文件：**
- 修改：`lib/models/bill_item.dart`
- 修改：`lib/db/database_helper.dart`
- 修改：`lib/services/export_service.dart`
- 修改：`lib/services/import_service.dart`
- 创建：`lib/models/payment_method.dart`
- 测试：`test/payment_method_migration_test.dart`
- 测试：`test/backup_json_roundtrip_test.dart`

- [ ] **步骤 1：写失败的测试**

```dart
test('old bills are migrated to wechat payment method', () async {
  final db = DatabaseHelper.instance;
  await db.database;
  final bills = await db.getAllBills();
  expect(bills.every((bill) => bill.paymentMethod == PaymentMethod.wechat), isTrue);
});
```

- [ ] **步骤 2：运行测试以验证它失败**

运行：`flutter test test/payment_method_migration_test.dart -v`

预期：失败，因为 `BillItem` 还没有 `paymentMethod` 字段，数据库也还没迁移。

- [ ] **步骤 3：写最少的实现**

```dart
class PaymentMethod {
  static const wechat = 'wechat';
  static const alipay = 'alipay';
  static const bank = 'bank';

  static const values = [wechat, alipay, bank];
}
```

在 `BillItem` 里增加 `paymentMethod`，在 `toMap` / `fromMap` / `copyWith` 里同步处理；在 `DatabaseHelper` 的 `bills` 表升级里补 `payment_method TEXT NOT NULL DEFAULT 'wechat'`，并把历史记录统一更新为 `wechat`。

- [ ] **步骤 4：运行测试以验证它通过**

运行：`flutter test test/payment_method_migration_test.dart -v`

预期：通过。

- [ ] **步骤 5：运行导入导出回环验证**

运行：`flutter test test/backup_json_roundtrip_test.dart -v`

预期：通过，导出 JSON 会带上支付方式，导入旧 JSON 时默认补成 `wechat`。

### 任务 2：把录入和编辑接上支付方式

**文件：**
- 修改：`lib/pages/billing_page.dart`
- 修改：`lib/providers/bill_provider.dart`
- 修改：`lib/providers/keyboard_provider.dart`
- 创建：`lib/providers/payment_method_provider.dart`
- 创建：`lib/widgets/payment_method_picker.dart`
- 修改：`lib/widgets/calculator_keyboard.dart`
- 测试：`test/billing_page_payment_method_test.dart`

- [ ] **步骤 1：写失败的测试**

```dart
testWidgets('new bill remembers last payment method', (tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.pumpAndSettle();

  await tester.tap(find.text('记账'));
  await tester.pumpAndSettle();

  expect(find.text('支付方式'), findsOneWidget);
  expect(find.text('微信'), findsOneWidget);
  expect(find.text('支付宝'), findsOneWidget);
  expect(find.text('银行卡'), findsOneWidget);
});
```

- [ ] **步骤 2：运行测试以验证它失败**

运行：`flutter test test/billing_page_payment_method_test.dart -v`

预期：失败，因为 UI 里还没有支付方式入口，也没有默认值状态。

- [ ] **步骤 3：写最少的实现**

在 `billing_page.dart` 的录入流程里，把支付方式做成一个底部弹层/分段选择控件；新增账单时默认使用最近一次值，编辑账单时回填原值。保存时调用 `BillItem.copyWith(paymentMethod: ...)` 或在新建 `BillItem` 时写入对应值。

- [ ] **步骤 4：运行测试以验证它通过**

运行：`flutter test test/billing_page_payment_method_test.dart -v`

预期：通过。

- [ ] **步骤 5：手工验证编辑回填**

运行：`flutter run`

预期：长按或进入编辑账单时，金额、分类、收支类型和支付方式都能回填并可修改。

### 任务 3：补筛选、统计和列表展示

**文件：**
- 修改：`lib/pages/home_page.dart`
- 修改：`lib/pages/search_page.dart`
- 修改：`lib/pages/chart_page.dart`
- 修改：`lib/pages/bill_statement_page.dart`
- 修改：`lib/pages/bookkeeping_calendar_page.dart`
- 修改：`lib/db/database_helper.dart`
- 测试：`test/payment_method_filter_test.dart`

- [ ] **步骤 1：写失败的测试**

```dart
test('monthly summary can be split by payment method', () async {
  final db = DatabaseHelper.instance;
  await db.database;

  await db.insertBill(
    const BillItem(
      id: 'bill_wechat',
      walletId: BillItem.defaultWalletId,
      type: 'expense',
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
      walletId: BillItem.defaultWalletId,
      type: 'income',
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

  final bills = await db.getBillsByMonth('2026-07');
  expect(bills.length, 2);
  expect(bills.every((bill) => bill.paymentMethod.isNotEmpty), isTrue);
});
```

- [ ] **步骤 2：运行测试以验证它失败**

运行：`flutter test test/payment_method_filter_test.dart -v`

预期：失败，因为数据库查询还没有支付方式维度。

- [ ] **步骤 3：写最少的实现**

在 `DatabaseHelper` 里新增按 `payment_method` 过滤/汇总的查询方法；在 `search_page.dart`、`chart_page.dart` 和 `bill_statement_page.dart` 中补支付方式筛选入口；在 `home_page.dart` 和日历/明细项里显示支付方式标签。

- [ ] **步骤 4：运行测试以验证它通过**

运行：`flutter test test/payment_method_filter_test.dart -v`

预期：通过。

- [ ] **步骤 5：回归验证主流程**

运行：`flutter test test/widget_test.dart -v`

预期：现有主流程不回退，账单列表、首页汇总和搜索页还能正常打开。
