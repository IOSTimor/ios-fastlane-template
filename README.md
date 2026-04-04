# iOS Fastlane Release Template

[English](#english) | [中文](#中文)

## English

Reusable `fastlane/` release template for iOS apps that already manage signing in Xcode.

This repository focuses on release automation only. It does not generate an Xcode project, manage certificates with `match`, or hide Apple-side prerequisites.

### Features

- Parameterized `fastlane/Appfile`
- Reusable `fastlane/Fastfile`
- Project-root `.env.example`
- Safe defaults in `fastlane/.env.default`
- Optional `Gemfile` for pinned fastlane usage
- Metadata and screenshot folder structure with `en-US` and `zh-Hans` sample metadata
- Screenshot locale README guidance and optional metadata template files
- Installer script for existing iOS projects
- Workflows for local IPA build, TestFlight-only upload, review submission, existing app release, new app first release, and metadata-only upload

### Repository Structure

```text
.
├── docs/
│   ├── fastlane_ios_onboarding_guide.md
│   └── skills/ios-fastlane-release/
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

### Supported Workflows

1. `local_build`: export a local IPA only
2. `release_existing`: release an app that already exists in App Store Connect
3. `release_new`: optionally create the app and run the first release flow
4. `testflight_only`: build and upload to TestFlight without review submission
5. `submit_review`: submit an existing build for App Store review
6. `metadata_only`: upload metadata and screenshots without a binary
7. `precheck_assets`: verify local metadata and screenshot readiness before upload
8. `validate_setup`: inspect inferred paths and local template readiness

### Quick Start

#### Option 1: Copy manually

Copy the contents of `ios-newapp-template/` into your iOS project root.

#### Option 2: Install with the helper script

```bash
git clone git@github-personal:IOSTimor/ios-fastlane-template.git
cd ios-fastlane-template/ios-newapp-template
bash scripts/create_project.sh /path/to/your/ios-project
```

#### Option 3: Install with curl

```bash
curl -fsSL https://raw.githubusercontent.com/IOSTimor/ios-fastlane-template/main/scripts/install.sh | bash -s -- /path/to/your/ios-project
```

Then inside your target iOS project:

```bash
cp .env.example .env
fastlane lanes
fastlane ios validate_setup
fastlane ios precheck_assets
fastlane ios local_build scheme:"MyApp" export_method:"development"
```

If your team prefers pinned Ruby dependencies, run `bundle install` and switch to `bundle exec fastlane ...`.

The installer refuses to overwrite an existing `fastlane/` setup unless you pass `--force` or `FORCE_OVERWRITE=true`.

For a forced remote install:

```bash
curl -fsSL https://raw.githubusercontent.com/IOSTimor/ios-fastlane-template/main/scripts/install.sh | bash -s -- /path/to/your/ios-project --force
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

### Common Commands

Local IPA:

```bash
fastlane ios local_build scheme:"MyApp" export_method:"development"
```

Release existing app:

```bash
fastlane ios release_existing \
  scheme:"MyApp" \
  app_identifier:"com.example.app" \
  version:"1.0.0" \
  build_number:"1"
```

Release new app:

```bash
fastlane ios release_new \
  create_app:true \
  scheme:"MyApp" \
  app_identifier:"com.example.app" \
  app_name:"MyApp" \
  sku:"myapp001"
```

TestFlight only:

```bash
fastlane ios testflight_only \
  scheme:"MyApp" \
  app_identifier:"com.example.app" \
  version:"1.0.0" \
  build_number:"1"
```

Submit review:

```bash
fastlane ios submit_review \
  app_identifier:"com.example.app" \
  upload_metadata:true \
  upload_screenshots:true
```

Metadata only:

```bash
fastlane ios metadata_only app_identifier:"com.example.app"
```

Makefile shortcuts:

```bash
make -C ios-newapp-template help
```

Screenshot guidance lives in:

- `ios-newapp-template/fastlane/screenshots/en-US/README.md`
- `ios-newapp-template/fastlane/screenshots/zh-Hans/README.md`

### Assumptions

- Xcode signing already works
- The app project already has an `.xcodeproj` or `.xcworkspace`
- Apple credentials are provided via `.env` or shell env vars
- `match` is intentionally out of scope

### Validation

```bash
fastlane lanes
fastlane ios validate_setup
fastlane ios precheck_assets
xcodebuild -list -project MyApp.xcodeproj
```

### Notes

This repository is ready to publish as a reusable template, but actual release execution still depends on:

- Valid Apple Developer / App Store Connect access
- A working scheme in Xcode
- Correct bundle identifier and team configuration
- Real metadata and screenshot assets when upload flows require them

## 中文

适用于“签名已经由 Xcode 管理”的 iOS 项目的可复用 `fastlane` 发布模板。

这个仓库只解决一件事：发布自动化。它不会生成 Xcode 工程，不会引入 `match`，也不会假装 Apple 侧前置条件已经帮你处理好了。

### 功能

- 参数化的 `fastlane/Appfile`
- 可复用的 `fastlane/Fastfile`
- 项目根目录 `.env.example`
- 可提交的安全默认值 `fastlane/.env.default`
- 可选的 `Gemfile`
- 自带 `en-US` 和 `zh-Hans` 示例内容的 `metadata` / `screenshots` 目录结构
- 截图目录说明和可选 metadata 模板文件
- 安装到现有 iOS 工程的脚本
- 支持本地 IPA、仅上传 TestFlight、提交审核、已有 App 发布、新 App 首发、仅上传元数据

### 仓库结构

```text
.
├── docs/
│   ├── fastlane_ios_onboarding_guide.md
│   └── skills/ios-fastlane-release/
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

### 支持的工作流

1. `local_build`：只导出本地 IPA
2. `release_existing`：发布到已存在的 App Store Connect 应用
3. `release_new`：可选先创建应用，再执行首发
4. `testflight_only`：只构建并上传到 TestFlight
5. `submit_review`：基于已有构建提交审核
6. `metadata_only`：只上传 metadata 和 screenshots
7. `precheck_assets`：预检查本地 metadata 和截图是否准备好
8. `validate_setup`：检查当前模板识别到的路径和本地准备情况

### 快速使用

#### 方式一：手动复制

把 `ios-newapp-template/` 下的内容复制到你的 iOS 工程根目录。

#### 方式二：使用安装脚本

```bash
git clone git@github-personal:IOSTimor/ios-fastlane-template.git
cd ios-fastlane-template/ios-newapp-template
bash scripts/create_project.sh /path/to/your/ios-project
```

#### 方式三：使用 curl 直接安装

```bash
curl -fsSL https://raw.githubusercontent.com/IOSTimor/ios-fastlane-template/main/scripts/install.sh | bash -s -- /path/to/your/ios-project
```

然后进入目标 iOS 工程：

```bash
cp .env.example .env
fastlane lanes
fastlane ios validate_setup
fastlane ios precheck_assets
fastlane ios local_build scheme:"MyApp" export_method:"development"
```

如果你们团队想固定 Ruby 依赖版本，再执行 `bundle install`，后续命令改成 `bundle exec fastlane ...`。

安装脚本默认不会覆盖已经存在的 `fastlane/` 配置；如需覆盖，请显式传 `--force` 或设置 `FORCE_OVERWRITE=true`。

如果要远程强制覆盖安装：

```bash
curl -fsSL https://raw.githubusercontent.com/IOSTimor/ios-fastlane-template/main/scripts/install.sh | bash -s -- /path/to/your/ios-project --force
```

### 最少要填写的配置

在 `.env` 中至少补这些值：

```dotenv
APP_IDENTIFIER=com.example.app
SCHEME=MyApp
PROJECT=MyApp.xcodeproj
TEAM_ID=ABCDE12345
```

如果要上传或发布，还要提供 App Store Connect 认证信息：

```dotenv
APP_STORE_KEY_ID=
APP_STORE_ISSUER_ID=
APP_STORE_KEY_FILE=./fastlane/AuthKey_XXXXXXX.p8
```

### 常用命令

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

新 App 首发：

```bash
fastlane ios release_new \
  create_app:true \
  scheme:"MyApp" \
  app_identifier:"com.example.app" \
  app_name:"MyApp" \
  sku:"myapp001"
```

仅上传 TestFlight：

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

仅上传元数据：

```bash
fastlane ios metadata_only app_identifier:"com.example.app"
```

查看 Makefile 快捷命令：

```bash
make -C ios-newapp-template help
```

截图规范说明在这里：

- `ios-newapp-template/fastlane/screenshots/en-US/README.md`
- `ios-newapp-template/fastlane/screenshots/zh-Hans/README.md`

### 使用前提

- Xcode 签名已经可用
- 工程已经有 `.xcodeproj` 或 `.xcworkspace`
- Apple 凭证通过 `.env` 或 shell 环境变量提供
- 默认不引入 `match`

### 验证命令

```bash
fastlane lanes
fastlane ios validate_setup
fastlane ios precheck_assets
xcodebuild -list -project MyApp.xcodeproj
```

### 说明

这个仓库已经适合公开发布成模板，但真实发布仍然依赖：

- 有效的 Apple Developer / App Store Connect 权限
- Xcode 中可正常构建的 scheme
- 正确的 bundle identifier 与 team 配置
- 上传场景需要的真实 metadata 和截图素材
