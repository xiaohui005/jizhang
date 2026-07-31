# 支付方式管理与统计切换实施计划

> **对于代理工作者：** 必需子技能：使用 `superpowers:subagent-driven-development`（推荐）或 `superpowers:executing-plans` 来逐任务实施此计划。步骤使用复选框（`- [ ]`）语法进行跟踪。

**目标：** 把支付方式升级为全局可管理列表，支持新增、改名、拖动排序和删除，同时把图表页与账单汇总页顶部的支付方式筛选改成横向滚动按钮。

**架构：** 以一个全局支付方式仓库为单一来源，账单只保存支付方式 id，展示时统一映射到名称、图标和颜色。管理页负责维护列表本身，记账页负责选择当前支付方式，统计页负责读取同一份列表并用按钮切换过滤。默认三项保留为不可删除的内置项，删除自定义项时把已引用账单回退到微信，保证历史数据可继续读取。

**技术栈：** Flutter、Riverpod、sqflite、现有账单/统计页面、现有支付方式 badge 与标签组件。

---

### 任务 1：把支付方式改成可管理的全局数据源

**文件：**
- 修改：`lib/models/payment_method.dart`
- 创建：`lib/models/payment_method_item.dart`
- 修改：`lib/db/database_helper.dart`
- 修改：`lib/widgets/payment_method_widgets.dart`
- 测试：`test/payment_method_management_model_test.dart`
- 测试：`test/payment_method_migration_test.dart`

- [ ] **步骤 1：写失败的测试**

```dart
test('default payment methods exist and are ordered', () async {
  final db = DatabaseHelper.instance;
  await db.database;
  final items = await db.getPaymentMethods();
  expect(items.take(3).map((e) => e.name).toList(), ['微信', '支付宝', '银行卡']);
});
```

- [ ] **步骤 2：运行测试以验证它失败**

运行：`flutter test test/payment_method_management_model_test.dart -v`

预期：失败，因为当前还没有全局支付方式表与读取接口。

- [ ] **步骤 3：写最少的实现**

```dart
class PaymentMethodItem {
  final String id;
  final String name;
  final int sortOrder;
  final bool isDefault;
  final String createdAt;
  final String updatedAt;
}
```

在 `DatabaseHelper` 中新增 `payment_methods` 表、默认三项播种、读取/新增/改名/排序/删除接口；同步把账单里的支付方式从字符串常量使用模式迁移到 `payment_method_id` 或兼容 id 字段，并保留向后兼容映射。更新 `payment_method_widgets.dart` 里的标签、图标、颜色、筛选值来源，让它们全部来自数据库读取的全局列表。

- [ ] **步骤 4：运行测试以验证它通过**

运行：`flutter test test/payment_method_management_model_test.dart -v`

预期：通过。

- [ ] **步骤 5：运行迁移回归**

运行：`flutter test test/payment_method_migration_test.dart -v`

预期：通过，旧账仍回填到微信。

### 任务 2：新增支付方式管理页和入口

**文件：**
- 修改：`lib/pages/mine_page.dart`
- 创建：`lib/pages/payment_method_manager_page.dart`
- 创建：`lib/widgets/payment_method_edit_sheet.dart`
- 创建：`lib/widgets/payment_method_reorder_tile.dart`
- 修改：`lib/widgets/payment_method_widgets.dart`
- 测试：`test/payment_method_manager_page_test.dart`

- [ ] **步骤 1：写失败的测试**

```dart
testWidgets('payment method manager shows default methods', (tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.pumpAndSettle();
  // 进入“我的”页后点击“支付方式管理”，断言默认三项可见。
});
```

- [ ] **步骤 2：运行测试以验证它失败**

运行：`flutter test test/payment_method_manager_page_test.dart -v`

预期：失败，因为还没有入口和管理页。

- [ ] **步骤 3：写最少的实现**

在 `mine_page.dart` 的数据区新增“支付方式管理”入口。管理页使用现有的列表风格展示所有支付方式，提供新增和改名底部弹层，默认三项显示固定标记并禁删，自定义项可拖动排序和删除。删除动作若引用计数大于 0，先批量把相关账单回退到微信，再删方式本身。

- [ ] **步骤 4：运行测试以验证它通过**

运行：`flutter test test/payment_method_manager_page_test.dart -v`

预期：通过。

- [ ] **步骤 5：手工验证修改和删除**

运行：`flutter run`

预期：默认三项可重命名不可删除；自定义项可新增、拖动、删除；删除已使用方式时相关账单回退到微信。

### 任务 3：把记账页和统计页接到全局支付方式列表

**文件：**
- 修改：`lib/pages/billing_page.dart`
- 修改：`lib/providers/payment_method_provider.dart`
- 修改：`lib/widgets/calculator_keyboard.dart`
- 修改：`lib/pages/chart_page.dart`
- 修改：`lib/pages/bill_statement_page.dart`
- 修改：`lib/pages/search_page.dart`
- 修改：`lib/pages/home_page.dart`
- 修改：`lib/pages/bookkeeping_calendar_page.dart`
- 修改：`lib/widgets/payment_method_widgets.dart`
- 测试：`test/calculator_keyboard_payment_method_test.dart`
- 测试：`test/payment_method_filter_test.dart`

- [ ] **步骤 1：写失败的测试**

```dart
testWidgets('keyboard uses the selected method from the global list', (tester) async {
  // 断言记账键盘的支付方式按钮来自 PaymentMethodItem 列表并能回填上次选择。
});
```

- [ ] **步骤 2：运行测试以验证它失败**

运行：`flutter test test/calculator_keyboard_payment_method_test.dart -v`

预期：失败，因为键盘仍然只依赖静态三项。

- [ ] **步骤 3：写最少的实现**

让 `payment_method_provider.dart` 读取全局支付方式列表，记账页用它来提供默认选中项，键盘里的按钮改为动态渲染。图表页和账单汇总页顶部把当前支付方式下拉替换为横向滚动的胶囊按钮，按钮来源于同一个全局列表，并保留“全部”选项。搜索页继续沿用支付方式筛选，但从全局列表生成选项，重置状态包含支付方式。

- [ ] **步骤 4：运行测试以验证它通过**

运行：`flutter test test/calculator_keyboard_payment_method_test.dart -v`

预期：通过。

- [ ] **步骤 5：运行筛选回归**

运行：`flutter test test/payment_method_filter_test.dart -v`

预期：通过，图表/账单汇总的过滤结果与按钮选择一致。
