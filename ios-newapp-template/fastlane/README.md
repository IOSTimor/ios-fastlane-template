fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios validate_setup

```sh
[bundle exec] fastlane ios validate_setup
```

Print configured lanes and inferred paths

### ios local_build

```sh
[bundle exec] fastlane ios local_build
```

Generate a local IPA without any upload step

### ios release_existing

```sh
[bundle exec] fastlane ios release_existing
```

Release for an existing App Store Connect app

### ios release_new

```sh
[bundle exec] fastlane ios release_new
```

First release for a new app, optionally creating the App Store Connect app

### ios metadata_only

```sh
[bundle exec] fastlane ios metadata_only
```

Upload metadata and screenshots only when local assets exist

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
