#!/bin/bash

set -euo pipefail

TARGET_DIR=${1:-}

if [[ -z "$TARGET_DIR" ]]; then
  echo "Usage: bash scripts/create_project.sh /absolute/or/relative/path/to/ios-project"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd || true)"

if [[ -z "$TARGET_DIR" || ! -d "$TARGET_DIR" ]]; then
  echo "Target directory does not exist: ${1}"
  exit 1
fi

mkdir -p "$TARGET_DIR/fastlane"
mkdir -p "$TARGET_DIR/fastlane/metadata"
mkdir -p "$TARGET_DIR/fastlane/screenshots"

cp -R "$TEMPLATE_DIR/fastlane/." "$TARGET_DIR/fastlane/"

if [[ ! -f "$TARGET_DIR/.env.example" ]]; then
  cp "$TEMPLATE_DIR/.env.example" "$TARGET_DIR/.env.example"
fi

if [[ ! -f "$TARGET_DIR/Gemfile" ]]; then
  cp "$TEMPLATE_DIR/Gemfile" "$TARGET_DIR/Gemfile"
fi

if [[ ! -f "$TARGET_DIR/Makefile" ]]; then
  cp "$TEMPLATE_DIR/Makefile" "$TARGET_DIR/Makefile"
fi

echo "Fastlane template installed into $TARGET_DIR"
echo "Next:"
echo "  1. Copy .env.example to .env and fill project-specific values"
echo "  2. Update fastlane/.env.default safe defaults"
echo "  3. Run 'fastlane lanes' and 'fastlane ios local_build'"
echo "  4. Optional: run 'bundle install' and switch to 'bundle exec fastlane ...'"
