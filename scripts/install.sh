#!/bin/bash

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_NAME=${SCRIPT_NAME_OVERRIDE:-$SCRIPT_NAME}

MODE=install
RELEASE_COMMAND=""
case "${1:-}" in
  build) MODE=build; shift ;;
  testflight|metadata|submit) MODE=release; RELEASE_COMMAND=$1; shift ;;
esac

# Prefer helpers already bundled beside the launcher; never install a template for release subcommands.
INSTALL_SOURCE=${BASH_SOURCE[0]:-}
if [[ "$MODE" != "install" && -n "$INSTALL_SOURCE" && -f "$INSTALL_SOURCE" ]]; then
  SOURCE_DIR="$(cd "$(dirname "$INSTALL_SOURCE")" && pwd)"
  if [[ "$MODE" == "build" && -f "$SOURCE_DIR/build_local.rb" ]]; then
    exec ruby "$SOURCE_DIR/build_local.rb" "$@"
  elif [[ "$MODE" == "release" && -f "$SOURCE_DIR/release.rb" ]]; then
    exec ruby "$SOURCE_DIR/release.rb" "$RELEASE_COMMAND" "$@"
  fi
fi

TARGET_DIR=${1:-}
if [[ "$MODE" != "install" && -z "$TARGET_DIR" ]]; then
  TARGET_DIR=.
fi
if [[ "$TARGET_DIR" == "--help" || "$TARGET_DIR" == "-h" ]]; then
  echo "Usage: ${SCRIPT_NAME} /path/to/your/ios-project [options]"
  echo "Build: ${SCRIPT_NAME} build [PROJECT_DIRECTORY] [options]"
  echo "Release: ${SCRIPT_NAME} testflight|metadata|submit [PROJECT_DIRECTORY] [options]"
  echo "Use ${SCRIPT_NAME} COMMAND --help for command-specific options."
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
elif [[ "$MODE" == "release" ]]; then
  if [[ ! -f "$EXTRACTED_DIR/scripts/release.rb" ]]; then
    echo "This template version does not include release subcommands" >&2
    exit 1
  fi
  ruby "$EXTRACTED_DIR/scripts/release.rb" "$RELEASE_COMMAND" "$@"
else
  bash "$EXTRACTED_DIR/ios-newapp-template/scripts/create_project.sh" "$@"
fi
