#!/bin/bash

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_NAME=${SCRIPT_NAME_OVERRIDE:-$SCRIPT_NAME}

MODE=install
if [[ "${1:-}" == "build" ]]; then
  MODE=build
  shift
fi

# A repository checkout already has the builder; avoid downloading or installing a template.
INSTALL_SOURCE=${BASH_SOURCE[0]:-}
if [[ "$MODE" == "build" && -n "$INSTALL_SOURCE" && -f "$INSTALL_SOURCE" ]]; then
  SOURCE_DIR="$(cd "$(dirname "$INSTALL_SOURCE")" && pwd)"
  if [[ -f "$SOURCE_DIR/build_local.rb" ]]; then
    exec ruby "$SOURCE_DIR/build_local.rb" "$@"
  fi
fi

TARGET_DIR=${1:-}
if [[ "$MODE" == "build" && -z "$TARGET_DIR" ]]; then
  TARGET_DIR=.
fi
if [[ "$TARGET_DIR" == "--help" || "$TARGET_DIR" == "-h" ]]; then
  echo "Usage: ${SCRIPT_NAME} /path/to/your/ios-project [options]"
  echo "Build: ${SCRIPT_NAME} build [PROJECT_DIRECTORY] [--scheme NAME] [--dry-run]"
  echo "Options: --force --project PATH --workspace PATH --scheme NAME --app-name NAME --skip-generate-env"
  exit 0
fi

REPO_OWNER=${REPO_OWNER:-IOSTimor}
REPO_NAME=${REPO_NAME:-ios-fastlane-template}
REPO_REF=${REPO_REF:-main}
ARCHIVE_URL=${ARCHIVE_URL:-"https://codeload.github.com/${REPO_OWNER}/${REPO_NAME}/tar.gz/${REPO_REF}"}
LOCAL_ARCHIVE_PATH=${LOCAL_ARCHIVE_PATH:-}
RAW_INSTALL_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/main/scripts/install.sh"

if [[ -z "$TARGET_DIR" ]]; then
  if [[ "$SCRIPT_NAME" == "install.sh" || "$SCRIPT_NAME" == "bash" ]]; then
    echo "Usage: curl -fsSL ${RAW_INSTALL_URL} | bash -s -- /path/to/your/ios-project [options]"
  else
    echo "Usage: ${SCRIPT_NAME} /path/to/your/ios-project [options]"
  fi
  echo "Options: --force --project NAME.xcodeproj --workspace NAME.xcworkspace --scheme NAME --app-name NAME --skip-generate-env"
  exit 1
fi

if ! command -v tar >/dev/null 2>&1; then
  echo "tar is required but was not found"
  exit 1
fi

if [[ -n "$LOCAL_ARCHIVE_PATH" ]]; then
  if [[ ! -f "$LOCAL_ARCHIVE_PATH" ]]; then
    echo "LOCAL_ARCHIVE_PATH does not exist: $LOCAL_ARCHIVE_PATH"
    exit 1
  fi
else
  if ! command -v curl >/dev/null 2>&1; then
    echo "curl is required but was not found"
    exit 1
  fi
fi

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ios-fastlane-template-install.XXXXXX")"
cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

ARCHIVE_PATH="$WORK_DIR/template.tar.gz"

if [[ -n "$LOCAL_ARCHIVE_PATH" ]]; then
  cp "$LOCAL_ARCHIVE_PATH" "$ARCHIVE_PATH"
else
  curl -fsSL "$ARCHIVE_URL" -o "$ARCHIVE_PATH"
fi

tar -xzf "$ARCHIVE_PATH" -C "$WORK_DIR"

EXTRACTED_DIR="$(find "$WORK_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)"

if [[ -z "$EXTRACTED_DIR" || ! -d "$EXTRACTED_DIR/ios-newapp-template" ]]; then
  echo "Downloaded archive did not contain ios-newapp-template"
  exit 1
fi

if [[ "$MODE" == "build" ]]; then
  if [[ ! -f "$EXTRACTED_DIR/scripts/build_local.rb" ]]; then
    echo "This template version does not include the one-command builder" >&2
    exit 1
  fi
  ruby "$EXTRACTED_DIR/scripts/build_local.rb" "$@"
else
  bash "$EXTRACTED_DIR/ios-newapp-template/scripts/create_project.sh" "$@"
fi
