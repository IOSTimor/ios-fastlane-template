# iosipa 认证信息获取与配置

适用版本：v1.4.0。配置文件位于**你的 App 项目**的 `fastlane/.env`。

## 先确认：你必须配置吗

| 使用场景 | 是否需要 App Store Connect 认证 |
|---|---|
| `iosipa build` 打本地 IPA | 不需要；沿用 Xcode 签名配置 |
| `iosipa testflight` | 需要 |
| `iosipa metadata` | 需要 |
| `iosipa submit` | 需要 |

认证必需不等于 API Key 必需。发布可选团队 API Key 或 Apple ID 登录。推荐团队 API Key，适合自动化，也减少交互登录；两种方式的能力和限制见 [fastlane 官方认证说明](https://docs.fastlane.tools/getting-started/ios/authentication/)。

先按[操作手册的一次性配置](user_guide.md#5-发布前的一次性配置)安装模板，保留生成的工程配置，不要为了填写认证而覆盖整个 `.env`。

## 方案 A：团队 API Key（推荐）

### 第一步：找到 Apple 后台入口

登录 [App Store Connect](https://appstoreconnect.apple.com/)，进入：

```text
用户和访问（Users and Access）
  → 集成（Integrations）
  → App Store Connect API
  → 团队密钥（Team Keys）
```

第一次申请 API 访问需要 Account Holder。访问开通后，由 Account Holder 或 Admin 创建团队密钥。若没有入口，请让团队的相应管理员操作。[Apple 官方步骤](https://developer.apple.com/help/app-store-connect/get-started/app-store-connect-api)

创建时起一个方便识别的名称，例如 `iosipa-release`。按实际任务赋予权限；需要提交审核时，可选择具备该能力的 App Manager 角色，无需为此直接选择 Admin。[Apple 提交审核角色要求](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app/)

### 第二步：保存三个值

| 要填写的字段 | 获取位置 | 含义 |
|---|---|---|
| `APP_STORE_KEY_ID` | 团队密钥列表里的 Key ID | 标识这把密钥 |
| `APP_STORE_ISSUER_ID` | API 页面上方的 Issuer ID | 标识签发团队，不是 Team ID |
| `APP_STORE_KEY_FILE` | 下载的 `.p8` 私钥在你电脑上的路径 | 本地文件路径，不是密钥内容 |

Issuer ID 和 Key ID 的位置见 [Apple 官方说明](https://developer.apple.com/documentation/appstoreconnectapi/generating-tokens-for-api-requests)。

下载的私钥通常名为 `AuthKey_<KeyID>.p8`。私钥只能下载一次，请妥善保存，不要提交 Git、发到聊天或放进 App 包中。[Apple 密钥管理说明](https://developer.apple.com/documentation/appstoreconnectapi/creating-api-keys-for-app-store-connect-api)

**当前模板的 API Key 校验要求同时有 Issuer ID，请选择 Team Keys。个人 API Key 没有 Issuer ID，当前模板尚未适配。** 这也是为什么不能把“个人 API Key”的值直接填进本模板。[fastlane 对个人 Key 的说明](https://docs.fastlane.tools/actions/app_store_connect_api_key/)

### 第三步：把文件放到项目中并填写 `.env`

下面是假设的目录和示例值，不是真实凭证；按你的实际情况替换：

```text
MyApp/
└── fastlane/
    ├── Fastfile
    ├── .env
    └── AuthKey_ABC123DEFG.p8
```

在已有的 `fastlane/.env` 中填写：

```dotenv
APP_IDENTIFIER=com.yourcompany.MyApp

APP_STORE_KEY_ID=ABC123DEFG
APP_STORE_ISSUER_ID=11111111-2222-3333-4444-555555555555
APP_STORE_KEY_FILE=./fastlane/AuthKey_ABC123DEFG.p8

APPLE_ID=
FASTLANE_USER=
FASTLANE_SESSION=
```

- `APP_IDENTIFIER`：Xcode → App Target → Signing & Capabilities → Bundle Identifier。必须与 App Store Connect 中的 App 对应。
- 私钥相对路径以 **App 项目根目录**为基准，虽然 `.env` 在 fastlane 子目录中，也不要将上例误写成 `./AuthKey_ABC123DEFG.p8`。
- 可以改用绝对路径，例如 `APP_STORE_KEY_FILE="/Users/yourname/Keys/AuthKey_ABC123DEFG.p8"`，无需把私钥复制进项目。
- 路径包含空格时用双引号包住值。
- 保留原有 SCHEME、PROJECT、WORKSPACE 等值；API Key 不会替你配置 Xcode 签名。

## 方案 B：已有 Apple ID 登录

适合可以交互登录的本地发布场景。先把 API Key 三项**一起清空**，再填登录邮箱：

```dotenv
APP_STORE_KEY_ID=
APP_STORE_ISSUER_ID=
APP_STORE_KEY_FILE=

APPLE_ID=you@example.com
FASTLANE_USER=you@example.com
FASTLANE_SESSION=
APP_IDENTIFIER=com.yourcompany.MyApp
```

第一次运行发布命令时，fastlane 可能提示登录及双重认证。普通账号密码无需写进本模板的 `.env`。

如果需要提前生成会话，可在 App 项目目录执行：

```bash
bundle install
bundle exec fastlane spaceauth -u you@example.com
```

将 fastlane 生成的会话值按其提示保存到 `FASTLANE_SESSION` 环境变量，或作为单行、正确引用的值放入项目的 `fastlane/.env`。会话属于敏感信息，不要分享。会话可能过期，并受运行机器／地区影响；失效后要重新登录生成。[fastlane 会话说明](https://docs.fastlane.tools/getting-started/ios/authentication/)

Apple ID 上传二进制还可能需要应用专用密码，通过环境变量 `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD` 提供。**仅有应用专用密码不能完成文案修改、测试者分发和审核等完整操作。** 具体适用条件以 [fastlane 认证说明](https://docs.fastlane.tools/getting-started/ios/authentication/)为准；新接入建议优先用方案 A。

不要用 `--non-interactive` 来尝试第一次需要验证码的交互登录。CI 中应提前准备 API Key 或可用会话。

## `.env` 中其他字段是否必须填写

| 字段 | 用途／来源 | 对发布子命令的要求 |
|---|---|---|
| `SCHEME` | Xcode 中的应用 scheme | TestFlight 构建需要；素材和审核不需要本地 scheme |
| `PROJECT` | 项目根目录下 `.xcodeproj` 的相对路径 | 无 workspace 时用于构建；指定版本／构建号修改时必须正确 |
| `WORKSPACE` | `.xcworkspace` 的相对路径 | 有 workspace 时优先用于构建 |
| `CONFIGURATION` | Xcode 编译配置 | 默认 Release |
| `TEAM_ID` | Apple Developer Membership details 中的 Team ID | 签名相关，API Key 认证本身不强制填写；不要与 Issuer ID 混填 |
| `ITC_TEAM_ID` | Apple ID 多团队登录时使用的 App Store Connect 团队标识 | API Key 路径通常可留空，不是 Issuer ID |
| `APP_NAME` / `SKU` / `LANGUAGE` | 新建 App 等扩展流程的参数 | 日常 testflight、metadata、submit 不要求全部填写 |
| `DERIVED_DATA_PATH` / `EXPORT_OPTIONS_PLIST` | 自定义构建缓存和导出配置 | 可选，按项目需要填写 |

Team ID 的获取位置见 [Apple 官方说明](https://developer.apple.com/help/glossary/team-id/)。本机 Xcode 已经能够签名，仍不代表账号拥有 App Store Connect 的上传或审核权限，两者需分别准备。

## 配置后怎么检查

先在项目目录执行：

```bash
iosipa testflight --dry-run
```

它只验证本地入口和参数并显示执行计划，**不会尝试认证，也不能证明 Key／会话有效**。

准备实际上传时才执行：

```bash
iosipa testflight
```

该命令会构建并向 Apple 上传，不是“只测试账号”。若只是维护素材或审核，可选择相应命令，不必先构建。

如果出现 `API key configuration is incomplete`，核对 API Key 三个字段是否都填写；如果切换到 Apple ID，就把三项全部清空。`.env` 中未填写的值也可能被 shell 中导出的环境变量覆盖，请检查终端／CI 配置，但不要公开输出全部敏感环境变量。

## 常见混淆

- 下载的是 **App Store Connect API Key**，不是 Apple Developer 证书管理页面中用于 APNs 等服务的另一把 `.p8` key。
- `APP_IDENTIFIER` 是 Bundle ID，不是 App Store Connect 页面上的纯数字 Apple ID。
- `TEAM_ID`、`APP_STORE_ISSUER_ID`、`APP_STORE_KEY_ID` 是不同标识，不能互相替代。
- 这个项目的 `.env` 存在 `fastlane/` 中；编辑其他目录的同名文件不会自动更新这里。
- `.p8` 私钥和 `.env` 即使有忽略规则，也应在提交 Git 前检查它们未被跟踪。

继续使用：[用户操作手册](user_guide.md)、[发布命令说明](release_commands.md)。
