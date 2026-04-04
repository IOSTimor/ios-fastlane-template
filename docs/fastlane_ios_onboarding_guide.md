# iOS Fastlane Reusable Release Onboarding Guide

This repository is built for teams that already have a working iOS app project and want a reusable `fastlane/` release workflow without introducing `match`.

## Scope

This template is designed for:

- local IPA export
- TestFlight upload
- App Store metadata and screenshot upload
- first release for a new App Store Connect app

This template does not:

- generate an Xcode project
- replace bundle identifiers across a scaffolded app template
- manage signing certificates or provisioning with `match`

## Recommended project structure

```text
your-ios-project/
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

## Install into an existing project

From this repository:

```bash
cd ios-newapp-template
bash scripts/create_project.sh /path/to/your/ios-project
```

Then in the target project:

```bash
cp .env.example .env
```

Optional but recommended for teams that want pinned Ruby dependencies:

```bash
bundle install
```

Fill at least these values in `.env`:

```dotenv
APP_IDENTIFIER=com.example.app
SCHEME=MyApp
PROJECT=MyApp.xcodeproj
TEAM_ID=ABCDE12345
```

For upload workflows, also fill either:

- `APP_STORE_KEY_ID`, `APP_STORE_ISSUER_ID`, `APP_STORE_KEY_FILE`

or a valid interactive/session-based fastlane login setup such as:

- `FASTLANE_SESSION`
- `FASTLANE_USER`

## Files and responsibilities

### `fastlane/Appfile`

Minimal identity settings only. Values come from environment variables so the same template can be reused across projects.

### `fastlane/Fastfile`

Public lanes:

- `local_build`
- `release_existing`
- `release_new`
- `testflight_only`
- `submit_review`
- `metadata_only`
- `precheck_assets`
- `validate_setup`

Private lane:

- `shared_release`

The design goal is:

- local build stays isolated from upload logic
- release flows share one implementation path
- mutable inputs stay in options or env vars

### `.env.example`

Documents what each project must provide without committing secrets.

### `fastlane/.env.default`

Holds safe committed defaults such as `SCHEME`, `PROJECT`, `APP_NAME`, and `LANGUAGE`.

## Lanes

### 1. Validate setup

```bash
fastlane ios validate_setup
fastlane ios precheck_assets
```

Checks the inferred paths and whether metadata or screenshots exist locally.

### 2. Local IPA build only

```bash
fastlane ios local_build \
  scheme:"MyApp" \
  export_method:"development"
```

This lane does not require App Store Connect credentials.

### 3. Release an existing App Store Connect app

```bash
fastlane ios release_existing \
  scheme:"MyApp" \
  app_identifier:"com.example.app" \
  version:"1.0.0" \
  build_number:"1" \
  beta_description:"Internal testing build" \
  testers:"internal" \
  automatic_release:false \
  submit_for_review:false
```

### 4. First release for a new app

```bash
fastlane ios release_new \
  create_app:true \
  scheme:"MyApp" \
  app_identifier:"com.example.app" \
  app_name:"MyApp" \
  sku:"myapp001" \
  language:"en-US" \
  version:"1.0.0" \
  build_number:"1"
```

### 5. TestFlight upload only

```bash
fastlane ios testflight_only \
  scheme:"MyApp" \
  app_identifier:"com.example.app" \
  version:"1.0.0" \
  build_number:"1"
```

### 6. Submit review using an existing build

```bash
fastlane ios submit_review \
  app_identifier:"com.example.app" \
  upload_metadata:true \
  upload_screenshots:true \
  automatic_release:false
```

### 7. Metadata and screenshot upload only

```bash
fastlane ios metadata_only \
  app_identifier:"com.example.app" \
  upload_metadata:true \
  upload_screenshots:true
```

## Makefile shortcuts

Inside the target project:

```bash
make lanes
make validate
make precheck-assets
make local-build SCHEME=MyApp EXPORT_METHOD=development
make release-existing SCHEME=MyApp APP_IDENTIFIER=com.example.app
make release-new SCHEME=MyApp APP_IDENTIFIER=com.example.app APP_NAME=MyApp SKU=myapp001
make testflight-only SCHEME=MyApp APP_IDENTIFIER=com.example.app
make submit-review APP_IDENTIFIER=com.example.app
make metadata-only APP_IDENTIFIER=com.example.app
```

## Metadata and screenshots

The template preserves the standard fastlane layout:

- `fastlane/metadata/<locale>/`
- `fastlane/screenshots/<locale>/`

Rules:

- do not hardcode metadata content in `Fastfile`
- commit text metadata when it is safe to share
- keep screenshots local or commit only sanitized examples
- the template already includes `en-US` and `zh-Hans` sample metadata files that should be rewritten per app

If there are no metadata or screenshot files, the relevant upload step is skipped unless you explicitly force it.

## Validation flow

Prefer non-destructive checks in this order:

1. `fastlane lanes`
2. `fastlane ios validate_setup`
3. `fastlane ios precheck_assets`
4. `xcodebuild -list -project MyApp.xcodeproj`
5. `fastlane ios local_build`

Do not run release lanes until:

- signing already works in Xcode
- the scheme builds from command line
- release credentials are in place

## Readiness summary

### Ready now

- copying the template into an existing iOS project
- filling `.env`
- validating lane availability
- running local IPA export

### Ready after filling variables

- TestFlight upload
- App Store metadata upload
- screenshot upload
- submission and automatic release options

### Still blocked by Apple/Xcode setup

- missing signing configuration in Xcode
- invalid or missing App Store Connect access
- missing or incorrect bundle identifier and team mapping
