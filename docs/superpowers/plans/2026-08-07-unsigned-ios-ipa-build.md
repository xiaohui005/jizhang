# GitHub Actions 无签名 iOS IPA 构建实施计划

> **对于代理工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 来逐任务实施此计划。步骤使用复选框（`- [ ]`）语法进行跟踪。

**目标：** 补齐 Flutter iOS CocoaPods 配置，并通过独立 GitHub Actions 工作流生成可供外部重签的无签名 IPA。

**架构：** iOS 配置和 CI 与现有 Android 构建完全隔离。macOS Runner 无签名编译 `Runner.app`，再按 `Payload/Runner.app` 标准结构封装 IPA，并在上传前验证压缩包内容。

**技术栈：** Flutter stable、CocoaPods、GitHub Actions、macOS `ditto`、`unzip`

---

### 任务 1：补齐 CocoaPods 配置

**文件：**
- 创建：`ios/Podfile`

- [x] **步骤 1：确认 Podfile 当前缺失**

运行：`git ls-files --error-unmatch ios/Podfile`

预期：命令失败，并提示 `ios/Podfile` 不在版本库中。

- [x] **步骤 2：创建标准 Flutter Podfile**

写入：

```ruby
platform :ios, '13.0'

ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. Run flutter pub get first."
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}."
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  target 'RunnerTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
  end
end
```

- [x] **步骤 3：静态检查 Podfile 的关键约束**

运行：`rg "platform :ios, '13.0'|flutter_install_all_ios_pods|flutter_additional_ios_build_settings" ios/Podfile`

预期：输出三处匹配，分别确认最低系统版本、插件安装和 Pod 构建设置。

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
- 验证：`ios/Podfile`
- 验证：`.github/workflows/build-ipa.yml`
- 验证未修改：`.github/workflows/build-apk.yml`
- 验证未修改：`android/`

- [x] **步骤 1：确认仅新增预期文件**

运行：`git status --short`

预期：除已确认的设计和计划文档外，只新增 `ios/Podfile` 与 `.github/workflows/build-ipa.yml`。

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
