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

### One-command local IPA (source checkout)

From this repository's root, build an existing iOS app without installing the template or filling `.env`:

```bash
bash scripts/install.sh build /path/to/your/ios-project
```

The helper prefers an app workspace, reads real schemes and signing settings from Xcode, and exports to the app's `build/` directory. It prompts if several apps are possible; use `--non-interactive --scheme MyApp` in CI. If fastlane is missing and Homebrew is available, it installs fastlane. Your app's existing Fastfile and environment files are preserved. Xcode signing and project dependencies must already be configured.

Preview discovery with `--dry-run`. See [the complete one-command guide](docs/one_command_ipa.md). The published Homebrew `v1.2.1` command does not include this new subcommand yet.

### Quick Start

Install with `curl`:

```bash
curl -fsSL https://raw.githubusercontent.com/IOSTimor/ios-fastlane-template/main/scripts/install.sh | bash -s -- /path/to/your/ios-project
```

Or install a local command with Homebrew:

```bash
brew tap IOSTimor/ios-release
brew install ios-fastlane-template
ios-fastlane-template /path/to/your/ios-project
```

This assumes the tap repository is published as `IOSTimor/homebrew-ios-release`. See [docs/homebrew_tap.md](docs/homebrew_tap.md).

Then inside your target iOS project:

```bash
bundle install
bundle exec fastlane lanes
bundle exec fastlane ios validate_setup
bundle exec fastlane ios precheck_assets
bundle exec fastlane ios local_build scheme:"MyApp" export_method:"development"
```

The installer creates `fastlane/.env` when missing. An existing root `.env` is imported once; edit `fastlane/.env` afterward. Existing environment files and assets are preserved, including with `--force`.

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
git clone https://github.com/IOSTimor/ios-fastlane-template.git
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

Fill at least these values in `fastlane/.env`:

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

`release_existing` and `release_new` upload the binary by default. Metadata and screenshots require explicit `upload_metadata:true` / `upload_screenshots:true`; replace all starter copy before opting in. For existing-build review, use `build_number` and `version` to select a specific build.

### Commands You Will Actually Use

Local IPA:

```bash
bundle exec fastlane ios local_build scheme:"MyApp" export_method:"development"
```

Existing app release:

```bash
bundle exec fastlane ios release_existing \
  scheme:"MyApp" \
  app_identifier:"com.example.app" \
  version:"1.0.0" \
  build_number:"1"
```

TestFlight only:

```bash
bundle exec fastlane ios testflight_only \
  scheme:"MyApp" \
  app_identifier:"com.example.app" \
  version:"1.0.0" \
  build_number:"1"
```

Review submission:

```bash
bundle exec fastlane ios submit_review \
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
    ├── Gemfile
    ├── Makefile
    ├── fastlane/
    │   ├── .env.example
    │   ├── .env.default
    │   ├── Appfile
    │   ├── Fastfile
    │   ├── metadata/
    │   └── screenshots/
    └── scripts/
```

### More Docs

- Onboarding: [docs/fastlane_ios_onboarding_guide.md](docs/fastlane_ios_onboarding_guide.md)
- FAQ / Troubleshooting: [docs/troubleshooting.md](docs/troubleshooting.md)
- Release notes draft: [docs/releases/v1.2.1.md](docs/releases/v1.2.1.md)
- Homebrew tap notes: [docs/homebrew_tap.md](docs/homebrew_tap.md)
- Tap repo templates: [templates/homebrew-tap/README.md](templates/homebrew-tap/README.md)
- Tap repo scaffold script: [scripts/prepare_homebrew_tap_repo.sh](scripts/prepare_homebrew_tap_repo.sh)
- Contributing: [CONTRIBUTING.md](CONTRIBUTING.md)
- Security: [SECURITY.md](SECURITY.md)

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

### 一条命令打本地 IPA（源码版）

在本仓库根目录运行，无需先接入模板或填写 `.env`：

```bash
bash scripts/install.sh build /你的/iOS项目目录
```

会自动优先选择 workspace，读取 Xcode 的真实 scheme、Team 和签名配置，输出到目标项目的 `build/`。存在多个 App 时提示选择；CI 可使用 `--non-interactive --scheme MyApp`。若缺少 fastlane 且已安装 Homebrew，会自动安装 fastlane。已有 Fastfile 和环境配置不会改写，Xcode 签名及项目依赖仍需正常。

添加 `--dry-run` 可先查看识别结果。详见[一键打包说明](docs/one_command_ipa.md)。已发布的 Homebrew `v1.2.1` 命令暂不包含此新子命令。

### 快速开始

使用 `curl` 一键安装：

```bash
curl -fsSL https://raw.githubusercontent.com/IOSTimor/ios-fastlane-template/main/scripts/install.sh | bash -s -- /path/to/your/ios-project
```

或者先通过 Homebrew 安装命令：

```bash
brew tap IOSTimor/ios-release
brew install ios-fastlane-template
ios-fastlane-template /path/to/your/ios-project
```

这要求 tap 仓库以 `IOSTimor/homebrew-ios-release` 发布，详情见 [docs/homebrew_tap.md](docs/homebrew_tap.md)。

然后进入目标 iOS 工程：

```bash
bundle install
bundle exec fastlane lanes
bundle exec fastlane ios validate_setup
bundle exec fastlane ios precheck_assets
bundle exec fastlane ios local_build scheme:"MyApp" export_method:"development"
```

安装脚本会在缺失时创建 `fastlane/.env`。已有根目录 `.env` 会在首次迁移时导入，之后请编辑 `fastlane/.env`。即使使用 `--force`，已有环境文件和素材也会保留。

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
git clone https://github.com/IOSTimor/ios-fastlane-template.git
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

在 `fastlane/.env` 中至少补这些值：

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

`release_existing` 和 `release_new` 默认只上传二进制。上传素材需显式设置 `upload_metadata:true` / `upload_screenshots:true`，并先替换示例内容。提交已有构建时，可通过 `build_number` 和 `version` 指定构建。

### 最常用命令

本地 IPA：

```bash
bundle exec fastlane ios local_build scheme:"MyApp" export_method:"development"
```

已有 App 发布：

```bash
bundle exec fastlane ios release_existing \
  scheme:"MyApp" \
  app_identifier:"com.example.app" \
  version:"1.0.0" \
  build_number:"1"
```

只传 TestFlight：

```bash
bundle exec fastlane ios testflight_only \
  scheme:"MyApp" \
  app_identifier:"com.example.app" \
  version:"1.0.0" \
  build_number:"1"
```

提交审核：

```bash
bundle exec fastlane ios submit_review \
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
    ├── Gemfile
    ├── Makefile
    ├── fastlane/
    │   ├── .env.example
    │   ├── .env.default
    │   ├── Appfile
    │   ├── Fastfile
    │   ├── metadata/
    │   └── screenshots/
    └── scripts/
```

### 更多文档

- 上手指南: [docs/fastlane_ios_onboarding_guide.md](docs/fastlane_ios_onboarding_guide.md)
- FAQ / 故障排查: [docs/troubleshooting.md](docs/troubleshooting.md)
- Release 草稿: [docs/releases/v1.2.1.md](docs/releases/v1.2.1.md)
- Homebrew Tap 说明: [docs/homebrew_tap.md](docs/homebrew_tap.md)
- Tap 仓库模板: [templates/homebrew-tap/README.md](templates/homebrew-tap/README.md)
- Tap 仓库脚手架脚本: [scripts/prepare_homebrew_tap_repo.sh](scripts/prepare_homebrew_tap_repo.sh)
- 参与贡献: [CONTRIBUTING.md](CONTRIBUTING.md)
- 安全策略: [SECURITY.md](SECURITY.md)

## Development checks

```bash
python3 -m unittest discover -s tests -v
```

The tests use temporary projects and action doubles. If fastlane is installed, they also check actual dotenv loading. No test builds an app or uploads to Apple. CI runs the suite on macOS and Linux.
