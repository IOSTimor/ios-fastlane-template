#!/bin/bash

set -euo pipefail

TARGET_DIR=${1:-}

detect_single_match() {
  local target_dir=$1
  local pattern=$2
  local first_match
  local second_match

  first_match=$(find "$target_dir" -maxdepth 2 -name "$pattern" | sort | head -n 1)
  second_match=$(find "$target_dir" -maxdepth 2 -name "$pattern" | sort | sed -n '2p')

  if [[ -n "$first_match" && -z "$second_match" ]]; then
    basename "$first_match"
  fi
}

infer_scheme_from_project() {
  local project_name=$1

  if [[ -n "$project_name" ]]; then
    echo "${project_name%.xcodeproj}"
  fi
}

upsert_env_value() {
  local file_path=$1
  local key=$2
  local value=$3

  [[ -n "$value" ]] || return 0

  if grep -q "^${key}=" "$file_path"; then
    sed -i '' "s|^${key}=.*|${key}=${value}|" "$file_path"
  else
    printf "\n%s=%s\n" "$key" "$value" >> "$file_path"
  fi
}

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

DETECTED_WORKSPACE=$(detect_single_match "$TARGET_DIR" "*.xcworkspace" || true)
DETECTED_PROJECT=$(detect_single_match "$TARGET_DIR" "*.xcodeproj" || true)
DETECTED_SCHEME=$(infer_scheme_from_project "${DETECTED_PROJECT}")

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

upsert_env_value "$TARGET_DIR/fastlane/.env.default" "WORKSPACE" "${DETECTED_WORKSPACE:-}"
upsert_env_value "$TARGET_DIR/fastlane/.env.default" "PROJECT" "${DETECTED_PROJECT:-}"
upsert_env_value "$TARGET_DIR/fastlane/.env.default" "SCHEME" "${DETECTED_SCHEME:-}"
upsert_env_value "$TARGET_DIR/fastlane/.env.default" "APP_NAME" "${DETECTED_SCHEME:-}"

echo "Fastlane template installed into $TARGET_DIR"
if [[ -n "${DETECTED_WORKSPACE:-}" ]]; then
  echo "Detected workspace: $DETECTED_WORKSPACE"
fi
if [[ -n "${DETECTED_PROJECT:-}" ]]; then
  echo "Detected project: $DETECTED_PROJECT"
fi
if [[ -n "${DETECTED_SCHEME:-}" ]]; then
  echo "Detected default scheme: $DETECTED_SCHEME"
fi
echo "Next:"
echo "  1. Copy .env.example to .env and fill project-specific values"
echo "  2. Review fastlane/.env.default inferred defaults"
echo "  3. Run 'fastlane lanes', 'fastlane ios validate_setup', and 'fastlane ios precheck_assets'"
echo "  4. Run 'fastlane ios local_build'"
echo "  5. Optional: run 'bundle install' and switch to 'bundle exec fastlane ...'"
