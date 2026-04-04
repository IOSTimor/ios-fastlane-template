# iOS Fastlane Release Template

[English](#english) | [中文](#中文)

## English

Reusable `fastlane/` release template for iOS apps that already manage signing in Xcode.

[![MIT License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Validate](https://img.shields.io/github/actions/workflow/status/IOSTimor/ios-fastlane-template/validate-template.yml?branch=main&label=validate)](https://github.com/IOSTimor/ios-fastlane-template/actions/workflows/validate-template.yml)
[![Latest Release](https://img.shields.io/github/v/release/IOSTimor/ios-fastlane-template?label=latest%20release)](https://github.com/IOSTimor/ios-fastlane-template/releases)
[![Homebrew](https://img.shields.io/badge/homebrew-formula-orange)](https://raw.githubusercontent.com/IOSTimor/ios-fastlane-template/main/Formula/ios-fastlane-template.rb)

This repository focuses on release automation only. It does not generate an Xcode project, manage certificates with `match`, or hide Apple-side prerequisites.

### What It Solves

- Standardize fastlane setup across existing iOS projects
- Export local IPAs without mixing in upload logic
- Support TestFlight, metadata upload, review submission, and first release flows
- Install the template through `git clone`, `curl | bash`, or Homebrew
- Reduce setup mistakes with asset prechecks and safer installer behavior

### Quick Start

Install with `curl`:

```bash
curl -fsSL https://raw.githubusercontent.com/IOSTimor/ios-fastlane-template/main/scripts/install.sh | bash -s -- /path/to/your/ios-project
```

Or install a local command with Homebrew:

```bash
brew install --formula https://raw.githubusercontent.com/IOSTimor/ios-fastlane-template/main/Formula/ios-fastlane-template.rb
ios-fastlane-template /path/to/your/ios-project
```

If you want the more standard `brew tap ... && brew install ...` flow later, see [docs/homebrew_tap.md](/Users/cx/Desktop/ios-fastlane-template/docs/homebrew_tap.md).

Then inside your target iOS project:

```bash
fastlane lanes
fastlane ios validate_setup
fastlane ios precheck_assets
fastlane ios local_build scheme:"MyApp" export_method:"development"
```

The installer creates `.env` automatically when the target project does not already have one.

### Core Workflows

- `local_build`: export a local IPA only
- `testflight_only`: build and upload to TestFlight without review submission
- `submit_review`: submit an existing build for App Store review
- `release_existing`: run the release flow for an existing App Store Connect app
- `release_new`: optionally create the app and run the first release flow
- `metadata_only`: upload metadata and screenshots without a binary
- `precheck_assets`: verify local metadata and screenshot readiness before upload
- `validate_setup`: inspect inferred paths and local template readiness

### Installation Options

Install with `git clone`:

```bash
git clone git@github-personal:IOSTimor/ios-fastlane-template.git
cd ios-fastlane-template/ios-newapp-template
bash scripts/create_project.sh /path/to/your/ios-project
```

Forced install when the target project already has `fastlane/`:

```bash
curl -fsSL https://raw.githubusercontent.com/IOSTimor/ios-fastlane-template/main/scripts/install.sh | bash -s -- /path/to/your/ios-project --force
```

```bash
ios-fastlane-template /path/to/your/ios-project --force
```

The installer refuses to overwrite an existing `fastlane/` setup unless you explicitly pass `--force` or `FORCE_OVERWRITE=true`.

If detection is ambiguous, set the values explicitly:

```bash
ios-fastlane-template /path/to/your/ios-project \
  --project MyApp.xcodeproj \
  --workspace MyApp.xcworkspace \
  --scheme MyApp \
  --app-name MyApp
```

### Minimum Required Inputs

Fill at least these values in `.env`:

```dotenv
APP_IDENTIFIER=com.example.app
SCHEME=MyApp
PROJECT=MyApp.xcodeproj
TEAM_ID=ABCDE12345
```

For upload and release flows, also provide App Store Connect authentication:

```dotenv
APP_STORE_KEY_ID=
APP_STORE_ISSUER_ID=
APP_STORE_KEY_FILE=./fastlane/AuthKey_XXXXXXX.p8
```

### Commands You Will Actually Use

Local IPA:

```bash
fastlane ios local_build scheme:"MyApp" export_method:"development"
```

Existing app release:

```bash
fastlane ios release_existing \
  scheme:"MyApp" \
  app_identifier:"com.example.app" \
  version:"1.0.0" \
  build_number:"1"
```

TestFlight only:

```bash
fastlane ios testflight_only \
  scheme:"MyApp" \
  app_identifier:"com.example.app" \
  version:"1.0.0" \
  build_number:"1"
```

Review submission:

```bash
fastlane ios submit_review \
  app_identifier:"com.example.app" \
  upload_metadata:true \
  upload_screenshots:true
```

### Use This If

- your iOS app already builds and signs correctly in Xcode
- you want a reusable fastlane setup instead of a custom one-off script
- you want a template focused on release automation, not project generation

### Do Not Use This If

- you need a full Xcode app scaffold
- you want `match` included by default
- you expect this repository to replace Apple-side setup, signing, or App Store Connect permissions

### Project Layout

```text
.
├── docs/
│   ├── fastlane_ios_onboarding_guide.md
│   ├── releases/
│   └── troubleshooting.md
├── Formula/
└── ios-newapp-template/
    ├── .env.example
    ├── Gemfile
    ├── Makefile
    ├── fastlane/
    │   ├── .env.default
    │   ├── Appfile
    │   ├── Fastfile
    │   ├── metadata/
    │   └── screenshots/
    └── scripts/
```

### More Docs

- Onboarding: [docs/fastlane_ios_onboarding_guide.md](/Users/cx/Desktop/ios-fastlane-template/docs/fastlane_ios_onboarding_guide.md)
- FAQ / Troubleshooting: [docs/troubleshooting.md](/Users/cx/Desktop/ios-fastlane-template/docs/troubleshooting.md)
- Release notes draft: [docs/releases/v1.1.0.md](/Users/cx/Desktop/ios-fastlane-template/docs/releases/v1.1.0.md)
- Homebrew tap notes: [docs/homebrew_tap.md](/Users/cx/Desktop/ios-fastlane-template/docs/homebrew_tap.md)
- Contributing: [CONTRIBUTING.md](/Users/cx/Desktop/ios-fastlane-template/CONTRIBUTING.md)
- Security: [SECURITY.md](/Users/cx/Desktop/ios-fastlane-template/SECURITY.md)

## 中文

适用于“签名已经由 Xcode 管理”的 iOS 项目的可复用 `fastlane` 发布模板。

[![MIT License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Validate](https://img.shields.io/github/actions/workflow/status/IOSTimor/ios-fastlane-template/validate-template.yml?branch=main&label=validate)](https://github.com/IOSTimor/ios-fastlane-template/actions/workflows/validate-template.yml)
[![Latest Release](https://img.shields.io/github/v/release/IOSTimor/ios-fastlane-template?label=latest%20release)](https://github.com/IOSTimor/ios-fastlane-template/releases)
[![Homebrew](https://img.shields.io/badge/homebrew-formula-orange)](https://raw.githubusercontent.com/IOSTimor/ios-fastlane-template/main/Formula/ios-fastlane-template.rb)

这个仓库只解决一件事：发布自动化。它不会生成 Xcode 工程，不会引入 `match`，也不会假装 Apple 侧前置条件已经帮你处理好了。

### 它解决什么问题

- 为已有 iOS 工程快速建立统一的 fastlane 发布结构
- 把本地 IPA 导出和上传流程拆开，避免耦合
- 支持 TestFlight、metadata 上传、审核提交和新应用首发
- 支持 `git clone`、`curl | bash`、Homebrew 三种安装方式
- 通过预检查和安全安装策略减少接入错误

### 快速开始

使用 `curl` 一键安装：

```bash
curl -fsSL https://raw.githubusercontent.com/IOSTimor/ios-fastlane-template/main/scripts/install.sh | bash -s -- /path/to/your/ios-project
```

或者先通过 Homebrew 安装命令：

```bash
brew install --formula https://raw.githubusercontent.com/IOSTimor/ios-fastlane-template/main/Formula/ios-fastlane-template.rb
ios-fastlane-template /path/to/your/ios-project
```

如果后续要做标准 `brew tap` 方式，可参考 [docs/homebrew_tap.md](/Users/cx/Desktop/ios-fastlane-template/docs/homebrew_tap.md)。

然后进入目标 iOS 工程：

```bash
fastlane lanes
fastlane ios validate_setup
fastlane ios precheck_assets
fastlane ios local_build scheme:"MyApp" export_method:"development"
```

如果目标工程还没有 `.env`，安装脚本会自动创建。

### 核心工作流

- `local_build`：只导出本地 IPA
- `testflight_only`：只构建并上传到 TestFlight
- `submit_review`：基于已有构建提交审核
- `release_existing`：发布到已存在的 App Store Connect 应用
- `release_new`：可选先创建应用，再执行首发
- `metadata_only`：只上传 metadata 和 screenshots
- `precheck_assets`：预检查 metadata 和截图是否准备好
- `validate_setup`：检查当前模板识别到的路径和本地准备情况

### 安装方式

使用 `git clone`：

```bash
git clone git@github-personal:IOSTimor/ios-fastlane-template.git
cd ios-fastlane-template/ios-newapp-template
bash scripts/create_project.sh /path/to/your/ios-project
```

如果目标工程已经有 `fastlane/`，明确强制覆盖时：

```bash
curl -fsSL https://raw.githubusercontent.com/IOSTimor/ios-fastlane-template/main/scripts/install.sh | bash -s -- /path/to/your/ios-project --force
```

```bash
ios-fastlane-template /path/to/your/ios-project --force
```

安装脚本默认不会覆盖已有 `fastlane/`，只有显式传 `--force` 或设置 `FORCE_OVERWRITE=true` 才会覆盖。

如果自动探测不适合你的工程，也可以手动指定：

```bash
ios-fastlane-template /path/to/your/ios-project \
  --project MyApp.xcodeproj \
  --workspace MyApp.xcworkspace \
  --scheme MyApp \
  --app-name MyApp
```

### 最少要填的配置

在 `.env` 中至少补这些值：

```dotenv
APP_IDENTIFIER=com.example.app
SCHEME=MyApp
PROJECT=MyApp.xcodeproj
TEAM_ID=ABCDE12345
```

如果要上传或发布，还要补 App Store Connect 认证信息：

```dotenv
APP_STORE_KEY_ID=
APP_STORE_ISSUER_ID=
APP_STORE_KEY_FILE=./fastlane/AuthKey_XXXXXXX.p8
```

### 最常用命令

本地 IPA：

```bash
fastlane ios local_build scheme:"MyApp" export_method:"development"
```

已有 App 发布：

```bash
fastlane ios release_existing \
  scheme:"MyApp" \
  app_identifier:"com.example.app" \
  version:"1.0.0" \
  build_number:"1"
```

只传 TestFlight：

```bash
fastlane ios testflight_only \
  scheme:"MyApp" \
  app_identifier:"com.example.app" \
  version:"1.0.0" \
  build_number:"1"
```

提交审核：

```bash
fastlane ios submit_review \
  app_identifier:"com.example.app" \
  upload_metadata:true \
  upload_screenshots:true
```

### 适合使用的情况

- 你的 iOS 工程已经能在 Xcode 正常签名和构建
- 你希望有一套可复用的 fastlane 模板，而不是一次性脚本
- 你只想解决发布自动化，不想把仓库变成工程脚手架

### 不适合使用的情况

- 你想要完整的 Xcode 工程脚手架
- 你默认就需要 `match`
- 你希望这个仓库代替 Apple 侧配置、签名配置或权限配置

### 项目结构

```text
.
├── docs/
│   ├── fastlane_ios_onboarding_guide.md
│   ├── releases/
│   └── troubleshooting.md
├── Formula/
└── ios-newapp-template/
    ├── .env.example
    ├── Gemfile
    ├── Makefile
    ├── fastlane/
    │   ├── .env.default
    │   ├── Appfile
    │   ├── Fastfile
    │   ├── metadata/
    │   └── screenshots/
    └── scripts/
```

### 更多文档

- 上手指南: [docs/fastlane_ios_onboarding_guide.md](/Users/cx/Desktop/ios-fastlane-template/docs/fastlane_ios_onboarding_guide.md)
- FAQ / 故障排查: [docs/troubleshooting.md](/Users/cx/Desktop/ios-fastlane-template/docs/troubleshooting.md)
- Release 草稿: [docs/releases/v1.1.0.md](/Users/cx/Desktop/ios-fastlane-template/docs/releases/v1.1.0.md)
- Homebrew Tap 说明: [docs/homebrew_tap.md](/Users/cx/Desktop/ios-fastlane-template/docs/homebrew_tap.md)
- 参与贡献: [CONTRIBUTING.md](/Users/cx/Desktop/ios-fastlane-template/CONTRIBUTING.md)
- 安全策略: [SECURITY.md](/Users/cx/Desktop/ios-fastlane-template/SECURITY.md)
