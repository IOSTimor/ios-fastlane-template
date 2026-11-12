# 一条命令导出本地 IPA

适用于已经能在 Xcode 中正常构建和签名的 iOS App。无需先安装发布模板、填写 `.env` 或创建 Gemfile。

从 v1.3.1 起推荐使用短命令 `iosipa`；原命令 `ios-fastlane-template` 继续兼容，安装包名称不变。

## Homebrew 安装和使用

```bash
brew tap IOSTimor/ios-release
brew install ios-fastlane-template
iosipa build /path/to/your/ios-project
```

已安装旧版时执行 `brew update && brew upgrade ios-fastlane-template`。从 v1.3.0 起，Homebrew 会一并安装 Ruby、fastlane 和本地打包脚本，打包时无需再次下载仓库。添加 `--dry-run` 可先检查识别结果。

## 源码方式使用

在本仓库根目录执行，替换最后的路径：

```bash
bash scripts/install.sh build /path/to/your/ios-project
```

也可以在 App 目录中，使用本仓库的绝对路径；省略项目目录时默认使用当前目录：

```bash
bash /path/to/ios-fastlane-template/scripts/install.sh build
```

IPA 输出位置为：

```text
<目标项目>/build/<Scheme>-<时间戳>.ipa
```

源码命令与 Homebrew 的 `iosipa build` 使用同一个打包实现；参数相同。

## 自动识别内容

- 搜索当前项目及其浅层子目录，覆盖常见 `ios/` 结构。
- 优先使用 `.xcworkspace`；跳过 Pods、Carthage、node_modules、构建缓存和 `.xcodeproj` 内部的 workspace。
- 用 `xcodebuild -list -json` 取得真实 scheme，读取构建设置筛选 iOS application，排除框架和测试 target。
- 沿用 Xcode 的 Team、Bundle ID、签名方式及已有 provisioning profile，包括 scheme 中的扩展 target。
- 默认使用 Release 配置，导出 development IPA。
- 缺少 fastlane 时，如果已有 Homebrew，会自动执行 `brew install fastlane`。不改写 App 的 Gemfile、Fastfile 或 `.env`。

有多个工程或可打包的 App scheme 时，终端会提示选择，避免猜测错误的 App。非交互环境可传入明确选项。

## 常用选项

只检查识别结果，不安装工具、不 archive、不导出：

```bash
bash scripts/install.sh build /path/to/app --dry-run
```

为 CI 指定 scheme，遇到其他歧义直接失败：

```bash
bash scripts/install.sh build /path/to/app --non-interactive --scheme MyApp
```

指定工程或 workspace（两者选其一）：

```bash
bash scripts/install.sh build /path/to/app --workspace ios/MyApp.xcworkspace --scheme MyApp
```

导出 Ad Hoc 包到指定目录：

```bash
bash scripts/install.sh build /path/to/app --export-method ad-hoc --output-dir artifacts/ipa
```

查看全部参数：

```bash
bash scripts/install.sh build --help
```

## 签名和依赖

Xcode 仍需有可用的开发者账号、证书和签名配置。工具不会替你选择陌生的 Team、创建账号或注册测试设备。development / ad-hoc 安装的设备需要满足相应签名配置。

自动签名项目默认允许 Xcode 用已登录账号刷新 provisioning assets；加 `--no-provisioning-updates` 可关闭。手动签名沿用项目中配置的 profile。它不会上传 App Store Connect；临时 ExportOptions.plist 明确设置 `destination=export`。

CocoaPods、Flutter 或 React Native 工程需要先完成本身的依赖安装。工具调用 Xcode/fastlane 进行打包，不负责生成业务项目或替换依赖管理器。

fastlane 在临时工作目录运行，不加载 App 中的 Fastfile、Gymfile 或 dotenv；会清理继承的 GYM_* 和 Bundler 配置，防止它们覆盖这次导出。Xcode 自身仍会使用正常的缓存、构建脚本和已登录账号。
