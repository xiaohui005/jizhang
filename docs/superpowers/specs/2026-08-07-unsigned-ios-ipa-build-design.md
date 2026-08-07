# GitHub Actions 无签名 iOS IPA 构建设计

## 目标

通过 GitHub Actions 生成可供外部签名工具重签的 Release IPA，并沿用 Flutter 自动配置的 Swift Package Manager 集成。

生成的 IPA 不包含有效的 Apple 分发签名，不能直接安装到普通 iPhone，也不能直接上传 App Store。用户下载后自行完成签名和分发。

## 范围

- 保持项目不包含 `ios/Podfile`，避免与 Flutter 的 Swift Package Manager 插件集成冲突。
- 新增独立的 `.github/workflows/build-ipa.yml`。
- 支持从 GitHub Actions 页面手动触发。
- 支持推送 `v*` 标签时自动构建，并把 IPA 附加到对应 GitHub Release。
- 保留现有 Android APK 构建流程，不修改应用业务代码。

## 构建流程

工作流使用 GitHub 托管的 `macos-latest` Runner：

1. 检出代码并安装稳定版 Flutter。
2. 执行 `flutter pub get` 获取 Dart 和 Flutter 依赖。
3. 执行 `flutter build ios --release --no-codesign`，生成无签名的 `Runner.app`。
4. 创建标准 IPA 目录结构 `Payload/Runner.app`。
5. 使用 macOS 自带工具封装为 `ledger_flutter-unsigned.ipa`。
6. 检查 IPA 中存在 `Payload/Runner.app/Info.plist`，构建缺失或封装异常时立即失败。
7. 将 IPA 上传为 GitHub Actions Artifact，保留 7 天。
8. 当触发来源为 `v*` 标签时，将同一 IPA 附加到 GitHub Release。

## 配置与安全

工作流不导入 Apple 证书、Provisioning Profile 或私钥，不需要新增 GitHub Secrets。产物名称明确包含 `unsigned`，避免被误认为可直接安装的已签名包。

当前 Flutter 工具已确认所有 iOS 插件都可通过 Swift Package Manager 集成。工程不引入 CocoaPods，避免同时存在两套依赖管理机制以及 `Podfile.lock` sandbox 校验错误。

## 错误处理

- Flutter 依赖解析、Swift Package Manager 集成或 iOS 编译失败时，工作流停止且不上传产物。
- `Runner.app` 不存在时，封装步骤停止并报告错误。
- IPA 结构校验失败时，工作流停止，防止发布无效压缩包。
- GitHub Release 上传只在标签构建中执行；手动构建只产生 Artifact。

## 验证标准

- 仓库中不存在 `ios/Podfile`，Xcode 工程不包含 CocoaPods 构建阶段。
- GitHub Actions 工作流 YAML 语法有效。
- 工作流不引用任何 Apple 签名 Secret。
- IPA 内部顶层为 `Payload`，并包含 `Payload/Runner.app/Info.plist`。
- 手动触发后可从 Actions 页面下载 `ledger_flutter-unsigned.ipa`。
- `v*` 标签触发后，IPA 同时出现在对应 GitHub Release 中。

## 非目标

- 不在 GitHub Actions 中完成 Apple 签名。
- 不自动上传 TestFlight 或 App Store Connect。
- 不保证任何第三方签名服务的兼容性；产物仅遵循标准 IPA 目录结构。
- 不修改 Bundle ID、版本号、应用图标或应用功能。
