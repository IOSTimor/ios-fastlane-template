# FAQ / Troubleshooting

## Why does `pod search ios-fastlane-template` not find anything?

This repository is not a CocoaPods pod. It is a reusable release automation template. Use one of these instead:

- `curl -fsSL ... | bash`
- `brew install --formula ...`
- `git clone`

## Why is `match` not included by default?

This template assumes signing is already managed by Xcode. It is intentionally scoped to release automation, not certificate lifecycle management.

## What if my project already has a `fastlane/` directory?

The installer refuses to overwrite it by default. Re-run only if you explicitly want replacement:

```bash
ios-fastlane-template /path/to/your/ios-project --force
```

or:

```bash
curl -fsSL https://raw.githubusercontent.com/IOSTimor/ios-fastlane-template/main/scripts/install.sh | bash -s -- /path/to/your/ios-project --force
```

## What if my project has multiple `.xcodeproj` or `.xcworkspace` files?

The installer only auto-detects a single project or workspace cleanly. In multi-project setups:

- review `fastlane/.env.default`
- review the generated `.env`
- set `PROJECT`, `WORKSPACE`, and `SCHEME` manually
- re-run with `--project`, `--workspace`, `--scheme`, or `--app-name` if needed
- run `fastlane ios validate_setup`

The installer now prints a recommended explicit command to help you re-run it with concrete values.

## Why does `precheck_assets` show zero screenshots?

`precheck_assets` only counts actual screenshot image files such as `.png`, `.jpg`, or `.jpeg`. Locale README files are intentionally ignored.

## Why does the installer stop on an existing setup?

That is intentional. Silent overwrite is risky in real app repositories. Use `--force` only when you have reviewed the target project and want replacement.

## Why is this not an Xcode project generator?

Because the repository is optimized for reusing release automation across existing apps. Project generation and release automation have different maintenance costs and should stay separate.

## What if I want pinned Ruby dependencies?

Install with the included `Gemfile`:

```bash
bundle install
bundle exec fastlane lanes
```

## What if Homebrew install works but `pod search` still fails?

That is expected. Homebrew installs a CLI wrapper for the template installer. CocoaPods is a different distribution mechanism and not used here.

## Does the installer create `.env` for me?

Yes. If `.env` does not already exist, the installer copies `.env.example` to `.env` and fills detected defaults such as `PROJECT`, `WORKSPACE`, `SCHEME`, and `APP_NAME`.

## What should I check first if a lane fails?

1. Confirm the app builds and signs in Xcode.
2. Run `fastlane ios validate_setup`.
3. Run `fastlane ios precheck_assets`.
4. Check `.env` and `fastlane/.env.default`.
5. Confirm App Store Connect credentials are present for upload flows.
