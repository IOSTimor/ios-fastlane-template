# Changelog

All notable changes to this repository will be documented in this file.

The format is based on Keep a Changelog, and this repository follows Semantic Versioning as a practical guideline for template evolution.

## [Unreleased]

### Added

- Placeholder for upcoming changes

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
