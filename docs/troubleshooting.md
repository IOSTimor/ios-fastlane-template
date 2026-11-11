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
- review the generated `fastlane/.env`
- set `PROJECT`, `WORKSPACE`, and `SCHEME` manually
- re-run with `--project`, `--workspace`, `--scheme`, or `--app-name` if needed
- run `bundle exec fastlane ios validate_setup`

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

## Does the installer create `fastlane/.env` for me?

Yes. If `fastlane/.env` does not already exist, the installer imports a legacy root `.env` once if present, otherwise copies `fastlane/.env.example` and fills inferred defaults. Existing environment files are preserved even with `--force`.

## What should I check first if a lane fails?

1. Confirm the app builds and signs in Xcode.
2. Run `bundle exec fastlane ios validate_setup`.
3. Run `bundle exec fastlane ios precheck_assets`.
4. Check `fastlane/.env` and `fastlane/.env.default`.
5. Confirm App Store Connect credentials are present for upload flows.

## Why do edits to my old root `.env` no longer affect releases?

All dotenv files now live under `fastlane/`, matching fastlane's directory selection. Reinstall the updated template with `--force` to import the root `.env` once, then maintain `fastlane/.env`. The root file is left intact. Check the imported scheme, paths and credentials before uploading. Exported shell variables take precedence, and `--env staging` loads `fastlane/.env.staging`.

## How do I validate assets before building?

`precheck_assets` prints an inventory. For failing validation suitable for CI, use:

```bash
bundle exec fastlane ios precheck_assets strict:true upload_metadata:true upload_screenshots:true
```

Required metadata files must exist and be nonempty; starter copy and example URLs must be replaced. Screenshot detection counts image files, not README files. Image dimensions and Apple-side eligibility are still checked by fastlane and App Store Connect.

## Why were my metadata and screenshots not uploaded during release?

Release lanes require explicit `upload_metadata:true` and `upload_screenshots:true`. This avoids sending template content. `metadata_only` validates and uploads metadata by default; `submit_review` reuses remote metadata unless asked to upload local assets. Neither lane requires a local scheme or Xcode project.

## External testers did not receive a build

External distribution requires `groups` and completed build processing. The release lane defaults to waiting when `distribute_external:true` and rejects an explicitly conflicting `skip_waiting_for_build_processing:true` before building.

## Does `validate_setup` verify Apple permissions or signing?

It checks local scheme configuration and selected project/workspace paths. It does not contact Apple or run Xcode. Use `build:false` for an inventory without build prerequisites, for example when only uploading metadata.
