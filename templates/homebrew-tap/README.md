# homebrew-tap

Homebrew tap for `ios-fastlane-template`.

## Install

```bash
brew tap IOSTimor/tap https://github.com/IOSTimor/homebrew-tap
brew install ios-fastlane-template
```

## Upgrade

```bash
brew update
brew upgrade ios-fastlane-template
```

## Formula Source

The main repository already provides the source formula:

- source repo: `IOSTimor/ios-fastlane-template`
- source file: `Formula/ios-fastlane-template.rb`

You can scaffold this tap repo locally from the main repository with:

```bash
bash scripts/prepare_homebrew_tap_repo.sh /path/to/homebrew-tap IOSTimor homebrew-tap
```

## Release Workflow

When `scripts/install.sh` changes in the main repository:

1. update the version and sha in `Formula/ios-fastlane-template.rb`
2. copy the updated formula into this tap repository
3. commit and push
4. test with:

```bash
brew untap IOSTimor/tap || true
brew tap IOSTimor/tap https://github.com/IOSTimor/homebrew-tap
brew reinstall ios-fastlane-template
ios-fastlane-template
```
