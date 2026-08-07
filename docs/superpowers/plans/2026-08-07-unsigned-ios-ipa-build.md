# GitHub Actions 无签名 iOS IPA 构建实施计划

> **对于代理工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 来逐任务实施此计划。步骤使用复选框（`- [ ]`）语法进行跟踪。

**目标：** 使用 Flutter 的 Swift Package Manager 插件集成，并通过独立 GitHub Actions 工作流生成可供外部重签的无签名 IPA。

**架构：** iOS 配置和 CI 与现有 Android 构建完全隔离。macOS Runner 通过 Swift Package Manager 解析插件，无签名编译 `Runner.app`，再按 `Payload/Runner.app` 标准结构封装 IPA，并在上传前验证压缩包内容。

**技术栈：** Flutter stable、Swift Package Manager、GitHub Actions、macOS `ditto`、`unzip`

---

### 任务 1：保持 Swift Package Manager 单一依赖管理

**文件：**
- 删除：`ios/Podfile`

- [x] **步骤 1：运行回归断言并确认失败**

运行：`if (Test-Path -LiteralPath "ios/Podfile") { exit 1 }`

预期：退出码为 1，证明新增的 Podfile 违反 Swift Package Manager 单一集成约束。

- [x] **步骤 2：删除 Podfile**

删除 `ios/Podfile`，不修改 Xcode 工程。原工程没有 Pods 文件引用、`[CP]` 构建阶段或 Pods workspace 引用。

- [x] **步骤 3：重新运行回归断言**

运行：`if (Test-Path -LiteralPath "ios/Podfile") { exit 1 }; "PASS: no CocoaPods Podfile"`

预期：输出 `PASS: no CocoaPods Podfile`，退出码为 0。

### 任务 2：新增无签名 IPA 工作流

**文件：**
- 创建：`.github/workflows/build-ipa.yml`
- 保持不变：`.github/workflows/build-apk.yml`
- 保持不变：`android/`

- [x] **步骤 1：创建独立 iOS 工作流**

写入：

```yaml
name: build-ipa

on:
  workflow_dispatch:
  push:
    tags:
      - 'v*'

permissions:
  contents: write

jobs:
  build:
    runs-on: macos-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      - name: Pub get
        run: flutter pub get

      - name: Build unsigned iOS app
        run: flutter build ios --release --no-codesign

      - name: Package unsigned IPA
        run: |
          set -euo pipefail
          test -d build/ios/iphoneos/Runner.app
          rm -rf build/ios/ipa-unsigned
          mkdir -p build/ios/ipa-unsigned/Payload
          cp -R build/ios/iphoneos/Runner.app build/ios/ipa-unsigned/Payload/Runner.app
          (
            cd build/ios/ipa-unsigned
            ditto -c -k --sequesterRsrc --keepParent Payload ../ledger_flutter-unsigned.ipa
          )
          unzip -t build/ios/ledger_flutter-unsigned.ipa
          unzip -p build/ios/ledger_flutter-unsigned.ipa Payload/Runner.app/Info.plist > /dev/null

      - name: Upload unsigned IPA
        uses: actions/upload-artifact@v4
        with:
          name: ledger_flutter-unsigned-ipa
          path: build/ios/ledger_flutter-unsigned.ipa
          if-no-files-found: error
          retention-days: 7

      - name: Publish unsigned IPA
        if: startsWith(github.ref, 'refs/tags/v')
        uses: softprops/action-gh-release@v2
        with:
          files: build/ios/ledger_flutter-unsigned.ipa
```

- [x] **步骤 2：检查工作流边界和签名要求**

运行：`rg "runs-on: macos-latest|flutter build ios --release --no-codesign|Payload/Runner.app/Info.plist|actions/upload-artifact@v4" .github/workflows/build-ipa.yml`

预期：输出四处匹配，确认 macOS 构建、无签名模式、IPA 结构校验和产物上传。

运行：`rg "secrets\.|certificate|provision" .github/workflows/build-ipa.yml`

预期：无输出且退出码为 1，确认工作流不依赖 Apple 签名材料。

### 任务 3：验证改动范围和配置

**文件：**
- 验证删除：`ios/Podfile`
- 验证：`.github/workflows/build-ipa.yml`
- 验证未修改：`.github/workflows/build-apk.yml`
- 验证未修改：`android/`

- [x] **步骤 1：确认仅新增预期文件**

运行：`git status --short`

预期：`ios/Podfile` 显示为删除，设计和计划文档显示为修改，`.github/workflows/build-ipa.yml` 无改动。

- [x] **步骤 2：确认 Android 构建配置零改动**

运行：`git diff --exit-code -- .github/workflows/build-apk.yml android`

预期：无输出且退出码为 0。

- [x] **步骤 3：检查差异内容**

运行：`git diff --check`

预期：无空白错误。

运行：`git diff -- ios/Podfile .github/workflows/build-ipa.yml`

预期：差异仅包含计划中的 Podfile 和 iOS 工作流内容。

- [x] **步骤 4：记录平台验证限制**

当前工作区为 Windows 且没有可用的 `flutter` 命令，因此不能本地执行 CocoaPods 或 iOS 编译。推送到 GitHub 后手动运行 `build-ipa`，其成功标准是产出 `ledger_flutter-unsigned-ipa` Artifact，下载内容包含 `ledger_flutter-unsigned.ipa`。
