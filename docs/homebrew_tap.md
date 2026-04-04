# Homebrew Tap Publishing Notes

This repository already supports direct formula installation:

```bash
brew install --formula https://raw.githubusercontent.com/IOSTimor/ios-fastlane-template/main/Formula/ios-fastlane-template.rb
```

If you want the more standard tap flow:

```bash
brew tap IOSTimor/tap
brew install ios-fastlane-template
```

publish the formula in a dedicated tap repository:

- repository name: `homebrew-tap`
- formula path: `Formula/ios-fastlane-template.rb`

## Suggested flow

1. Create `IOSTimor/homebrew-tap`
2. Copy [Formula/ios-fastlane-template.rb](/Users/cx/Desktop/ios-fastlane-template/Formula/ios-fastlane-template.rb) into that repo's `Formula/` directory
3. Copy the template files from [`templates/homebrew-tap/`](/Users/cx/Desktop/ios-fastlane-template/templates/homebrew-tap/):
   - [`templates/homebrew-tap/README.md`](/Users/cx/Desktop/ios-fastlane-template/templates/homebrew-tap/README.md)
   - [`templates/homebrew-tap/.github/workflows/test-formula.yml`](/Users/cx/Desktop/ios-fastlane-template/templates/homebrew-tap/.github/workflows/test-formula.yml)
4. Update the formula `version` and `sha256` whenever `scripts/install.sh` changes
5. Test the tap locally

```bash
brew tap IOSTimor/tap https://github.com/IOSTimor/homebrew-tap
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
