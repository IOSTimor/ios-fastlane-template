# Changelog

All notable changes to this repository will be documented in this file.

The format is based on Keep a Changelog, and this repository follows Semantic Versioning as a practical guideline for template evolution.

## [Unreleased]

### Added

- Placeholder for upcoming changes

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
