# 统一发布子命令

Homebrew v1.4.0 起支持 `iosipa testflight`、`iosipa metadata` 和 `iosipa submit`。省略项目路径时使用当前目录；原命令 `ios-fastlane-template` 同样支持。

## 一次性准备

这些命令复用项目内的 fastlane 发布流程。若项目还没有模板，先执行：

```bash
iosipa /path/to/app
```

配置目标项目的 `fastlane/.env`，例如 API Key 认证：

```dotenv
APP_IDENTIFIER=com.yourcompany.yourapp
APP_STORE_KEY_ID=你的KeyID
APP_STORE_ISSUER_ID=你的IssuerID
APP_STORE_KEY_FILE=./fastlane/AuthKey_你的KeyID.p8
```

上传所需 App Store Connect 应用、权限、协议和 Xcode 签名需已就绪。也可以配置已有 Apple ID 登录方式。密钥只放本地配置或环境变量，不作为命令行参数。

安装器会填充工程路径和 scheme 的初始值，请核对 `fastlane/.env`。已有自定义 fastlane 工作流不会被发布命令自动覆盖；其中需要包含对应的 `testflight_only`、`metadata_only`、`submit_review` lane。

存在 Gemfile 时，命令在项目目录执行 `bundle check`，缺少依赖则执行 `bundle install`，然后用 `bundle exec fastlane`。因此项目应使用匹配的 Ruby 和 Gemfile.lock；不改写已有 Gemfile/Fastfile。没有 Gemfile 时使用 PATH 中的 fastlane。

## TestFlight

```bash
iosipa testflight /path/to/app
```

支持覆盖工程和版本，例如：

```bash
iosipa testflight /path/to/app --scheme MyApp --project MyApp.xcodeproj --version 2.0.0 --build-number 42 --changelog "修复已知问题"
```

版本修改会改动指定 Xcode 工程。首次安装的模板会给出工程默认值；workspace 构建时，PROJECT 仍用于明确版本修改的目标。

外部分发：

```bash
iosipa testflight /path/to/app --external --groups ExternalTesters
```

`--external` 必须提供 `--groups`，并等待构建处理完成；不能与 `--no-wait` 同时使用。普通内部上传默认沿用 lane 的跳过等待行为；可用 `--wait` 等待。该命令只构建和上传 TestFlight，不上传 App Store 素材、不提交 App Store 审核。

## 素材上传

```bash
iosipa metadata /path/to/app
```

默认上传本地 metadata，并按真实图片存在情况决定是否上传截图。明确只上传截图：

```bash
iosipa metadata /path/to/app --no-metadata --screenshots
```

素材位于 `fastlane/metadata/<locale>/` 和 `fastlane/screenshots/<locale>/`。必填文案不能为空，模板占位内容必须先替换。显式要求截图但缺少图片时会失败。此命令不构建、不上传二进制、不提交审核。

## 提交已有构建审核

```bash
iosipa submit /path/to/app --version 2.0.0 --build-number 42
```

版本和构建号必须显式提供，以选择确切的已上传构建。默认沿用线上素材、审核通过后手动发布。需要同时上传本地素材或自动发布时明确指定：

```bash
iosipa submit /path/to/app --version 2.0.0 --build-number 42 --metadata --screenshots --automatic-release
```

此命令不构建，也不再次上传 IPA。App Store Connect 中的该构建必须已就绪并满足审核要求。

## 预览与 CI

```bash
iosipa testflight /path/to/app --dry-run
iosipa metadata /path/to/app --screenshots --dry-run
iosipa submit /path/to/app --version 2.0.0 --build-number 42 --dry-run
```

Dry-run 检查参数和本地入口，打印将执行的命令，不安装依赖、不登录 Apple、不构建、不上传、不提交；不会验证远端权限或凭证有效性。

CI 可添加 `--non-interactive`，并在环境变量或项目的 fastlane/.env 中提供非交互认证。使用 `iosipa COMMAND --help` 查看各子命令参数。
