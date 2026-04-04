# iOS Fastlane Readiness Checklist

Use this reference when you need to evaluate whether an iOS project is only "fastlane configured" or actually "ready to run".

## Status model

Use these labels in responses:

- `Ready now`: the repo has enough information and tooling to run the next non-destructive step immediately
- `Ready after filling variables`: the fastlane structure is in place, but project-specific values are still missing
- `Blocked by Apple/Xcode setup`: the repo can be configured, but actual build or upload depends on external signing, account, or App Store setup

You may also describe the setup level:

- `Local-build capable`
- `Release-capable`

## Repo-side checks

Check for:

- `fastlane/Appfile`
- `fastlane/Fastfile`
- `fastlane/metadata/`
- `fastlane/screenshots/`
- `.xcodeproj` or `.xcworkspace`
- a discoverable scheme or a clearly required scheme input

Conditional checks:

- project-root `.env.example` for release or upload-oriented flows
- `fastlane/.env.default` when shared defaults are expected

## Environment-side checks

Check for:

- `fastlane` installed
- Xcode command line tooling available
- ability to list schemes with `xcodebuild -list`

## Apple-side prerequisites

These are often not fully verifiable from the repo alone:

- Apple Developer account access
- App Store Connect access
- team configuration
- bundle identifier registration
- certificates and provisioning profiles
- whether the App Store Connect app already exists
- review metadata completeness

## Recommended response shape

Report in this order:

1. repo changes completed
2. whether this was a fresh setup or an upgrade from local-build-only to release-capable
3. current readiness label
4. missing required inputs
5. suggested next command
6. which env file the user should fill next, if the chosen flow requires one

## Common inputs by scenario

Local IPA only:

- `scheme` if it cannot be inferred
- optional `export_method`

Release and upload flows:

- `APP_IDENTIFIER`
- `APPLE_ID`
- `TEAM_ID`
- `ITC_TEAM_ID`
- `APP_STORE_KEY_ID`
- `APP_STORE_ISSUER_ID`
- `APP_STORE_KEY_FILE`
- `scheme`
- `version`
- `build_number`
- `app_name`
- `sku`

## Upgrade scenario

If the repo already supports `local_build` and the user later asks for upload or release:

- keep the existing local-build workflow unchanged
- add only the missing release-specific pieces
- treat missing Apple credentials, metadata, screenshots, and release variables as newly required inputs
- do not mark the repo as "not configured" just because it was previously configured only for local build

## Important interpretation rule

If the repo is configured but Apple-side setup is unverified, do not say "fully ready for release". Prefer:

- "fastlane is configured"
- "ready for local validation"
- "ready after Apple credentials/signing are confirmed"

If `.env.example` exists, prefer telling the user to create or fill `.env` from it before running release lanes. Do not require this for a local-build-only workflow unless the lane was designed around env-only inputs.
