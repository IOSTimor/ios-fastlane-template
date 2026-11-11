#!/bin/bash

set -euo pipefail

FORMULA_PATH=${FORMULA_PATH:-Formula/ios-fastlane-template.rb}
INSTALL_SCRIPT_PATH=${INSTALL_SCRIPT_PATH:-scripts/install.sh}
VERSION=${1:-}

portable_sed_in_place() {
  local expression=$1
  local file_path=$2

  if sed --version >/dev/null 2>&1; then
    sed -i "$expression" "$file_path"
  else
    sed -i '' "$expression" "$file_path"
  fi
}

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Usage: bash scripts/update_homebrew_formula.sh <version>"
  exit 1
fi

if [[ ! -f "$FORMULA_PATH" ]]; then
  echo "Formula not found: $FORMULA_PATH"
  exit 1
fi

if [[ ! -f "$INSTALL_SCRIPT_PATH" ]]; then
  echo "Install script not found: $INSTALL_SCRIPT_PATH"
  exit 1
fi

SHA=$(shasum -a 256 "$INSTALL_SCRIPT_PATH" | awk '{print $1}')

portable_sed_in_place "s|^  url \".*\"|  url \"https://raw.githubusercontent.com/IOSTimor/ios-fastlane-template/v${VERSION}/scripts/install.sh\"|" "$FORMULA_PATH"
portable_sed_in_place "s|^      export REPO_REF=.*|      export REPO_REF=\"v${VERSION}\"|" "$FORMULA_PATH"
portable_sed_in_place "s|^  version \".*\"|  version \"${VERSION}\"|" "$FORMULA_PATH"
portable_sed_in_place "s|^  sha256 \".*\"|  sha256 \"${SHA}\"|" "$FORMULA_PATH"

if [[ "$FORMULA_PATH" == "Formula/ios-fastlane-template.rb" ]]; then
  cp "$FORMULA_PATH" templates/homebrew-tap/Formula/ios-fastlane-template.rb
fi

echo "Updated $FORMULA_PATH"
echo "Publish tag v${VERSION} with these exact installer bytes before distributing the formula."
echo "  version: $VERSION"
echo "  sha256:  $SHA"
