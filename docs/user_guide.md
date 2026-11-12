# iosipa 用户操作手册

适用版本：发布子命令需 v1.4.0+，`docs` 命令需 v1.4.1+。面向第一次使用的 iOS 开发者。

随时执行 `iosipa docs` 在默认浏览器打开本手册；`iosipa docs --url` 只输出网址，适合远程终端或 CI。

`iosipa` 是本项目提供的命令行工具。安装包叫 `ios-fastlane-template`，原来的同名长命令仍然可用。

## 目录

- [1. 先选你要做的事](#1-先选你要做的事)
- [2. 安装、升级和查看版本](#2-安装升级和查看版本)
- [3. 项目路径怎么填](#3-项目路径怎么填)
- [4. 只打本地 IPA：无需 API 认证](#4-只打本地-ipa无需-api-认证)
- [5. 发布前的一次性配置](#5-发布前的一次性配置)
- [6. 上传 TestFlight](#6-上传-testflight)
- [7. 上传描述和截图](#7-上传描述和截图)
- [8. 提交指定构建审核](#8-提交指定构建审核)
- [9. 一次版本发布的完整顺序](#9-一次版本发布的完整顺序)
- [10. 参数速查](#10-参数速查)
- [11. 常见问题](#11-常见问题)

## 1. 先选你要做的事

| 目的 | 命令 | 需要先安装项目内模板吗 | 需要 Apple 上传认证吗 | 会发生什么 |
|---|---|---|---|---|
| 打开操作手册 | `iosipa docs` | 不需要 | 不需要 | 默认浏览器打开本手册 |
| 打本地包 | `iosipa build` | 不需要 | 不需要 API Key；仍需 Xcode 签名 | 构建并导出本地 IPA |
| 上传 TestFlight | `iosipa testflight` | 需要 | 需要 | 构建 App Store 包并上传 |
| 上传描述／截图 | `iosipa metadata` | 需要 | 需要 | 更新线上素材，不上传 IPA |
| 提交审核 | `iosipa submit` | 需要 | 需要 | 选择已有构建提交审核，不重新构建 |
| 给项目安装发布模板 | `iosipa "/项目目录"` | 这是安装动作 | 安装时不需要 | 写入 fastlane 发布文件及缺失的辅助配置 |

只想打本地包：完成第 2～4 节即可。**不必填写 `.env` 或申请 API Key。**

## 2. 安装、升级和查看版本

先安装 macOS、完整 Xcode 和 [Homebrew](https://brew.sh/)，并在 Xcode 中打开过你的 App，确保其能正常构建、签名和归档。

首次安装，在终端执行：

```bash
brew tap IOSTimor/ios-release
brew install ios-fastlane-template
```

Homebrew 会一并安装所需的 Ruby 和 fastlane。工具不会替你创建 Xcode 项目、开发者账号或证书。

已经安装旧版：

```bash
brew update
brew upgrade ios-fastlane-template
```

查看已安装版本及入口：

```bash
brew list --versions ios-fastlane-template
iosipa --help
```

如果保留了多个旧版，查看当前启用的版本：

```bash
readlink "$(brew --prefix)/opt/ios-fastlane-template"
```

例如路径末尾为 `/ios-fastlane-template/1.4.0`，表示当前启用 1.4.0。

## 3. 项目路径怎么填

本手册里的 `/path/to/app` 是占位符，要替换成**你的 App 源码文件夹**，不是本工具的安装目录。

例如你的目录是：

```text
/Users/yourname/Projects/MyApp/
├── MyApp.xcodeproj
├── MyApp.xcworkspace
├── Podfile
└── MyApp/
```

那么输入：

```bash
iosipa build "/Users/yourname/Projects/MyApp"
```

路径包含空格时，保留两侧双引号。也可以把 Finder 中的文件夹拖进终端来填入路径。

先进入 App 文件夹后，可以省略路径：

```bash
cd "/Users/yourname/Projects/MyApp"
iosipa build
```

省略路径始终代表当前终端目录。发布命令需要该目录下有 `fastlane/Fastfile`；如果模板放在 `ios/fastlane`，发布命令应把 `ios/` 作为项目目录。

## 4. 只打本地 IPA：无需 API 认证

```bash
iosipa build "/path/to/app"
```

它会优先选择 workspace，读取真实 iOS App scheme、Team 和签名信息。多个候选时会提示选择。默认使用 Release 构建配置、development 导出方式，不上传 Apple，也不会给项目安装发布模板。

成功后查找：

```text
<项目目录>/build/<Scheme>-<时间戳>.ipa
```

可能还会生成 dSYM 符号文件。Release 是编译配置，development 是导出／签名方式，两者不是同一个概念。

先查看识别结果：

```bash
iosipa build "/path/to/app" --dry-run
```

此操作不 archive、不导出、不安装 fastlane，但会调用 Xcode 读取工程，Xcode 可能解析 Swift 包或使用缓存。它不能证明最终签名打包一定成功。

需要指定入口或导出方式时：

```bash
iosipa build "/path/to/app" --workspace MyApp.xcworkspace --scheme MyApp
iosipa build "/path/to/app" --export-method ad-hoc --output-dir artifacts/ipa
```

`--project` 和 `--workspace` 只能选一个。development／ad-hoc IPA 的安装设备需要符合签名配置，不能当作任意设备都可安装的包。

### CocoaPods、SPM、Flutter 和 React Native

| 工程 | 使用前准备 |
|---|---|
| CocoaPods | 按项目惯例先执行 `pod install` 或 `bundle exec pod install`，生成 workspace；工具不代替执行这些命令 |
| SPM | 在 Xcode 中能正常解析依赖，网络／私有仓库权限可用；包解析交给 Xcode |
| 两者混用 | 先准备依赖，工具优先使用 workspace |
| Flutter／React Native | 先完成框架本身的依赖安装和 iOS 初始化，再使用原生 iOS 工程入口 |

单独的 `Package.swift` 库项目不是一个可导出 IPA 的 App，仍需可构建的 iOS 应用工程与 scheme。

## 5. 发布前的一次性配置

这一步仅用于 `testflight`、`metadata`、`submit`。发布子命令复用项目里的 fastlane lane，不会套用本地 `build` 的自动识别结果。

### 5.1 安装模板

```bash
iosipa "/path/to/app"
```

安装后主要文件如下：

```text
你的 App/
├── Gemfile
├── Makefile
└── fastlane/
    ├── Fastfile
    ├── Appfile
    ├── .env.example
    ├── .env.default
    ├── .env                 # 本地配置，不提交 Git
    ├── metadata/
    └── screenshots/
```

安装器默认拒绝覆盖已有 fastlane 配置。已有自定义流程时，请先检查和备份，不要直接为了通过检查加 `--force`。明确需要更新模板时，`--force` 会替换工作流代码和推断默认值，同时保留已有 `.env` 和素材文件。

### 5.2 核对工程配置

打开 **App 项目的** `fastlane/.env`，保留并校正生成的值。例如 CocoaPods 工程：

```dotenv
SCHEME=MyApp
PROJECT=MyApp.xcodeproj
WORKSPACE=MyApp.xcworkspace
CONFIGURATION=Release
```

没有 workspace 的原生工程可将 `WORKSPACE=` 留空。路径相对项目根目录；scheme 必须真实存在，不能只根据文件夹名猜测。

Xcode → Product → Scheme 可查看实际名称，也可以在项目目录执行：

```bash
xcodebuild -list -workspace MyApp.xcworkspace
```

使用 `.xcodeproj` 时改为 `xcodebuild -list -project MyApp.xcodeproj`。如多个工程，优先手动明确配置；修改版本号时必须有正确的 PROJECT。

### 5.3 配置认证

详细步骤请看 **[认证信息获取与配置](authentication.md)**，包括 Apple 后台点击路径和完整字段说明。

推荐团队 API Key。你至少需要自己的 Bundle ID、Key ID、Issuer ID 和 `.p8` 私钥路径。上传和审核也可以用 Apple ID 登录，但需要处理双重认证／会话，不能完全省去认证。

App Store Connect 中还需提前有对应 App，账号权限、协议及审核所需资料也需准备好。

### 5.4 Ruby 依赖

发布命令遇到 Gemfile 时，会在项目目录检查依赖，缺失时执行 `bundle install`，再用 `bundle exec fastlane`。Gemfile 必须包含 fastlane，Ruby 版本要与项目要求匹配。没有 Gemfile 时使用已安装的 fastlane。

可以在项目目录手动做本地检查：

```bash
bundle install
bundle exec fastlane ios validate_setup
```

该检查主要检查工程路径等本地配置，**不会验证 Apple 凭证、远端权限或签名能否导出**。

## 6. 上传 TestFlight

在已配置的 App 目录执行：

```bash
iosipa testflight
```

这会重新构建 App Store 包并上传，不会直接拿上一次 `build` 导出的 development IPA 上传，也不会上传 App Store 文案或提交 App Store 审核。

指定版本、构建号和测试说明：

```bash
iosipa testflight --version 2.0.0 --build-number 42 --changelog "修复已知问题"
```

版本／构建号应与本次发布对应；再次上传时使用未重复的构建号。指定这两个参数会修改 Xcode 工程的版本设置，记得检查 Git 改动。

默认内部上传可在 Apple 完成构建处理前返回；上传成功不代表测试者已经能安装。需要等待时：

```bash
iosipa testflight --wait
```

外部测试者分发：

```bash
iosipa testflight --external --groups ExternalTesters
```

先在 App Store Connect 准备对应测试组及所需测试信息。外部分发会等待处理，必须有 `--groups`，不能配 `--no-wait`；是否能分发还取决于 Apple 侧的测试审核状态。

## 7. 上传描述和截图

先替换模板文案、填写真实 URL 并准备截图。目录示例：

```text
fastlane/
├── metadata/
│   ├── en-US/
│   │   ├── name.txt
│   │   ├── description.txt
│   │   ├── keywords.txt
│   │   ├── privacy_policy_url.txt
│   │   ├── release_notes.txt
│   │   └── support_url.txt
│   └── zh-Hans/
└── screenshots/
    ├── en-US/
    │   └── 01-home.png
    └── zh-Hans/
        └── 01-home.png
```

只保留你真正维护的语言；不要留下未修改的示例语言文案。语言目录名称使用 Apple 支持的 locale。

上传前做严格的本地素材检查：

```bash
bundle exec fastlane ios precheck_assets strict:true upload_metadata:true upload_screenshots:true
```

当前检查会拒绝缺失／空白必填文件和已知模板占位内容，截图只统计真实图片文件；它不保证图片尺寸、文案长度、URL 可访问性和 Apple 侧所有规则都合格。

上传描述和截图：

```bash
iosipa metadata --screenshots
```

其他常用方式：

```bash
# 只上传文案，不上传截图
iosipa metadata --no-screenshots

# 只上传截图，不上传文案
iosipa metadata --no-metadata --screenshots
```

不带素材选项时，默认上传 metadata，并根据本地图片存在情况决定是否上传截图。这是实际更新线上素材的命令；不会构建、上传 IPA 或提交审核。请在 App Store Connect 中准备要维护的 App 版本。

## 8. 提交指定构建审核

在 App Store Connect 确认上传的构建处理完成，并准备审核资料后执行：

```bash
iosipa submit --version 2.0.0 --build-number 42
```

这里的数字必须对应已上传的构建；`--version` 和 `--build-number` 都是必填，不能只写 `iosipa submit`。

默认沿用线上素材，审核通过后手动发布，不重新构建、不再次上传 IPA。

需要同时上传本地素材时明确选择：

```bash
iosipa submit --version 2.0.0 --build-number 42 --metadata --screenshots
```

要在审核通过后自动发布，再添加 `--automatic-release`。仅执行提交命令不意味着 Apple 会立即通过审核。

## 9. 一次版本发布的完整顺序

首次完成模板和认证配置后，在 App 目录按实际需要逐步执行：

```bash
# 1. 可选：先打一个本地开发测试包
iosipa build

# 2. 构建并上传本次要发布的构建
iosipa testflight --version 2.0.0 --build-number 42 --wait

# 3. 本地素材准备好后，更新 App Store 描述及截图
iosipa metadata --screenshots

# 4. 确认远端资料及该构建就绪，再提交审核
iosipa submit --version 2.0.0 --build-number 42
```

以上命令不要在还未配置账号和素材时整段盲目执行。每一步成功并不代表下一步所有 Apple 前置要求都已满足。

发布子命令可先添加 `--dry-run` 查看执行计划：

```bash
iosipa testflight --dry-run
iosipa metadata --screenshots --dry-run
iosipa submit --version 2.0.0 --build-number 42 --dry-run
```

发布 dry-run 不安装 gems、不登录 Apple、不构建、不上传、不提交，也不会验证凭证是否有效。它与第 4 节会调用 Xcode 的 build dry-run 行为不同。

## 10. 参数速查

所有命令都可使用 `COMMAND --help` 查看当前版本支持的选项，例如 `iosipa submit --help`。

| 命令 | 主要参数 |
|---|---|
| `docs` | `--url`（只输出文档链接）、`--help` |
| `build` | `--project` 或 `--workspace`、`--scheme`、`--configuration`、`--export-method`、`--output-dir`、`--non-interactive`、`--no-provisioning-updates`、`--dry-run` |
| `testflight` | `--app-identifier`、`--scheme`、`--project`、`--workspace`、`--configuration`、`--version`、`--build-number`、`--changelog`、`--groups`、`--testers`、`--external`、`--wait`／`--no-wait`、`--non-interactive`、`--dry-run` |
| `metadata` | `--app-identifier`、`--metadata`／`--no-metadata`、`--screenshots`／`--no-screenshots`、`--non-interactive`、`--dry-run` |
| `submit` | 必填 `--version` 和 `--build-number`；可选 `--app-identifier`、`--metadata`、`--screenshots`、`--automatic-release`、`--non-interactive`、`--dry-run` |

CI 中的 `build --non-interactive` 遇到多个工程／App scheme 会失败，需再明确选择。发布命令的同名参数用于让 fastlane 按 CI 模式执行，认证应提前通过 API Key 等方式配置。

## 11. 常见问题

| 现象 | 怎么处理 |
|---|---|
| `command not found: iosipa` | 确认已安装 v1.3.1+，且终端 PATH 包含 Homebrew bin；发布子命令需要 v1.4.0+ |
| `No Xcode project/workspace found` | 检查路径是否是 App 目录，或用 `--workspace`／`--project` 指向工程 |
| 出现多个 scheme | 选 App 对应项；可显式提供 `--scheme` |
| `Release setup not found` | 在作为命令目标的目录安装一次模板并配置认证 |
| 找不到某个 lane | 该项目是旧版／自定义 Fastfile，需补齐对应 lane；先审核现有脚本再更新模板 |
| 找不到 `.env` 或修改后无效 | 编辑 App 项目中的 `fastlane/.env`；导出的 shell 环境变量优先于 dotenv |
| `API key configuration is incomplete` | Key ID、Issuer ID、私钥路径必须一起填写；切换 Apple ID 时把三项一起清空 |
| `.p8` 文件不存在 | 核对路径相对于项目根目录，或改用绝对路径 |
| `bundle install failed` | 检查当前 Ruby、Gemfile、Gemfile.lock、私有 gem 和网络；不要直接删锁文件或使用 sudo 安装 gems |
| 签名／profile 错误 | 在 Xcode 检查 Team、证书、profile 和设备；上传 API Key 不等于签名证书 |
| `no screenshot files` | 提供 png/jpg/jpeg 图片；README 不计为截图；不上传截图可按命令使用 `--no-screenshots` |
| 文案被判为占位内容 | 替换 YourApp、example.com 等模板文字，删除不维护的语言目录 |
| 上传后 TestFlight 暂时没有构建 | 等待 Apple 处理，检查 App、版本／构建号、处理邮件和账号权限 |
| `--no-wait` 与外部分发冲突 | 外部分发必须等待，去掉 `--no-wait` |
| submit 提示缺少版本／构建号 | 从 App Store Connect 确认要提交的值，并同时提供两个参数 |
| 审核提示资料／协议未完成 | 到 App Store Connect 完成相应资料；工具不代填隐私、合规及协议信息 |

更多背景：[认证指南](authentication.md)、[本地打包说明](one_command_ipa.md)、[发布命令说明](release_commands.md)、[故障排查](troubleshooting.md)。
