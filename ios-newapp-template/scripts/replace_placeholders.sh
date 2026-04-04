#!/bin/bash

set -euo pipefail

TARGET_DIR=${1:-.}
APP_NAME=${2:-MyApp}
BUNDLE_ID=${3:-com.example.app}

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "Target directory does not exist: $TARGET_DIR"
  exit 1
fi

find "$TARGET_DIR" -type f -not -path "*/.git/*" -exec sed -i '' "s/MyApp/${APP_NAME}/g" {} +
find "$TARGET_DIR" -type f -not -path "*/.git/*" -exec sed -i '' "s/com\\.example\\.app/${BUNDLE_ID}/g" {} +

echo "Updated placeholders in $TARGET_DIR"
