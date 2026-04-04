# en-US Screenshots

Add App Store screenshots for the `en-US` locale in this directory.

Recommended file naming:

- `01-home.png`
- `02-feature.png`
- `03-results.png`

Guidelines:

- keep names ordered with a numeric prefix
- use PNG unless your workflow requires JPEG
- export final assets, not design-source files
- keep only locale-specific screenshots here
- replace this file if your team prefers a different screenshot workflow

Suggested workflow:

1. prepare the final marketing copy for each screen
2. generate or export screenshots from your app or design tool
3. place the final files in this folder
4. run `fastlane ios precheck_assets`
5. run `fastlane ios metadata_only` or a release lane
