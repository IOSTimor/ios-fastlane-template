#!/bin/bash

set -euo pipefail

TARGET_DIR=${1:-}
TAP_OWNER=${2:-IOSTimor}
TAP_REPO=${3:-homebrew-tap}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TEMPLATE_DIR="${REPO_ROOT}/templates/homebrew-tap"
SOURCE_FORMULA="${REPO_ROOT}/Formula/ios-fastlane-template.rb"
TARGET_DIR_ABS=""

if [[ -z "$TARGET_DIR" ]]; then
  echo "Usage: bash scripts/prepare_homebrew_tap_repo.sh /path/to/homebrew-tap [owner] [repo]"
  exit 1
fi

mkdir -p "$TARGET_DIR"
TARGET_DIR_ABS="$(cd "$TARGET_DIR" && pwd)"

mkdir -p "$TARGET_DIR_ABS/Formula"
mkdir -p "$TARGET_DIR_ABS/.github/workflows"

cp "$SOURCE_FORMULA" "$TARGET_DIR_ABS/Formula/ios-fastlane-template.rb"
cp "$TEMPLATE_DIR/README.md" "$TARGET_DIR_ABS/README.md"
cp "$TEMPLATE_DIR/.gitignore" "$TARGET_DIR_ABS/.gitignore"
cp "$TEMPLATE_DIR/.github/workflows/test-formula.yml" "$TARGET_DIR_ABS/.github/workflows/test-formula.yml"

if sed --version >/dev/null 2>&1; then
  sed -i "s|IOSTimor/homebrew-tap|${TAP_OWNER}/${TAP_REPO}|g" "$TARGET_DIR_ABS/README.md"
  sed -i "s|IOSTimor/tap|${TAP_OWNER}/tap|g" "$TARGET_DIR_ABS/README.md"
else
  sed -i '' "s|IOSTimor/homebrew-tap|${TAP_OWNER}/${TAP_REPO}|g" "$TARGET_DIR_ABS/README.md"
  sed -i '' "s|IOSTimor/tap|${TAP_OWNER}/tap|g" "$TARGET_DIR_ABS/README.md"
fi

echo "Prepared Homebrew tap scaffold at: $TARGET_DIR_ABS"
echo "Files:"
echo "  - README.md"
echo "  - .gitignore"
echo "  - Formula/ios-fastlane-template.rb"
echo "  - .github/workflows/test-formula.yml"
echo
echo "Next:"
echo "  1. Create the ${TAP_OWNER}/${TAP_REPO} repository if it does not exist yet"
echo "  2. Review README.md and Formula/ios-fastlane-template.rb"
echo "  3. Commit and push the tap repository"
echo "  4. Test with: brew tap ${TAP_OWNER}/tap https://github.com/${TAP_OWNER}/${TAP_REPO}"
