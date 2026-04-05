# Homebrew Tap Publishing Notes

This repository already supports direct formula installation:

```bash
brew install --formula https://raw.githubusercontent.com/IOSTimor/ios-fastlane-template/main/Formula/ios-fastlane-template.rb
```

For a shorter and clearer Homebrew experience, publish a dedicated tap repository named `homebrew-ios-release`.

The recommended user-facing flow then becomes:

```bash
brew tap IOSTimor/ios-release
brew install ios-fastlane-template
```

That corresponds to this tap repository:

- repository name: `homebrew-ios-release`
- formula path: `Formula/ios-fastlane-template.rb`

## Suggested flow

1. Create or rename the tap repository to `IOSTimor/homebrew-ios-release`
2. Generate the tap scaffold locally:

```bash
bash scripts/prepare_homebrew_tap_repo.sh /path/to/homebrew-ios-release IOSTimor homebrew-ios-release
```

3. Commit the generated files into the tap repository
4. Update the formula `version` and `sha256` whenever `scripts/install.sh` changes
5. Test the tap locally

```bash
brew tap IOSTimor/ios-release https://github.com/IOSTimor/homebrew-ios-release
brew install ios-fastlane-template
ios-fastlane-template
```

## Versioning Note

The formula installs the CLI wrapper script from this repository. If the installer script changes, update:

- `version`
- `sha256`

before publishing the next tap release.

Use the helper script in this repository:

```bash
bash scripts/update_homebrew_formula.sh 1.2.1
```

That command updates:

- [`Formula/ios-fastlane-template.rb`](/Users/cx/Desktop/ios-fastlane-template/Formula/ios-fastlane-template.rb)

based on the current hash of:

- [`scripts/install.sh`](/Users/cx/Desktop/ios-fastlane-template/scripts/install.sh)

To generate the tap repository skeleton itself, use:

```bash
bash scripts/prepare_homebrew_tap_repo.sh /path/to/homebrew-ios-release IOSTimor homebrew-ios-release
```
