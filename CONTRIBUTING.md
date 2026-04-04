# Contributing

Thank you for contributing.

## Scope

This repository is intentionally narrow. Changes should improve the reusable iOS release workflow without expanding the template into a full project generator.

Good contributions:

- safer fastlane defaults
- clearer documentation
- better parameterization
- non-destructive validation improvements
- fixes for reusable metadata or screenshot handling

Changes to avoid unless explicitly discussed:

- adding `match` by default
- adding business-specific release logic
- turning the repository into an Xcode app scaffold

## Development Notes

Before opening a pull request:

1. Keep the template focused on existing iOS projects.
2. Prefer environment variables or lane options over hardcoded values.
3. Do not commit secrets, signing assets, or generated reports.
4. Validate non-destructively where possible.

Useful checks:

```bash
ruby -c ios-newapp-template/fastlane/Fastfile
ruby -c ios-newapp-template/fastlane/Appfile
bash -n ios-newapp-template/scripts/create_project.sh
bash -n ios-newapp-template/scripts/replace_placeholders.sh
cd ios-newapp-template && fastlane lanes
make -C ios-newapp-template validate
```

## Pull Request Expectations

- describe the user-facing reason for the change
- mention any workflow behavior changes
- update documentation when commands or files change
- keep the repository publishable as a clean template
