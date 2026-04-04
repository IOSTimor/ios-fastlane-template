# Fastlane iOS Reusable Template Reference

Use this reference when you need the concrete structure, lane layout, env strategy, or example commands for this repository's reusable iOS release workflow.

## Assumptions

- signing remains managed by Xcode
- the target project already exists
- `match` is intentionally out of scope
- `fastlane/` is the reusable unit copied into app repositories

## Recommended structure

```text
project/
├── Gemfile
├── .env.example
├── .env
├── Makefile
└── fastlane/
    ├── .env.default
    ├── Appfile
    ├── Fastfile
    ├── metadata/
    │   └── en-US/
    └── screenshots/
        ├── en-US/
        └── zh-Hans/
```

## Minimal Appfile pattern

```ruby
app_identifier(ENV["APP_IDENTIFIER"]) if ENV["APP_IDENTIFIER"]
apple_id(ENV["APPLE_ID"]) if ENV["APPLE_ID"]
team_id(ENV["TEAM_ID"]) if ENV["TEAM_ID"]
itc_team_id(ENV["ITC_TEAM_ID"]) if ENV["ITC_TEAM_ID"]
```

## Environment file strategy

Use two env layers:

- project-root `.env.example`: documents required and optional values
- `fastlane/.env.default`: stores safe committed defaults

Example `.env.example`:

```dotenv
APPLE_ID=your-apple-id@example.com
FASTLANE_USER=your-apple-id@example.com
FASTLANE_SESSION=

APP_IDENTIFIER=com.example.app
TEAM_ID=ABCDE12345
ITC_TEAM_ID=123456789

APP_STORE_KEY_ID=
APP_STORE_ISSUER_ID=
APP_STORE_KEY_FILE=./fastlane/AuthKey_ABCD1234.p8

SCHEME=MyApp
CONFIGURATION=Release
WORKSPACE=
PROJECT=MyApp.xcodeproj
DERIVED_DATA_PATH=
EXPORT_OPTIONS_PLIST=

APP_NAME=MyApp
SKU=myapp001
LANGUAGE=en-US
```

Example `fastlane/.env.default`:

```dotenv
SCHEME=MyApp
CONFIGURATION=Release
PROJECT=MyApp.xcodeproj
APP_NAME=MyApp
LANGUAGE=en-US
```

## Lane layout

Public lanes:

- `validate_setup`
- `local_build`
- `release_existing`
- `release_new`
- `metadata_only`

Private lanes:

- `shared_release`

## Fastfile template

The repository version is the source of truth:

- [`ios-newapp-template/fastlane/Fastfile`](/Users/cx/Desktop/ios-fastlane-template/ios-newapp-template/fastlane/Fastfile)

## Example commands

Local IPA build:

```bash
fastlane ios local_build \
  scheme:"MyApp" \
  export_method:"development"
```

Release existing app:

```bash
fastlane ios release_existing \
  scheme:"MyApp" \
  app_identifier:"com.example.app" \
  version:"1.0.0" \
  build_number:"1" \
  beta_description:"internal testing update" \
  testers:"internal" \
  automatic_release:false \
  submit_for_review:false
```

First release for new app:

```bash
fastlane ios release_new \
  create_app:true \
  scheme:"MyApp" \
  app_identifier:"com.demo.app" \
  app_name:"DemoApp" \
  sku:"demoapp001" \
  language:"en-US" \
  version:"1.0.0" \
  build_number:"1"
```

Metadata only:

```bash
fastlane ios metadata_only \
  app_identifier:"com.demo.app" \
  upload_metadata:true \
  upload_screenshots:true
```

## What should remain project-specific

- Xcode project or workspace path
- bundle identifiers and team settings
- metadata content
- screenshots
- any business-specific release policy

## Recommended first-run validation

1. copy the template into the real iOS project
2. create `.env` from `.env.example`
3. run `fastlane lanes`
4. run `fastlane ios validate_setup`
5. run `xcodebuild -list`
6. run `fastlane ios local_build`
