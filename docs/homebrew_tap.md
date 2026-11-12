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
bash scripts/update_homebrew_formula.sh 1.4.1
```

That command updates the URL, version, wrapper reference and SHA-256 in both formula copies. Publish the matching tag with those exact installer bytes before distributing the formula. It updates:

- [`Formula/ios-fastlane-template.rb`](../Formula/ios-fastlane-template.rb)

based on the current hash of:

- [`scripts/install.sh`](../scripts/install.sh)

To generate the tap repository skeleton itself, use:

```bash
bash scripts/prepare_homebrew_tap_repo.sh /path/to/homebrew-ios-release IOSTimor homebrew-ios-release
```

The v1.4.1 formula pins `install.sh`, `build_local.rb` and `release.rb` by tag and checksum. It installs the builder beside the launcher, so `iosipa build` executes locally. Ruby and fastlane are explicit dependencies. The helper updates all checksums and URLs; publish the matching source tag before publishing the tap. It does not create or push tags.

Starting with v1.3.1, `iosipa` is installed as a symlink to the same launcher. The package name remains `ios-fastlane-template`, and both commands remain supported.
