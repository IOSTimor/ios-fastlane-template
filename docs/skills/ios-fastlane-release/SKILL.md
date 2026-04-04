---
name: ios-fastlane-release
description: Use when the user wants to set up, reuse, or standardize an iOS fastlane release workflow for local IPA builds, TestFlight uploads, App Store metadata/screenshots upload, or first-time App Store Connect app creation without introducing match.
---

# iOS Fastlane Release

Use this skill when the task is about reusing or implementing a `fastlane/` workflow in an iOS project where signing is already managed by Xcode.

This skill assumes:

- the target is an iOS app project
- certificates and provisioning profiles are already configured in Xcode
- the goal is release automation, not project scaffolding
- `match` is intentionally not introduced unless the user explicitly asks for it

## Goal

Turn an existing iOS project into a project with a reusable, parameterized fastlane release setup that is ready for:

- local IPA export
- release flow for an existing App Store Connect app
- first release flow for a new App Store Connect app

The skill should bring the repo to "fastlane configured and ready to validate" state. It should not pretend that Apple-side assets or permissions are already satisfied unless they can be verified locally.

## What this skill should do

Focus on reusable release automation:

- create or update `fastlane/Appfile`
- create or update `fastlane/Fastfile`
- create or update a project-root `.env.example` when release credentials or shared variables need to be documented
- create or update `fastlane/.env.default` when safe project defaults would reduce repeated command parameters
- define lanes for local IPA build, existing-app release, and new-app first release
- keep project-specific differences in parameters, environment variables, metadata, and screenshots
- preserve the convention `fastlane/metadata/<locale>/` and `fastlane/screenshots/<locale>/`

Do not broaden scope into:

- generating a new Xcode project
- bundle identifier replacement scripts across a template project
- business-specific release scripts unrelated to fastlane

## Execution model

Run in three phases:

1. Detect
2. Configure
3. Validate

If the user asks to "set up fastlane for this iOS project", this skill should normally perform all three phases in one pass.

## Phase 1: Detect

Inspect the repository before editing anything.

Check for:

- `.xcodeproj` or `.xcworkspace`
- existing project-root `.env.example`
- existing `fastlane/` directory
- existing `fastlane/Appfile`
- existing `fastlane/Fastfile`
- existing `fastlane/.env.default`
- existing `fastlane/metadata/`
- existing `fastlane/screenshots/`
- obvious project identifiers already present in the repo
- whether the repo appears to be native iOS or Flutter-with-iOS-runner

Classify the project into one of these states:

- no fastlane setup yet
- partial fastlane setup
- existing fastlane setup that should be adapted

Then identify the requested release shape:

- local IPA only
- existing App Store Connect app
- first release for a new App Store Connect app

If the repo already has a release workflow, adapt it instead of rewriting everything from scratch.

This skill should support incremental upgrades. A repo that only supports local IPA build today may later be upgraded to release flows without replacing the working local-build setup.

## Phase 2: Configure

Keep `Appfile` minimal. Prefer environment variables for fields that vary between projects.

Keep `Fastfile` parameterized. Do not hardcode app names, schemes, bundle IDs, or release metadata into lanes.

Generate a project-root `.env.example` that lists required and optional variables the user must fill.

Generate `fastlane/.env.default` for safe project defaults such as inferred scheme, app name, language, bundle identifier, or team identifier when those are known.

For local IPA only workflows, these env files are optional. Prefer them when they reduce repeated parameters, but do not treat them as blockers for local build support.

When a repo already supports local IPA build and the user later asks for TestFlight or App Store release, extend the existing setup in place:

- keep the working local-build lane
- add release lanes if missing
- add `.env.example` and `fastlane/.env.default` if release inputs now need to be documented
- add `metadata/` and `screenshots/` folders if upload flows need them
- report only the newly required inputs instead of re-listing local-build requirements as blockers

Use one private shared release lane and expose small public lanes for each scenario.

When adding upload behavior, rely on local `metadata/` and `screenshots/` folders instead of embedding large text into the lane itself.

If the user needs exact lane shapes or command examples, read [`references/fastlane-ios-template.md`](references/fastlane-ios-template.md).

If you need to report required inputs and likely blockers, read [`references/ios-fastlane-readiness-checklist.md`](references/ios-fastlane-readiness-checklist.md).

## Implementation rules

- Default platform should be `ios`.
- Keep `local_build` isolated from upload or review submission logic.
- Use options for mutable fields such as `scheme`, `version`, `build_number`, `app_identifier`, `app_name`, `sku`, `language`, `automatic_release`, and tester-related fields.
- For existing apps, the public lane should only call the shared release lane.
- For first-time releases, the public lane may optionally call `produce` before the shared release lane.
- If metadata or screenshots are missing, do not invent content. Keep fastlane configured to upload only what exists locally.
- If the repo already has a different lane structure, adapt the pattern instead of forcing a full rewrite.
- Treat "local build only" and "release capable" as upgrade levels of the same setup, not separate templates that require a reset.
- `.env.example` should document release-oriented inputs without storing secrets. It is recommended for upload and release flows, but optional for local-build-only setups.
- `fastlane/.env.default` should contain only non-sensitive defaults and placeholders that are safe to commit. It is optional when command-line parameters are sufficient.
- Prefer repo-safe setup:
  - write files and folders
  - generate examples
  - validate with non-destructive commands
  - report missing Apple-side prerequisites
- Do not assume `scheme`, `team_id`, or `app_identifier` if they cannot be inferred. If not discoverable, leave them parameterized and clearly report them as required inputs.

## Phase 3: Validate

Prefer lightweight validation in this order:

1. file structure validation
2. lane shape validation
3. environment and tool availability checks
4. non-destructive fastlane validation

Useful validation commands include:

- `fastlane lanes`
- `xcodebuild -list`

Do not run destructive release commands unless the user explicitly asks for that execution.

## Output contract

When this skill finishes, the response should clearly separate:

- what was configured in the repo
- what is ready to use immediately
- what inputs are still required
- what Apple-side or environment-side blockers remain
- example commands to run next

If `.env.example` or `fastlane/.env.default` were created, tell the user exactly which file they should fill next. Do this only when the chosen flow actually needs more values.

Prefer a readiness summary like:

- Ready now
- Ready after filling variables
- Blocked by Apple/Xcode setup

If the user is upgrading from local-build-only to release-capable, make that transition explicit in the response.

## Deliverables

When you implement or refactor this workflow, the result should usually include:

- a parameterized `fastlane/Appfile`
- a reusable `fastlane/Fastfile`
- an optional project-root `.env.example`
- an optional `fastlane/.env.default`
- optional locale folders under `fastlane/metadata/`
- optional locale folders under `fastlane/screenshots/`
- example commands for the lanes that were added
- a short readiness report based on the checklist reference
