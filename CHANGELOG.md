# Changelog

All notable changes to this repository will be documented in this file.

The format is based on Keep a Changelog, and this repository follows Semantic Versioning as a practical guideline for template evolution.

## [Unreleased]

## [1.4.0] - 2026-11-12

### Added

- `iosipa testflight`, `iosipa metadata` and `iosipa submit` adapters for the existing release lanes.
- Per-command options/help, exact existing-build selection, external distribution checks and no-network dry-run plans.
- Homebrew bundles the release adapter; project workflows and credentials are preserved.
- Project Bundler dependencies are checked/installed before invoking release lanes when a Gemfile exists.

## [1.3.1] - 2026-11-12

### Added

- `iosipa` short command installed alongside `ios-fastlane-template`, with matching help text.
- Homebrew tests verify both command names can export local IPAs through the same implementation.

## [1.3.0] - 2026-11-12

### Added

- Homebrew installs the local builder, Ruby and fastlane; the installed `build` command works without downloading the repository.
- One-command local IPA builder with real Xcode scheme/signing discovery, workspace preference, interactive selection, dry-run and isolated fastlane execution.

- Load generated configuration from `fastlane/.env`, with one-time legacy root `.env` import and Git ignore rules.
- Preserve existing metadata, screenshots and local environment files during forced installation.
- Preserve spaces and nested paths in project detection; exclude Pods and internal project workspaces.
- Validate build paths, partial credentials and requested assets before building or creating an app.
- Reject empty metadata and starter placeholders in requested uploads; count actual screenshot images.
- Require explicit metadata/screenshot uploads in release lanes; reuse remote assets for existing-build review.
- Upload each binary once; pin combined review submission to the IPA just built.
- Wait for external TestFlight distribution and review submission; reject conflicting processing options.
- Omit empty Makefile options and pass values as data; apply version changes to the selected project.
- Fix tag archive download URLs, synchronize formula update fields and add real formula installation checks.
- Run installer and release regressions on macOS and Linux; replace the contradictory multi-project assertion.
- Replace machine-specific documentation links and SSH aliases.

## [1.2.1] - 2026-04-05

### Fixed

- Homebrew formula now pins to a tagged installer script instead of the moving `main` branch
- Homebrew CLI wrapper now displays the correct `ios-fastlane-template` usage text
- Tap-based Homebrew installation is now stable against raw GitHub branch cache drift

## [1.2.0] - 2026-04-04

### Added

- Automatic `.env` generation during installation when the target project does not already have one
- Homebrew tap publishing notes and tap-ready packaging guidance
- Explicit recommended installer commands for complex project layouts

### Changed

- Multi-project and multi-workspace detection now leaves values blank instead of preserving misleading defaults
- Installer CLI usage now documents explicit override options
- CI now validates generated `.env` values and multi-project detection behavior

## [1.1.0] - 2026-04-04

### Added

- `testflight_only`, `submit_review`, and `precheck_assets` lanes
- `curl | bash` installer flow and Homebrew formula support
- `en-US` and `zh-Hans` starter metadata content plus screenshot guidance
- `SECURITY.md`, troubleshooting guide, and release notes drafts

### Changed

- Installer now auto-detects project, workspace, scheme, and app name defaults
- Installer now refuses to overwrite existing fastlane setups unless forced
- CI now validates installer flows and formula syntax
- README homepage structure now emphasizes quick start, workflows, and adoption guidance

## [1.0.0] - 2026-04-04

### Added

- Reusable iOS fastlane release template with parameterized `Appfile` and `Fastfile`
- Support for `local_build`, `release_existing`, `release_new`, `metadata_only`, and `validate_setup`
- Project-level `.env.example` and `fastlane/.env.default`
- Installer script for copying the template into an existing iOS project
- Bilingual root README
- MIT license
- Onboarding and skill reference documentation

### Changed

- Refocused the repository around release automation only
- Replaced example-only lanes with reusable, parameterized workflows

### Removed

- Generated fastlane artifacts that should not ship in the template repository
- Legacy scaffolding assumptions around creating a new Xcode project from this repository
