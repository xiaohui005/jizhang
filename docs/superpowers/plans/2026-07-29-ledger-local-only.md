# 罐头记账纯本地模式实施计划

> **对于代理工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 来逐任务实施此计划。步骤使用复选框（`- [ ]`）语法进行跟踪。

**目标：** 去掉短信自动记账、后台同步和联网发送能力，保留本地手动记账、统计、计数、预算和分类等基础功能。

**架构：** 保留 `sqflite` 作为唯一数据持久层，清理短信接收与自动同步链路，确保应用启动后直接进入本地记账主页。所有记账、统计、预算、分类和设置仍然读取同一份本地数据库，不新增替代同步机制。

**技术栈：** Flutter, Riverpod, Kotlin Android, sqflite, MethodChannel, Android Manifest

---

### 任务 1：移除短信自动记账入口

**文件：**
- 修改：`lib/pages/mine_page.dart`
- 修改：`lib/providers/settings_provider.dart`
- 修改：`lib/pages/main_shell.dart`
- 修改：`lib/services/sms_auto_bookkeeping_service.dart`
- 修改：`test/widget_test.dart`

- [ ] **步骤 1：写失败的测试**

```dart
testWidgets('mine page does not show sms auto bookkeeping switch', (tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.pumpAndSettle();
  expect(find.text('短信自动记账'), findsNothing);
});
```

- [ ] **步骤 2：运行测试以验证它失败**

运行：`flutter test test/widget_test.dart -r expanded`
预期：失败，因为当前 `我的` 页仍然渲染短信自动记账开关。

- [ ] **步骤 3：写最少的实现**

```dart
// 从 mine_page.dart 删除短信自动记账设置卡片及其依赖
// 从 settings_provider.dart 删除 smsAutoBookkeepingEnabledProvider
// 从 main_shell.dart 删除启动/前后台短信同步监听
// 从 sms_auto_bookkeeping_service.dart 删除或废弃短信同步实现
```

- [ ] **步骤 4：运行测试以验证它通过**

运行：`flutter test test/widget_test.dart -r expanded`
预期：通过，页面不再出现短信开关。

- [ ] **步骤 5：运行验证并确认结果**

运行：`flutter test`
预期：全量测试通过，且 `main_shell` 仍可正常展示首页、底栏和计数相关页面。

### 任务 2：移除短信接收与权限链路

**文件：**
- 修改：`android/app/src/main/AndroidManifest.xml`
- 修改：`android/app/src/main/kotlin/com/guantou/ledger_flutter/MainActivity.kt`
- 修改：`android/app/src/main/kotlin/com/guantou/ledger_flutter/SmsReceiver.kt`
- 修改：`android/app/src/main/kotlin/com/guantou/ledger_flutter/SmsPlugin.kt`
- 修改：`lib/services/sms_auto_bookkeeping_service.dart`

- [ ] **步骤 1：写失败的测试**

```bash
python -c "from pathlib import Path; manifest = Path('android/app/src/main/AndroidManifest.xml').read_text(encoding='utf-8'); assert 'READ_SMS' not in manifest; assert 'RECEIVE_SMS' not in manifest; assert 'SmsReceiver' not in manifest"
```

- [ ] **步骤 2：运行测试以验证它失败**

运行：`python -c "from pathlib import Path; manifest = Path('android/app/src/main/AndroidManifest.xml').read_text(encoding='utf-8'); assert 'READ_SMS' not in manifest"`
预期：失败，因为当前 manifest 仍声明短信权限和接收器。

- [ ] **步骤 3：写最少的实现**

```kotlin
// 从 AndroidManifest.xml 删除短信权限与 SmsReceiver 声明
// 从 MainActivity 删除短信 MethodChannel 分支
// 删除 SmsReceiver.kt 和 SmsPlugin.kt，或改为不再被引用的空实现并确保不注册
// 删除 SmsAutoBookkeepingService 里的 MethodChannel 调用链
```

- [ ] **步骤 4：运行测试以验证它通过**

运行：`python -c "from pathlib import Path; manifest = Path('android/app/src/main/AndroidManifest.xml').read_text(encoding='utf-8'); assert 'READ_SMS' not in manifest and 'RECEIVE_SMS' not in manifest and 'SmsReceiver' not in manifest"`
预期：通过。

- [ ] **步骤 5：运行验证并确认结果**

运行：`flutter test`
预期：通过；再额外检查 `android/app/src/main/kotlin` 不再有短信接收或权限请求代码。

### 任务 3：保留统计、计数和本地数据库路径

**文件：**
- 保留：`lib/db/database_helper.dart`
- 保留：`lib/providers/bill_provider.dart`
- 保留：`lib/providers/chart_provider.dart`
- 保留：`lib/providers/budget_provider.dart`
- 保留：`lib/providers/category_provider.dart`
- 保留：`lib/pages/home_page.dart`
- 保留：`lib/pages/chart_page.dart`
- 保留：`lib/pages/discover_page.dart`
- 修改：`test/widget_test.dart`

- [ ] **步骤 1：写失败的测试**

```dart
import 'package:ledger_flutter/widgets/bottom_nav_bar.dart';
import 'package:ledger_flutter/main.dart';

testWidgets('app still boots into the main shell', (tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.pumpAndSettle();
  expect(find.byType(BottomNavBar), findsOneWidget);
  expect(find.text('短信自动记账'), findsNothing);
});
```

- [ ] **步骤 2：运行测试以验证它失败**

运行：`flutter test test/widget_test.dart -r expanded`
预期：失败，当前测试还停留在旧的 Counter smoke test，且 `BottomNavBar` 未被验证。

- [ ] **步骤 3：写最少的实现**

```dart
// 用 App 启动冒烟测试替换旧 Counter 测试
// 不改 DatabaseHelper、bill_provider、chart_provider、budget_provider 的数据流
```

- [ ] **步骤 4：运行测试以验证它通过**

运行：`flutter test test/widget_test.dart -r expanded`
预期：通过，说明基础导航和首页仍能启动。

- [ ] **步骤 5：运行验证并确认结果**

运行：`flutter test`
预期：通过，统计、计数、预算和分类相关页面仍可用。

### 任务 4：做一次静态回归检查

**文件：**
- 修改：`README.md`（如需要，删除短信自动记账说明）
- 修改：`docs/superpowers/specs/2026-07-29-ledger-local-only-design.md`（如实现细节与规格有轻微偏差时同步收敛）

- [ ] **步骤 1：写失败的测试**

```bash
rg -n "smsAutoBookkeepingEnabledProvider|SmsReceiver|SmsPlugin|READ_SMS|RECEIVE_SMS|短信自动记账" lib android README.md
```

- [ ] **步骤 2：运行测试以验证它失败**

运行：`rg -n "smsAutoBookkeepingEnabledProvider|SmsReceiver|SmsPlugin|READ_SMS|RECEIVE_SMS|短信自动记账" lib android README.md`
预期：先能搜到旧引用，说明清理还不完整。

- [ ] **步骤 3：写最少的实现**

```text
删除剩余引用，使上面的搜索没有输出。
```

- [ ] **步骤 4：运行测试以验证它通过**

运行：`rg -n "smsAutoBookkeepingEnabledProvider|SmsReceiver|SmsPlugin|READ_SMS|RECEIVE_SMS|短信自动记账" lib android README.md`
预期：无输出。

- [ ] **步骤 5：运行验证并确认结果**

运行：`flutter test`
预期：通过，且本地统计、计数登记、预算、分类、搜索、图表页面未被误伤。
